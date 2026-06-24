from __future__ import annotations

import json
import shutil
import tempfile
from datetime import date
from pathlib import Path
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from baha_rag.acquisition.gap_closure import PriorityGapClosureEngine
from baha_rag.acquisition.campaign import PriorityCampaignService
from baha_rag.acquisition.manual_ingestion import (
    ManualResourceIngestionService,
    ManualResourceMetadata,
)
from baha_rag.acquisition.review_queue import ClinicalReviewQueueService
from baha_rag.acquisition.service import AcquisitionService
from baha_rag.auth import ActorContext, get_actor_context
from baha_rag.config import Settings, get_settings
from baha_rag.dashboard.metrics import DashboardService
from baha_rag.db.mobile_repository import MobileAppRepository
from baha_rag.db.repository import KnowledgeRepository
from baha_rag.db.session import get_session
from baha_rag.embeddings.bge import EmbeddingService
from baha_rag.extraction.condition_profile import ConditionProfileExtractor
from baha_rag.generation.composer import EvidenceComposer
from baha_rag.ingestion.pipeline import IngestionPipeline
from baha_rag.privacy import PrivacyService
from baha_rag.retrieval.hybrid import HybridRetriever
from baha_rag.safety import assess_safety
from baha_rag.schemas import (
    AcquisitionDiscoverRequest,
    AcquisitionDownloadRequest,
    AcquisitionJobResponse,
    ChatRequest,
    ChatResponse,
    ChatSessionCreateRequest,
    ChatSessionSummary,
    CheckinSubmissionRequest,
    ConditionSummary,
    CounselorCaseDetailResponse,
    CounselorCaseNote,
    CounselorCaseNoteCreateRequest,
    CounselorQueueResponse,
    HelpRequestCreateRequest,
    HelpRequestResponse,
    IngestResponse,
    IngestUrlRequest,
    MobileChatExchangeResponse,
    MobileChatMessage,
    MobileChatMessageCreateRequest,
    MobileActorResponse,
    MobileCheckinTemplateDetail,
    MobileCheckinTemplateSummary,
    MobileLinkedStudentSummary,
    MobileModuleSummary,
    ModuleProgressUpsertRequest,
    ModuleProgressUpsertResponse,
    ParentWeeklySummaryResponse,
    PastoralFlagCreateRequest,
    PastoralFlagResponse,
    SearchRequest,
    SearchResponse,
    ReviewDecisionRequest,
    StudentCheckinDetail,
    StudentCheckinSummary,
    TeacherClassStudentSummary,
    TeacherClassSummary,
    TeacherCohortSummaryResponse,
    ViewRequest,
)
from baha_rag.taxonomy import TAXONOMY, find_conditions

router = APIRouter()


def get_embedding_service(settings: Settings = Depends(get_settings)) -> EmbeddingService:
    return EmbeddingService(settings)


async def get_retriever(
    session: AsyncSession = Depends(get_session),
    embeddings: EmbeddingService = Depends(get_embedding_service),
) -> HybridRetriever:
    return HybridRetriever(KnowledgeRepository(session), embeddings)


def _require_student(actor: ActorContext) -> None:
    if "student" not in actor.roles or actor.student_profile_id is None:
        raise HTTPException(status_code=403, detail="Student mobile endpoints require an active student profile")


def _require_guardian(actor: ActorContext) -> None:
    if "guardian" not in actor.roles or actor.guardian_id is None:
        raise HTTPException(status_code=403, detail="Parent mobile endpoints require an active guardian profile")


def _require_teacher(actor: ActorContext) -> None:
    if "teacher" not in actor.roles or actor.teacher_profile_id is None:
        raise HTTPException(status_code=403, detail="Teacher mobile endpoints require an active teacher profile")


def _require_counselor(actor: ActorContext) -> None:
    if not ({"counselor", "baha_admin", "administrator"} & set(actor.roles)):
        raise HTTPException(status_code=403, detail="Counselor mobile endpoints require counselor or BAHA admin access")


def _assistant_body(response: ChatResponse) -> str:
    answer = response.answer
    return " ".join(
        [
            answer.what_it_is.strip(),
            answer.what_to_do.strip(),
            answer.when_to_seek_help.strip(),
        ]
    )


@router.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


@router.get("/health/ready")
async def health_ready(
    session: AsyncSession = Depends(get_session),
    settings: Settings = Depends(get_settings),
) -> dict[str, str]:
    await session.execute(text("select 1"))
    return {
        "status": "ready",
        "environment": settings.environment,
        "storage_provider": settings.object_storage_provider,
    }


@router.post("/search", response_model=SearchResponse)
async def search(request: SearchRequest, retriever: HybridRetriever = Depends(get_retriever)) -> SearchResponse:
    results = await retriever.search(request.query, top_k=request.top_k, filters=request.filters)
    return SearchResponse(query=request.query, top_k=request.top_k, results=results)


@router.get("/conditions", response_model=list[ConditionSummary])
async def conditions() -> list[ConditionSummary]:
    return [
        ConditionSummary(condition=item.condition, category=item.category, topics=list(item.topics))
        for item in TAXONOMY
    ]


@router.post("/parent-view")
async def parent_view(
    request: ViewRequest,
    retriever: HybridRetriever = Depends(get_retriever),
) -> dict:
    request.audience = "parent"
    return await _perspective_view(request, retriever)


@router.post("/teacher-view")
async def teacher_view(
    request: ViewRequest,
    retriever: HybridRetriever = Depends(get_retriever),
) -> dict:
    request.audience = "teacher"
    return await _perspective_view(request, retriever)


@router.post("/interventions")
async def interventions(
    request: ViewRequest,
    retriever: HybridRetriever = Depends(get_retriever),
) -> dict:
    query = f"{request.condition} recommended interventions family classroom support escalation"
    results = await retriever.search(query, top_k=request.top_k, filters={"condition": request.condition})
    answer = EvidenceComposer().compose(
        condition=request.condition,
        perspective=request.audience,
        query=query,
        evidence=results,
    )
    return answer.model_dump()


@router.post("/conditions/profile")
async def condition_profile(
    request: ViewRequest,
    retriever: HybridRetriever = Depends(get_retriever),
) -> dict:
    query = (
        f"{request.condition} definition symptoms risk factors protective factors assessment "
        "interventions classroom family escalation emergency resources"
    )
    results = await retriever.search(query, top_k=request.top_k, filters={"condition": request.condition})
    profile = ConditionProfileExtractor().extract(request.condition, results)
    return profile.model_dump()


@router.post("/resources")
async def resources(
    request: ViewRequest,
    retriever: HybridRetriever = Depends(get_retriever),
) -> dict:
    query = f"{request.condition} resources guidance support adolescent parent teacher"
    results = await retriever.search(query, top_k=request.top_k, filters={"condition": request.condition})
    return {
        "condition": request.condition,
        "resources": [citation.model_dump() for result in results for citation in result.citations],
    }


@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest, retriever: HybridRetriever = Depends(get_retriever)) -> ChatResponse:
    results = await retriever.search(request.message, top_k=request.top_k, filters=request.filters)
    condition = next(iter(find_conditions(request.message)), "General Wellbeing")
    answer = EvidenceComposer().compose(
        condition=condition,
        perspective=request.audience,
        query=request.message,
        evidence=results,
    )
    return ChatResponse(answer=answer, retrieved=results)


@router.get("/mobile/me", response_model=MobileActorResponse)
async def mobile_me(actor: ActorContext = Depends(get_actor_context)) -> MobileActorResponse:
    return MobileActorResponse(
        user_id=actor.user_id,
        external_auth_id=actor.external_auth_id,
        display_name=actor.display_name,
        roles=actor.roles,
        primary_role=actor.primary_role,
        app_audience=actor.app_audience,
        student_profile_id=actor.student_profile_id,
        guardian_id=actor.guardian_id,
        teacher_profile_id=actor.teacher_profile_id,
        age_cohort=actor.age_cohort,
        school_id=actor.school_id,
    )


@router.get("/mobile/student/checkin-templates", response_model=list[MobileCheckinTemplateSummary])
async def mobile_student_checkin_templates(
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> list[MobileCheckinTemplateSummary]:
    _require_student(actor)
    rows = await MobileAppRepository(session).list_student_checkin_templates(age_cohort=actor.age_cohort)
    return [MobileCheckinTemplateSummary.model_validate(row) for row in rows]


@router.get("/mobile/student/checkin-templates/{template_id}", response_model=MobileCheckinTemplateDetail)
async def mobile_student_checkin_template_detail(
    template_id: UUID,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> MobileCheckinTemplateDetail:
    _require_student(actor)
    row = await MobileAppRepository(session).get_student_checkin_template_detail(
        template_id=template_id,
        age_cohort=actor.age_cohort,
    )
    if row is None:
        raise HTTPException(status_code=404, detail="Check-in template not found")
    return MobileCheckinTemplateDetail.model_validate(row)


@router.get("/mobile/student/modules", response_model=list[MobileModuleSummary])
async def mobile_student_modules(
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> list[MobileModuleSummary]:
    _require_student(actor)
    rows = await MobileAppRepository(session).list_student_modules(
        user_id=actor.user_id,
        student_profile_id=actor.student_profile_id,
        age_cohort=actor.age_cohort,
    )
    return [MobileModuleSummary.model_validate(row) for row in rows]


@router.post("/mobile/student/modules/{module_id}/progress", response_model=ModuleProgressUpsertResponse)
async def mobile_upsert_student_module_progress(
    module_id: UUID,
    request: ModuleProgressUpsertRequest,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> ModuleProgressUpsertResponse:
    _require_student(actor)
    row = await MobileAppRepository(session).upsert_student_module_progress(
        user_id=actor.user_id,
        student_profile_id=actor.student_profile_id,
        module_id=module_id,
        status=request.status,
        completion_percent=request.completion_percent,
        current_section_ordinal=request.current_section_ordinal,
        current_step_ordinal=request.current_step_ordinal,
    )
    await session.commit()
    return ModuleProgressUpsertResponse.model_validate(row)


@router.get("/mobile/student/checkins", response_model=list[StudentCheckinSummary])
async def mobile_student_checkins(
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
    limit: int = 20,
) -> list[StudentCheckinSummary]:
    _require_student(actor)
    rows = await MobileAppRepository(session).list_student_checkins(
        student_profile_id=actor.student_profile_id,
        limit=max(1, min(limit, 50)),
    )
    return [StudentCheckinSummary.model_validate(row) for row in rows]


@router.get("/mobile/student/checkins/{response_set_id}", response_model=StudentCheckinDetail)
async def mobile_student_checkin_detail(
    response_set_id: UUID,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> StudentCheckinDetail:
    _require_student(actor)
    row = await MobileAppRepository(session).get_student_checkin_detail(
        student_profile_id=actor.student_profile_id,
        response_set_id=response_set_id,
    )
    if row is None:
        raise HTTPException(status_code=404, detail="Check-in response set not found")
    return StudentCheckinDetail.model_validate(row)


@router.post("/mobile/student/checkins", response_model=StudentCheckinSummary)
async def mobile_submit_student_checkin(
    request: CheckinSubmissionRequest,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> StudentCheckinSummary:
    _require_student(actor)
    row = await MobileAppRepository(session).submit_student_checkin(
        student_profile_id=actor.student_profile_id,
        template_id=request.template_id,
        source_mode=request.source_mode,
        visibility_scope=request.visibility_scope,
        answers=[
            {
                "question_id": answer.question_id,
                "numeric_value": answer.numeric_value,
                "text_value": answer.text_value,
                "boolean_value": answer.boolean_value,
                "selected_options_json": json.dumps(answer.selected_options),
                "normalized_value_json": json.dumps(answer.normalized_value),
            }
            for answer in request.answers
        ],
    )
    await session.commit()
    detail = await MobileAppRepository(session).get_student_checkin_detail(
        student_profile_id=actor.student_profile_id,
        response_set_id=row["id"],
    )
    if detail is None:
        raise HTTPException(status_code=500, detail="Check-in was stored but could not be reloaded")
    return StudentCheckinSummary.model_validate(
        {
            "id": detail["id"],
            "template_id": detail["template_id"],
            "template_key": detail["template_key"],
            "title": detail["title"],
            "scheduled_for": detail["scheduled_for"],
            "submitted_at": detail["submitted_at"],
            "status": detail["status"],
            "source_mode": detail["source_mode"],
            "visibility_scope": detail["visibility_scope"],
            "response_count": len(detail["answers"]),
        }
    )


@router.post("/mobile/student/help-requests", response_model=HelpRequestResponse)
async def mobile_student_help_request(
    request: HelpRequestCreateRequest,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> HelpRequestResponse:
    _require_student(actor)
    row = await MobileAppRepository(session).create_help_request(
        student_profile_id=actor.student_profile_id,
        requested_by_user_id=actor.user_id,
        requested_for_user_id=actor.user_id,
        request_channel="student_app",
        category=request.category,
        urgency=request.urgency,
        summary=request.summary,
        details_json=json.dumps(request.details),
        visibility_scope=request.visibility_scope,
    )
    await session.commit()
    return HelpRequestResponse.model_validate(row)


@router.get("/mobile/chat/sessions", response_model=list[ChatSessionSummary])
async def mobile_chat_sessions(
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
    limit: int = 20,
) -> list[ChatSessionSummary]:
    rows = await MobileAppRepository(session).list_chat_sessions(
        user_id=actor.user_id,
        audience_app=actor.app_audience,
        student_profile_id=actor.student_profile_id if "student" in actor.roles else None,
        limit=max(1, min(limit, 50)),
    )
    return [ChatSessionSummary.model_validate(row) for row in rows]


@router.post("/mobile/chat/sessions", response_model=ChatSessionSummary)
async def mobile_create_chat_session(
    request: ChatSessionCreateRequest,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> ChatSessionSummary:
    row = await MobileAppRepository(session).create_chat_session(
        user_id=actor.user_id,
        audience_app=actor.app_audience,
        student_profile_id=actor.student_profile_id if "student" in actor.roles else None,
        session_type=request.session_type,
        summary_visibility_scope=request.summary_visibility_scope,
    )
    await session.commit()
    return ChatSessionSummary.model_validate(row)


@router.get("/mobile/chat/sessions/{session_id}/messages", response_model=list[MobileChatMessage])
async def mobile_chat_messages(
    session_id: UUID,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> list[MobileChatMessage]:
    owned = await MobileAppRepository(session).get_chat_session_owned(
        session_id=session_id,
        user_id=actor.user_id,
        audience_app=actor.app_audience,
        student_profile_id=actor.student_profile_id if "student" in actor.roles else None,
    )
    if owned is None:
        raise HTTPException(status_code=404, detail="Chat session not found")
    rows = await MobileAppRepository(session).list_chat_messages(chat_session_id=session_id)
    return [MobileChatMessage.model_validate(row) for row in rows]


@router.post("/mobile/chat/sessions/{session_id}/messages", response_model=MobileChatExchangeResponse)
async def mobile_create_chat_message(
    session_id: UUID,
    request: MobileChatMessageCreateRequest,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
    retriever: HybridRetriever = Depends(get_retriever),
) -> MobileChatExchangeResponse:
    owned = await MobileAppRepository(session).get_chat_session_owned(
        session_id=session_id,
        user_id=actor.user_id,
        audience_app=actor.app_audience,
        student_profile_id=actor.student_profile_id if "student" in actor.roles else None,
    )
    if owned is None:
        raise HTTPException(status_code=404, detail="Chat session not found")

    user_message_row = await MobileAppRepository(session).create_chat_message(
        chat_session_id=session_id,
        sender_type="user",
        message_type="user_query",
        body=request.body,
        retrieval_filters_json=json.dumps(request.filters),
    )

    chat_response = await chat(
        ChatRequest(message=request.body, audience="adolescent" if actor.app_audience == "student" else actor.app_audience, filters=request.filters),
        retriever=retriever,
    )
    safety = assess_safety(request.body)
    safety_labels = []
    if safety.emergency_indicators:
        safety_labels.append("emergency")
    if safety.diagnostic_request:
        safety_labels.append("diagnostic_request")

    assistant_message_row = await MobileAppRepository(session).create_chat_message(
        chat_session_id=session_id,
        sender_type="assistant",
        message_type="assistant_answer",
        body=_assistant_body(chat_response),
        structured_payload_json=json.dumps(chat_response.answer.model_dump(mode="json")),
        retrieval_filters_json=json.dumps(request.filters),
        safety_labels_json=json.dumps(safety_labels),
    )
    await MobileAppRepository(session).add_chat_answer_citations(
        chat_message_id=assistant_message_row["id"],
        citations=[
            {
                "resource_id": result.document_id,
                "chunk_id": result.chunk_id,
                "citation_label": (result.citations[0].title if result.citations else "Retrieved evidence"),
                "confidence": result.confidence,
            }
            for result in chat_response.retrieved
        ],
    )

    safety_disposition = None
    if safety.emergency_indicators and actor.student_profile_id is not None:
        signal = await MobileAppRepository(session).create_monitoring_signal(
            student_profile_id=actor.student_profile_id,
            signal_type="chatbot_risk_phrase",
            severity="emergency",
            title="Emergency language detected in chat",
            signal_summary="Student chat message contained emergency self-harm or harm indicators.",
            derived_facts_json=json.dumps({"message_id": str(user_message_row["id"]), "session_id": str(session_id)}),
        )
        await MobileAppRepository(session).attach_signal_source(
            monitoring_signal_id=signal["id"],
            source_type="chat_message",
            source_record_id=user_message_row["id"],
            contribution_weight=1.0,
            summary="Emergency terms detected in student chat message",
        )
        await MobileAppRepository(session).create_escalation_case(
            student_profile_id=actor.student_profile_id,
            primary_signal_id=signal["id"],
            opened_by_user_id=actor.user_id,
            case_type="crisis",
            severity="emergency",
            title="Emergency chat escalation",
            summary="Chat message triggered an emergency safeguarding review.",
            privacy_override_active=True,
            override_reason="Emergency chat signal",
        )
        safety_disposition = "emergency"

    await MobileAppRepository(session).touch_chat_session(
        chat_session_id=session_id,
        safety_disposition=safety_disposition,
    )
    await session.commit()

    return MobileChatExchangeResponse(
        user_message=MobileChatMessage.model_validate(user_message_row),
        assistant_message=MobileChatMessage.model_validate(assistant_message_row),
        answer=chat_response.answer,
        retrieved=chat_response.retrieved,
    )


@router.get("/mobile/parent/students", response_model=list[MobileLinkedStudentSummary])
async def mobile_parent_students(
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> list[MobileLinkedStudentSummary]:
    _require_guardian(actor)
    rows = await MobileAppRepository(session).list_parent_linked_students(guardian_id=actor.guardian_id)
    return [MobileLinkedStudentSummary.model_validate(row) for row in rows]


@router.get("/mobile/parent/students/{student_profile_id}/weekly-summary/latest", response_model=ParentWeeklySummaryResponse)
async def mobile_parent_latest_summary(
    student_profile_id: UUID,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> ParentWeeklySummaryResponse:
    _require_guardian(actor)
    privacy = PrivacyService(session)
    access = await privacy.summarize_parent_access(
        guardian_id=actor.guardian_id,
        student_profile_id=student_profile_id,
    )
    if not access["allowed"]:
        raise HTTPException(status_code=403, detail=access["reason"] or "Parent summary access is not allowed")
    row = await MobileAppRepository(session).get_latest_parent_summary(
        guardian_id=actor.guardian_id,
        student_profile_id=student_profile_id,
    )
    if row is None:
        raise HTTPException(status_code=404, detail="Parent weekly summary not found")
    row["access"] = access
    return ParentWeeklySummaryResponse.model_validate(row)


@router.get("/mobile/teacher/classes", response_model=list[TeacherClassSummary])
async def mobile_teacher_classes(
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> list[TeacherClassSummary]:
    _require_teacher(actor)
    rows = await MobileAppRepository(session).list_teacher_classes(teacher_profile_id=actor.teacher_profile_id)
    return [TeacherClassSummary.model_validate(row) for row in rows]


@router.get("/mobile/teacher/classes/{class_id}/students", response_model=list[TeacherClassStudentSummary])
async def mobile_teacher_class_students(
    class_id: UUID,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> list[TeacherClassStudentSummary]:
    _require_teacher(actor)
    assigned_classes = await MobileAppRepository(session).list_teacher_classes(teacher_profile_id=actor.teacher_profile_id)
    if class_id not in {row["class_id"] for row in assigned_classes}:
        raise HTTPException(status_code=403, detail="Teacher is not assigned to this class")
    rows = await MobileAppRepository(session).list_teacher_class_students(
        teacher_profile_id=actor.teacher_profile_id,
        class_id=class_id,
    )
    return [TeacherClassStudentSummary.model_validate(row) for row in rows]


@router.get("/mobile/teacher/classes/{class_id}/cohort-summary/latest", response_model=TeacherCohortSummaryResponse)
async def mobile_teacher_latest_cohort_summary(
    class_id: UUID,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> TeacherCohortSummaryResponse:
    _require_teacher(actor)
    assigned_classes = await MobileAppRepository(session).list_teacher_classes(teacher_profile_id=actor.teacher_profile_id)
    if class_id not in {row["class_id"] for row in assigned_classes}:
        raise HTTPException(status_code=403, detail="Teacher is not assigned to this class")
    row = await MobileAppRepository(session).get_latest_teacher_cohort_summary(class_id=class_id)
    if row is None:
        raise HTTPException(status_code=404, detail="Teacher cohort summary not found")
    return TeacherCohortSummaryResponse.model_validate(row)


@router.post("/mobile/teacher/pastoral-flags", response_model=PastoralFlagResponse)
async def mobile_create_pastoral_flag(
    request: PastoralFlagCreateRequest,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> PastoralFlagResponse:
    _require_teacher(actor)
    row = await MobileAppRepository(session).create_pastoral_flag(
        student_profile_id=request.student_profile_id,
        teacher_profile_id=actor.teacher_profile_id,
        class_id=request.class_id,
        flag_type=request.flag_type,
        severity=request.severity,
        summary=request.summary,
        details_json=json.dumps(request.details),
    )
    await session.commit()
    return PastoralFlagResponse.model_validate(row)


@router.get("/mobile/counselor/queue", response_model=CounselorQueueResponse)
async def mobile_counselor_queue(
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
    limit: int = 20,
) -> CounselorQueueResponse:
    _require_counselor(actor)
    queue = await MobileAppRepository(session).list_counselor_queue(limit=max(1, min(limit, 50)))
    return CounselorQueueResponse.model_validate(queue)


@router.get("/mobile/counselor/cases/{case_id}", response_model=CounselorCaseDetailResponse)
async def mobile_counselor_case_detail(
    case_id: UUID,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> CounselorCaseDetailResponse:
    _require_counselor(actor)
    detail = await MobileAppRepository(session).get_counselor_case_detail(case_id=case_id)
    if detail is None:
        raise HTTPException(status_code=404, detail="Case not found")
    return CounselorCaseDetailResponse.model_validate(detail)


@router.post("/mobile/counselor/cases/{case_id}/notes", response_model=CounselorCaseNote)
async def mobile_counselor_case_note(
    case_id: UUID,
    request: CounselorCaseNoteCreateRequest,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> CounselorCaseNote:
    _require_counselor(actor)
    note = await MobileAppRepository(session).add_case_note(
        case_id=case_id,
        author_user_id=actor.user_id,
        note_type=request.note_type,
        visibility_scope=request.visibility_scope,
        body=request.body,
    )
    await session.commit()
    detail = await MobileAppRepository(session).get_counselor_case_detail(case_id=case_id)
    if detail is None:
        raise HTTPException(status_code=404, detail="Case not found")
    created_note = next((row for row in detail["notes"] if row["id"] == note["id"]), None)
    if created_note is None:
        raise HTTPException(status_code=500, detail="Case note was stored but could not be reloaded")
    return CounselorCaseNote.model_validate(created_note)


@router.post("/admin/ingest-url", response_model=IngestResponse)
async def ingest_url(
    request: IngestUrlRequest,
    session: AsyncSession = Depends(get_session),
    embeddings: EmbeddingService = Depends(get_embedding_service),
) -> IngestResponse:
    pipeline = IngestionPipeline(session, embeddings)
    try:
        response = await pipeline.ingest_url(
            url=str(request.url),
            organization=request.organization,
            audience=request.audience,
            country=request.country,
            evidence_level=request.evidence_level,
        )
        await session.commit()
        return response
    except ValueError as exc:
        await session.rollback()
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.get("/admin/dashboard")
async def dashboard(session: AsyncSession = Depends(get_session)) -> dict:
    service = DashboardService(KnowledgeRepository(session))
    return await service.summary()


@router.post("/admin/acquisition/sources/seed", response_model=AcquisitionJobResponse)
async def seed_acquisition_sources(
    session: AsyncSession = Depends(get_session),
    settings: Settings = Depends(get_settings),
) -> AcquisitionJobResponse:
    service = AcquisitionService(session, settings)
    count = await service.seed_sources()
    await session.commit()
    return AcquisitionJobResponse(status="ok", detail={"sources_seeded": count})


@router.post("/admin/acquisition/research/discover", response_model=AcquisitionJobResponse)
async def discover_research_sources(
    request: AcquisitionDiscoverRequest,
    session: AsyncSession = Depends(get_session),
    settings: Settings = Depends(get_settings),
) -> AcquisitionJobResponse:
    service = AcquisitionService(session, settings)
    count = await service.discover_research(limit_per_topic=request.limit_per_topic)
    await session.commit()
    return AcquisitionJobResponse(status="ok", detail={"candidates_discovered": count})


@router.post("/admin/acquisition/download", response_model=AcquisitionJobResponse)
async def download_acquisition_candidates(
    request: AcquisitionDownloadRequest,
    session: AsyncSession = Depends(get_session),
    settings: Settings = Depends(get_settings),
) -> AcquisitionJobResponse:
    service = AcquisitionService(session, settings)
    result = await service.download_due_candidates(limit=request.limit)
    await session.commit()
    return AcquisitionJobResponse(status="ok", detail=result)


@router.get("/admin/acquisition/inventory")
async def acquisition_inventory(
    session: AsyncSession = Depends(get_session),
    settings: Settings = Depends(get_settings),
) -> dict:
    service = AcquisitionService(session, settings)
    return await service.inventory_dashboard()


@router.get("/admin/acquisition/report")
async def acquisition_report(
    session: AsyncSession = Depends(get_session),
    settings: Settings = Depends(get_settings),
) -> dict:
    service = AcquisitionService(session, settings)
    return await service.final_report()


@router.post("/admin/acquisition/manual", response_model=AcquisitionJobResponse)
async def upload_manual_resources(
    organization: str = Form(...),
    reviewer: str = Form(...),
    source: str = Form("BAHA/IAP manual library"),
    publication_date: date | None = Form(None),
    topic: str | None = Form(None),
    audience: str = Form("general"),
    language: str = Form("en"),
    files: list[UploadFile] = File(...),
    session: AsyncSession = Depends(get_session),
    settings: Settings = Depends(get_settings),
) -> AcquisitionJobResponse:
    if not files:
        raise HTTPException(status_code=400, detail="At least one resource file is required")
    try:
        with tempfile.TemporaryDirectory(prefix="baha-upload-") as temp_dir:
            paths: list[Path] = []
            for upload in files:
                filename = Path(upload.filename or "resource.bin").name
                target = Path(temp_dir) / uuid4().hex / filename
                target.parent.mkdir(parents=True)
                with target.open("wb") as output:
                    shutil.copyfileobj(upload.file, output)
                paths.append(target)
            result = await ManualResourceIngestionService(
                session,
                settings.storage_root,
            ).import_paths(
                paths,
                ManualResourceMetadata(
                    organization=organization,
                    reviewer=reviewer,
                    source=source,
                    publication_date=publication_date,
                    topic=topic,
                    audience=audience,
                    language=language,
                ),
            )
        await session.commit()
        return AcquisitionJobResponse(status="ok", detail=result)
    except (ValueError, FileNotFoundError) as exc:
        await session.rollback()
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.get("/admin/acquisition/priority-dashboard")
async def priority_acquisition_dashboard(
    session: AsyncSession = Depends(get_session),
    settings: Settings = Depends(get_settings),
) -> dict:
    return await AcquisitionService(session, settings).priority_dashboard()


@router.post("/admin/acquisition/gap-closure", response_model=AcquisitionJobResponse)
async def plan_priority_gap_closure(
    max_topics: int = 9,
    session: AsyncSession = Depends(get_session),
) -> AcquisitionJobResponse:
    result = await PriorityGapClosureEngine(session).plan(max_topics=max(1, min(max_topics, 9)))
    await session.commit()
    return AcquisitionJobResponse(status="ok", detail=result)


@router.get("/admin/acquisition/weekly-gap-report")
async def weekly_priority_gap_report(
    session: AsyncSession = Depends(get_session),
) -> dict:
    result = await PriorityGapClosureEngine(session).weekly_report()
    await session.commit()
    return result


@router.get("/admin/acquisition/priority-campaign-report")
async def aha_nimhans_campaign_report(
    session: AsyncSession = Depends(get_session),
) -> dict:
    return await PriorityCampaignService(session).report()


@router.get("/admin/acquisition/review-queue")
async def review_queue(session: AsyncSession = Depends(get_session), limit: int = 100) -> list[dict]:
    return await ClinicalReviewQueueService(session).list_pending(limit=limit)


@router.post("/admin/acquisition/review-queue/{review_id}")
async def decide_review_item(
    review_id: UUID,
    request: ReviewDecisionRequest,
    session: AsyncSession = Depends(get_session),
) -> dict[str, str]:
    try:
        await ClinicalReviewQueueService(session).decide(
            review_id, status=request.status, reviewer=request.reviewer, notes=request.notes
        )
        await session.commit()
    except ValueError as exc:
        await session.rollback()
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return {"status": "ok"}


async def _perspective_view(request: ViewRequest, retriever: HybridRetriever) -> dict:
    query = f"{request.condition} signs support when to seek help {request.audience}"
    results = await retriever.search(
        query,
        top_k=request.top_k,
        filters={
            "condition": request.condition,
            "age_group": request.age_group,
            "gender_group": request.gender_group,
        },
    )
    answer = EvidenceComposer().compose(
        condition=request.condition,
        perspective=request.audience,
        query=query,
        evidence=results,
    )
    return answer.model_dump()
