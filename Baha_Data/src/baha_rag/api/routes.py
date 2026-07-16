from __future__ import annotations

import importlib
import json
import shutil
import tempfile
from datetime import date, datetime, timezone
from pathlib import Path
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from fastapi.responses import StreamingResponse
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from baha_rag.auth import (
    ActorContext,
    TokenIdentity,
    build_dev_password_metadata,
    get_actor_context,
    get_provisioning_identity,
    verify_dev_password,
)
from baha_rag.config import Settings, get_settings
from baha_rag.dashboard.metrics import DashboardService
from baha_rag.db.auth_repository import AuthRepository
from baha_rag.db.mobile_repository import MobileAppRepository
from baha_rag.db.repository import KnowledgeRepository
from baha_rag.db.session import get_session
from baha_rag.embeddings.bge import EmbeddingService
from baha_rag.extraction.condition_profile import ConditionProfileExtractor
from baha_rag.generation.buddy import BuddyChatService
from baha_rag.generation.composer import EvidenceComposer
from baha_rag.identity import ROLE_PRIORITY
from baha_rag.privacy import PrivacyService
from baha_rag.retrieval.hybrid import HybridRetriever
from baha_rag.safety import assess_safety
from baha_rag.schemas import (
    AcquisitionDiscoverRequest,
    AcquisitionDownloadRequest,
    AcquisitionJobResponse,
    AuthApprovalDecisionRequest,
    AuthApprovalRequestSummary,
    AuthBootstrapRequest,
    AuthGuardianLinkStudentRequest,
    AuthOnboardingStateResponse,
    AuthParentSummaryConsentRequest,
    AuthParentSummaryConsentResponse,
    AuthPlatformParticipationConsentRequest,
    AuthPlatformParticipationConsentResponse,
    ChatRequest,
    ChatResponse,
    ChatSessionCreateRequest,
    ChatSessionSummary,
    CheckinSubmissionRequest,
    ConditionSummary,
    CounselorCaseDetailResponse,
    CounselorDashboardMetricResponse,
    CounselorCaseNote,
    CounselorCaseNoteCreateRequest,
    CounselorQueueResponse,
    HelpRequestCreateRequest,
    HelpRequestResponse,
    IngestResponse,
    IngestUrlRequest,
    LinkRemovalResponse,
    MobileChatExchangeResponse,
    MobileChatMessage,
    MobileChatMessageCreateRequest,
    MobileActorResponse,
    MobileCheckinTemplateDetail,
    MobileCheckinTemplateSummary,
    MobileContentDetail,
    MobileContentSummary,
    MobileLinkedStudentSummary,
    MobileModuleSummary,
    MobileSupportContact,
    ModuleProgressUpsertRequest,
    ModuleProgressUpsertResponse,
    ParentWeeklySummaryResponse,
    StoryWorldSceneResponse,
    StoryWorldStateResponse,
    StoryWorldTurnRequest,
    StoryWorldTurnResponse,
    PastoralFlagCreateRequest,
    PastoralFlagResponse,
    SearchRequest,
    SearchResponse,
    ReviewDecisionRequest,
    StudentCheckinDetail,
    StudentCheckinSummary,
    LinkedGuardianSummary,
    StudentLinkingStateResponse,
    StudentParentSummarySharingRequest,
    StudentWeeklySummaryResponse,
    TeacherClassStudentSummary,
    TeacherClassSummary,
    TeacherCohortSummaryResponse,
    ViewRequest,
)
from baha_rag.taxonomy import TAXONOMY, find_conditions
from baha_rag.story_world import STORY_WORLD_LOCATIONS

router = APIRouter()


def get_embedding_service(settings: Settings = Depends(get_settings)) -> EmbeddingService:
    if settings.embedding_backend == "bge":
        try:
            importlib.import_module("sentence_transformers")
        except ModuleNotFoundError as exc:
            raise HTTPException(
                status_code=503,
                detail=(
                    "The BGE embedding backend is not installed in this runtime. "
                    "Use EMBEDDING_BACKEND=hash or install the retrieval runtime."
                ),
            ) from exc
    return EmbeddingService(settings)


async def get_retriever(
    session: AsyncSession = Depends(get_session),
    embeddings: EmbeddingService = Depends(get_embedding_service),
) -> HybridRetriever:
    return HybridRetriever(KnowledgeRepository(session), embeddings)


def get_buddy_chat_service(
    settings: Settings = Depends(get_settings),
) -> BuddyChatService:
    return BuddyChatService(settings)


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


def _optional_dependency(module_name: str, *, feature: str):
    try:
        return importlib.import_module(module_name)
    except ModuleNotFoundError as exc:
        raise HTTPException(
            status_code=503,
            detail=(
                f"{feature} is not installed in this API runtime. "
                "Use the full backend runtime when you need acquisition or ingestion features."
            ),
        ) from exc


def _counselor_scope(actor: ActorContext) -> tuple[UUID | None, bool]:
    _require_counselor(actor)
    if "baha_admin" in actor.roles:
        return (None, True)
    if actor.school_id is None:
        raise HTTPException(status_code=403, detail="Counselor access requires a school-scoped profile")
    return (actor.school_id, False)


def _resolve_mobile_content_audience(
    *,
    actor: ActorContext,
    requested_audience: str | None,
) -> str:
    if requested_audience is None:
        return actor.app_audience
    allowed = {"student", "parent", "teacher", "counselor", "shared"}
    if requested_audience not in allowed:
        raise HTTPException(status_code=400, detail="Unsupported content audience")
    if requested_audience != actor.app_audience and not ({"counselor", "baha_admin", "administrator"} & set(actor.roles)):
        raise HTTPException(status_code=403, detail="Audience override is only available to counselor or BAHA admin roles")
    return requested_audience


def _assistant_body(response: ChatResponse) -> str:
    answer = response.answer
    return " ".join(
        [
            answer.what_it_is.strip(),
            answer.what_to_do.strip(),
            answer.when_to_seek_help.strip(),
        ]
    )


def _stream_event(payload: dict[str, object]) -> str:
    return json.dumps(payload, default=str) + "\n"


def _primary_role_from_roles(roles: list[str]) -> str | None:
    for role in ROLE_PRIORITY:
        if role in roles:
            return role
    return roles[0] if roles else None


def _calculate_age_years(date_of_birth: date) -> int:
    today = date.today()
    years = today.year - date_of_birth.year
    if (today.month, today.day) < (date_of_birth.month, date_of_birth.day):
        years -= 1
    return years


def _derive_legal_consent_band(request: AuthBootstrapRequest) -> str:
    if request.legal_consent_band is not None:
        return request.legal_consent_band
    if request.date_of_birth is not None:
        return "adult" if _calculate_age_years(request.date_of_birth) >= 18 else "minor"
    if request.age_cohort in {"18_plus", "adult"}:
        return "adult"
    return "minor"


def _dev_identity_password_is_valid(
    *,
    identity: TokenIdentity,
    account: dict | None,
) -> bool:
    if not identity.is_dev_identity or account is None:
        return True
    metadata = account.get("metadata") or {}
    if not isinstance(metadata, dict):
        metadata = {}
    return verify_dev_password(identity.password, metadata)


def _derive_student_age_cohort(request: AuthBootstrapRequest) -> str:
    if request.age_cohort:
        return request.age_cohort
    if request.date_of_birth is None:
        return "13_14"
    age_years = _calculate_age_years(request.date_of_birth)
    if age_years <= 12:
        return "9_12"
    if age_years <= 14:
        return "13_14"
    if age_years <= 17:
        return "15_18"
    return "18_plus"


async def _build_onboarding_state(
    repository: AuthRepository,
    *,
    identity_match_mode: str,
    external_auth_id: str,
    account: dict | None,
    detail: str | None = None,
) -> AuthOnboardingStateResponse:
    if account is None:
        return AuthOnboardingStateResponse(
            has_baha_user=False,
            identity_match_mode=identity_match_mode,
            external_auth_id=external_auth_id,
            approval_status="not_required",
            consent_status="not_required",
            guardian_link_status="not_required",
            next_step="bootstrap",
            detail=detail,
        )

    roles = [role for role in (account["roles"] or []) if role]
    primary_role = _primary_role_from_roles(roles)
    account_status = account["account_status"]
    linked_student_count = 0
    linked_guardian_count = 0
    guardian_link_verification_code = None
    approval_status = "not_required"
    consent_status = "not_required"
    guardian_link_status = "not_required"
    next_step = "ready"

    if primary_role == "guardian" and account["guardian_id"] is not None:
        linked_student_count = await repository.count_active_linked_students_for_guardian(guardian_id=account["guardian_id"])
    if primary_role == "student" and account["student_profile_id"] is not None:
        linked_guardian_count = await repository.count_active_guardian_links_for_student(student_profile_id=account["student_profile_id"])
        if account["legal_consent_band"] == "minor" and linked_guardian_count == 0:
            guardian_link_verification_code = await repository.ensure_student_guardian_link_code(
                student_profile_id=account["student_profile_id"]
            )
        else:
            code_state = await repository.get_student_guardian_link_code_state(
                student_profile_id=account["student_profile_id"]
            )
            guardian_link_verification_code = (
                code_state.get("guardian_link_verification_code")
                if code_state
                else None
            )

    if primary_role in {"teacher", "counselor", "administrator"}:
        approval_row = await repository.get_latest_approval_request(
            user_id=account["user_id"],
            requested_role=primary_role,
        )
        approval_status = approval_row["status"] if approval_row else ("approved" if account_status == "active" else "pending")

    if primary_role == "student" and account["legal_consent_band"] == "minor":
        consent_row = await repository.get_latest_platform_participation_consent(student_user_id=account["user_id"])
        consent_status = consent_row["status"] if consent_row else "pending"
        guardian_link_status = "linked" if linked_guardian_count > 0 else "pending"
    elif primary_role == "guardian":
        guardian_link_status = "linked" if linked_student_count > 0 else "pending"

    if primary_role is None:
        next_step = "bootstrap"
    elif primary_role == "student":
        if account["student_profile_id"] is None:
            next_step = "complete_profile"
        elif account["legal_consent_band"] == "minor" and linked_guardian_count == 0:
            next_step = "await_guardian_link"
        elif account["legal_consent_band"] == "minor" and consent_status != "granted":
            next_step = "await_guardian_consent"
        elif account_status != "active":
            next_step = "await_activation"
    elif primary_role == "guardian":
        if account["guardian_id"] is None:
            next_step = "complete_profile"
        elif linked_student_count == 0:
            next_step = "link_student"
    elif primary_role in {"teacher", "counselor", "administrator"}:
        if account["teacher_profile_id"] is None:
            next_step = "complete_profile"
        elif approval_status == "approved" and account_status == "active":
            next_step = "ready"
        elif approval_status == "rejected":
            next_step = "approval_rejected"
        else:
            next_step = "await_approval"
    elif primary_role == "baha_admin":
        next_step = "ready"

    return AuthOnboardingStateResponse(
        has_baha_user=True,
        identity_match_mode=identity_match_mode,
        external_auth_id=external_auth_id,
        user_id=account["user_id"],
        email=account["email"],
        display_name=account["display_name"],
        account_status=account_status,
        roles=roles,
        primary_role=primary_role,
        school_id=account["school_id"],
        student_profile_id=account["student_profile_id"],
        guardian_id=account["guardian_id"],
        teacher_profile_id=account["teacher_profile_id"],
        student_code=account["student_code"],
        guardian_link_verification_code=guardian_link_verification_code,
        age_cohort=account["presentation_age_cohort"],
        legal_consent_band=account["legal_consent_band"],
        approval_status=approval_status,
        consent_status=consent_status,
        guardian_link_status=guardian_link_status,
        linked_student_count=linked_student_count,
        linked_guardian_count=linked_guardian_count,
        next_step=next_step,
        detail=detail,
    )


def _reviewer_scope(actor: ActorContext) -> tuple[str, UUID | None]:
    if "baha_admin" in actor.roles:
        return ("baha_admin", actor.school_id)
    if "administrator" in actor.roles:
        return ("administrator", actor.school_id)
    raise HTTPException(status_code=403, detail="Approval review requires administrator or BAHA admin access")


def _normalize_verification_code(value: str | None) -> str:
    return (value or "").strip().replace(" ", "")


def _build_parent_safe_summary(
    student_summary: dict[str, object],
    *,
    visible_tiers: list[str],
) -> dict[str, object]:
    risk_flags = student_summary.get("risk_flags")
    if not isinstance(risk_flags, list):
        risk_flags = []
    trend_labels = student_summary.get("trend_labels")
    if not isinstance(trend_labels, list):
        trend_labels = []
    focus_dimensions = student_summary.get("focus_dimensions")
    if not isinstance(focus_dimensions, list):
        focus_dimensions = []

    return {
        "headline": student_summary.get("headline") or "No summary has been generated yet.",
        "week_story": student_summary.get("week_story")
        or "BAHA is still building a weekly pattern summary for this student.",
        "best_progress": student_summary.get("best_progress") or "No clear improvement trend detected yet.",
        "watch_area": student_summary.get("watch_area") or "No watch area has been flagged yet.",
        "support_nudge": student_summary.get("support_nudge")
        or "Use a calm check-in conversation and watch for repeated patterns over time.",
        "risk_flags": risk_flags,
        "trend_labels": trend_labels,
        "focus_dimensions": focus_dimensions,
        "visible_tiers": visible_tiers,
        "privacy_note": (
            "This parent view intentionally hides individual student answers and only shows "
            "high-level weekly trends and alert signals."
        ),
        "derived_from_student_summary": True,
    }


def _ensure_request_visible_to_reviewer(
    *,
    reviewer_role: str,
    reviewer_school_id: UUID | None,
    request_row: dict[str, object],
) -> None:
    if reviewer_role == "baha_admin":
        return
    if reviewer_role == "administrator":
        if request_row["requested_role"] != "teacher" or request_row["school_id"] != reviewer_school_id:
            raise HTTPException(status_code=403, detail="Administrator can only review teacher approvals for their school")
        return
    raise HTTPException(status_code=403, detail="Reviewer role is not permitted for this approval workflow")


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
async def chat(
    request: ChatRequest,
    retriever: HybridRetriever = Depends(get_retriever),
    buddy_chat_service: BuddyChatService = Depends(get_buddy_chat_service),
) -> ChatResponse:
    result = await buddy_chat_service.generate(
        request=request,
        retriever=retriever,
        history=[],
    )
    return result.response


@router.post("/auth/bootstrap", response_model=AuthOnboardingStateResponse)
async def auth_bootstrap(
    request: AuthBootstrapRequest,
    identity: TokenIdentity = Depends(get_provisioning_identity),
    session: AsyncSession = Depends(get_session),
) -> AuthOnboardingStateResponse:
    if request.role == "administrator":
        create_school_if_missing = True
    else:
        create_school_if_missing = False

    repository = AuthRepository(session)
    existing = await repository.get_account_context_by_external_auth_id(identity.subject)
    identity_match_mode = "external_auth_id"
    if existing is not None and not _dev_identity_password_is_valid(
        identity=identity,
        account=existing,
    ):
        raise HTTPException(status_code=401, detail="Incorrect sign-in ID or password")
    if existing is None and identity.email:
        email_count = await repository.count_users_by_email(identity.email)
        if email_count > 1:
            raise HTTPException(
                status_code=409,
                detail="Multiple BAHA users share this email; automatic bootstrap linking is not allowed",
            )
        if email_count == 1:
            existing = await repository.get_account_context_by_unique_email(identity.email)
            identity_match_mode = "email"

    if existing is not None and existing["roles"] and request.role not in (existing["roles"] or []):
        raise HTTPException(
            status_code=409,
            detail="Bootstrap cannot add a second role to an existing BAHA user yet",
        )

    school_id = await repository.resolve_school_id(
        school_id=request.school_id,
        school_name=request.school_name,
        create_if_missing=create_school_if_missing,
    )

    if request.role == "student" and school_id is None:
        raise HTTPException(status_code=400, detail="Student bootstrap requires a valid school")
    if request.role in {"teacher", "administrator"} and school_id is None:
        raise HTTPException(status_code=400, detail=f"{request.role} bootstrap requires a valid school")

    legal_consent_band = _derive_legal_consent_band(request) if request.role == "student" else None
    account_status = "active"
    if request.role in {"teacher", "counselor", "administrator"}:
        account_status = "pending"
    elif request.role == "student" and legal_consent_band == "minor":
        account_status = "pending"
    if existing is not None and request.role in (existing["roles"] or []) and existing["account_status"] == "active":
        account_status = "active"

    metadata = {
        "bootstrap_role": request.role,
        "bootstrap_source": "auth_bootstrap",
        **request.metadata,
    }
    if identity.is_dev_identity and identity.password:
        metadata.update(build_dev_password_metadata(identity.password))
    user_id = await repository.upsert_user(
        user_id=existing["user_id"] if existing else None,
        external_auth_id=identity.subject,
        email=request.email or identity.email or (existing["email"] if existing else None),
        phone=request.phone,
        display_name=request.display_name,
        preferred_language=request.preferred_language,
        status=account_status,
        metadata_json=json.dumps(metadata),
    )
    await repository.ensure_role_assignment(user_id=user_id, role_key=request.role)

    if request.role == "student":
        student_profile_id = await repository.upsert_student_profile(
            user_id=user_id,
            school_id=school_id,
            age_cohort=_derive_student_age_cohort(request),
            legal_consent_band=legal_consent_band,
            date_of_birth=request.date_of_birth.isoformat() if request.date_of_birth else None,
            gender=request.gender,
            metadata_json=json.dumps(request.metadata),
        )
        await repository.ensure_student_guardian_link_code(
            student_profile_id=student_profile_id
        )
    elif request.role == "guardian":
        await repository.upsert_guardian_profile(
            user_id=user_id,
            guardian_type=request.guardian_type,
            metadata_json=json.dumps(request.metadata),
        )
    elif request.role in {"teacher", "counselor", "administrator"}:
        await repository.upsert_teacher_profile(
            user_id=user_id,
            school_id=school_id,
            staff_code=request.staff_code,
            staff_type=request.role,
            metadata_json=json.dumps(request.metadata),
        )
        await repository.create_or_refresh_approval_request(
            user_id=user_id,
            requested_role=request.role,
            school_id=school_id,
            metadata_json=json.dumps(request.metadata),
        )

    await session.commit()
    account = await repository.get_account_context_by_user_id(user_id)
    return await _build_onboarding_state(
        repository,
        identity_match_mode=identity_match_mode,
        external_auth_id=identity.subject,
        account=account,
    )


@router.get("/auth/onboarding-state", response_model=AuthOnboardingStateResponse)
async def auth_onboarding_state(
    identity: TokenIdentity = Depends(get_provisioning_identity),
    session: AsyncSession = Depends(get_session),
    entry_mode: str = "session",
) -> AuthOnboardingStateResponse:
    repository = AuthRepository(session)
    account = await repository.get_account_context_by_external_auth_id(identity.subject)
    if account is not None:
        if entry_mode != "register" and not _dev_identity_password_is_valid(
            identity=identity,
            account=account,
        ):
            raise HTTPException(status_code=401, detail="Incorrect sign-in ID or password")
        return await _build_onboarding_state(
            repository,
            identity_match_mode="external_auth_id",
            external_auth_id=identity.subject,
            account=account,
        )
    if identity.email:
        email_count = await repository.count_users_by_email(identity.email)
        if email_count > 1:
            return await _build_onboarding_state(
                repository,
                identity_match_mode="duplicate_email",
                external_auth_id=identity.subject,
                account=None,
                detail="Multiple BAHA users share this email; manual identity linking is required",
            )
        if email_count == 1:
            email_match = await repository.get_account_context_by_unique_email(identity.email)
            return await _build_onboarding_state(
                repository,
                identity_match_mode="email",
                external_auth_id=identity.subject,
                account=email_match,
            )
    return await _build_onboarding_state(
        repository,
        identity_match_mode="none",
        external_auth_id=identity.subject,
        account=None,
    )


@router.get("/auth/me", response_model=AuthOnboardingStateResponse)
async def auth_me(
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> AuthOnboardingStateResponse:
    repository = AuthRepository(session)
    account = await repository.get_account_context_by_user_id(actor.user_id)
    return await _build_onboarding_state(
        repository,
        identity_match_mode="external_auth_id",
        external_auth_id=actor.external_auth_id or "",
        account=account,
    )


@router.post("/auth/guardian/link-student", response_model=AuthOnboardingStateResponse)
async def auth_guardian_link_student(
    request: AuthGuardianLinkStudentRequest,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> AuthOnboardingStateResponse:
    _require_guardian(actor)
    repository = AuthRepository(session)
    student = await repository.get_student_for_link(
        student_profile_id=request.student_profile_id,
        student_code=request.student_code,
    )
    if student is None:
        raise HTTPException(status_code=404, detail="Student not found")
    metadata = student.get("metadata") or {}
    if not isinstance(metadata, dict):
        metadata = {}
    expected_code = _normalize_verification_code(
        metadata.get("guardian_link_verification_code")
    )
    expires_at_raw = str(metadata.get("guardian_link_code_expires_at") or "").strip()
    provided_code = _normalize_verification_code(request.verification_code)
    expires_at = None
    if expires_at_raw:
        try:
            expires_at = datetime.fromisoformat(expires_at_raw.replace("Z", "+00:00"))
        except ValueError:
            expires_at = None
    if not expected_code or expires_at is None or expires_at <= datetime.now(timezone.utc):
        raise HTTPException(
            status_code=403,
            detail="Verification code is missing or expired. Ask the student to generate a new code.",
        )
    if provided_code != expected_code:
        raise HTTPException(
            status_code=403,
            detail="Verification code did not match this student account",
        )
    await repository.upsert_guardian_link(
        student_profile_id=student["student_profile_id"],
        guardian_id=actor.guardian_id,
        relationship_to_student=request.relationship_to_student,
        is_primary=request.is_primary,
        consent_authority=request.consent_authority,
    )
    await session.commit()
    account = await repository.get_account_context_by_user_id(actor.user_id)
    return await _build_onboarding_state(
        repository,
        identity_match_mode="external_auth_id",
        external_auth_id=actor.external_auth_id or "",
        account=account,
    )


@router.get(
    "/auth/guardian/consent/platform-participation/{student_profile_id}",
    response_model=AuthPlatformParticipationConsentResponse,
)
async def auth_guardian_platform_participation_consent_status(
    student_profile_id: UUID,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> AuthPlatformParticipationConsentResponse:
    _require_guardian(actor)
    repository = AuthRepository(session)
    student = await repository.get_student_for_link(
        student_profile_id=student_profile_id,
        student_code=None,
    )
    if student is None:
        raise HTTPException(status_code=404, detail="Student not found")
    link = await repository.get_active_guardian_link(
        student_profile_id=student["student_profile_id"],
        guardian_id=actor.guardian_id,
    )
    if link is None or not link["consent_authority"]:
        raise HTTPException(status_code=403, detail="Guardian does not have active consent authority for this student")
    if student["legal_consent_band"] != "minor":
        return AuthPlatformParticipationConsentResponse(
            consent_version_id=None,
            student_profile_id=student["student_profile_id"],
            guardian_id=actor.guardian_id,
            status="granted",
            scope="platform_access",
            actor_relationship=link["relationship_to_student"],
            granted_at=None,
            withdrawn_at=None,
            created_at=None,
        )
    consent_row = await repository.get_latest_platform_participation_consent(
        student_user_id=student["student_user_id"]
    )
    if consent_row is not None:
        return AuthPlatformParticipationConsentResponse(
            consent_version_id=None,
            student_profile_id=student["student_profile_id"],
            guardian_id=actor.guardian_id,
            status=consent_row["status"],
            scope="platform_access",
            actor_relationship=link["relationship_to_student"],
            granted_at=consent_row.get("granted_at"),
            withdrawn_at=consent_row.get("withdrawn_at"),
            created_at=consent_row.get("granted_at") or consent_row.get("withdrawn_at"),
        )

    consent_version = await repository.get_latest_active_consent_version(
        consent_type="platform_participation"
    )
    return AuthPlatformParticipationConsentResponse(
        consent_version_id=consent_version["id"] if consent_version else None,
        student_profile_id=student["student_profile_id"],
        guardian_id=actor.guardian_id,
        status="pending",
        scope="platform_access",
        actor_relationship=link["relationship_to_student"],
    )


@router.post("/auth/guardian/consent/platform-participation", response_model=AuthOnboardingStateResponse)
async def auth_guardian_platform_participation_consent(
    request: AuthPlatformParticipationConsentRequest,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> AuthOnboardingStateResponse:
    _require_guardian(actor)
    repository = AuthRepository(session)
    student = await repository.get_student_for_link(
        student_profile_id=request.student_profile_id,
        student_code=None,
    )
    if student is None:
        raise HTTPException(status_code=404, detail="Student not found")
    if student["legal_consent_band"] != "minor":
        raise HTTPException(
            status_code=400,
            detail="Platform participation approval is only required for under-18 students",
        )
    link = await repository.get_active_guardian_link(
        student_profile_id=student["student_profile_id"],
        guardian_id=actor.guardian_id,
    )
    if link is None or not link["consent_authority"]:
        raise HTTPException(status_code=403, detail="Guardian does not have active consent authority for this student")
    consent_version = await repository.get_latest_active_consent_version(consent_type="platform_participation")
    if consent_version is None:
        raise HTTPException(status_code=500, detail="No active platform participation consent version is configured")
    await repository.create_platform_participation_consent(
        consent_version_id=consent_version["id"],
        student_user_id=student["student_user_id"],
        guardian_user_id=actor.user_id,
        student_profile_id=student["student_profile_id"],
        guardian_id=actor.guardian_id,
        actor_relationship=link["relationship_to_student"],
        status=request.status,
    )
    await repository.set_user_status(
        user_id=student["student_user_id"],
        status="active" if request.status == "granted" else "pending",
    )
    await session.commit()
    student_account = await repository.get_account_context_by_user_id(student["student_user_id"])
    return await _build_onboarding_state(
        repository,
        identity_match_mode="external_auth_id",
        external_auth_id=student_account["external_auth_id"] if student_account else "",
        account=student_account,
    )


@router.get(
    "/auth/guardian/consent/parent-summary-sharing/{student_profile_id}",
    response_model=AuthParentSummaryConsentResponse,
)
async def auth_guardian_parent_summary_consent_status(
    student_profile_id: UUID,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> AuthParentSummaryConsentResponse:
    _require_guardian(actor)
    repository = AuthRepository(session)
    student = await repository.get_student_for_link(
        student_profile_id=student_profile_id,
        student_code=None,
    )
    if student is None:
        raise HTTPException(status_code=404, detail="Student not found")
    link = await repository.get_active_guardian_link(
        student_profile_id=student["student_profile_id"],
        guardian_id=actor.guardian_id,
    )
    if link is None or not link["consent_authority"]:
        raise HTTPException(status_code=403, detail="Guardian does not have active consent authority for this student")
    consent_row = await repository.get_latest_parent_summary_sharing_consent(
        student_profile_id=student["student_profile_id"],
        guardian_id=actor.guardian_id,
    )
    if consent_row is not None:
        return AuthParentSummaryConsentResponse.model_validate(consent_row)

    consent_version = await repository.get_latest_active_consent_version(consent_type="parent_summary_sharing")
    return AuthParentSummaryConsentResponse(
        consent_version_id=consent_version["id"] if consent_version else None,
        student_profile_id=student["student_profile_id"],
        guardian_id=actor.guardian_id,
        status="pending",
        scope="weekly_summaries",
        actor_relationship=link["relationship_to_student"],
    )


@router.post(
    "/auth/guardian/consent/parent-summary-sharing",
    response_model=AuthParentSummaryConsentResponse,
)
async def auth_guardian_parent_summary_consent(
    request: AuthParentSummaryConsentRequest,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> AuthParentSummaryConsentResponse:
    _require_guardian(actor)
    repository = AuthRepository(session)
    student = await repository.get_student_for_link(
        student_profile_id=request.student_profile_id,
        student_code=None,
    )
    if student is None:
        raise HTTPException(status_code=404, detail="Student not found")
    link = await repository.get_active_guardian_link(
        student_profile_id=student["student_profile_id"],
        guardian_id=actor.guardian_id,
    )
    if link is None or not link["consent_authority"]:
        raise HTTPException(status_code=403, detail="Guardian does not have active consent authority for this student")
    consent_version = await repository.get_latest_active_consent_version(consent_type="parent_summary_sharing")
    if consent_version is None:
        raise HTTPException(status_code=500, detail="No active parent summary consent version is configured")
    await repository.create_parent_summary_sharing_consent(
        consent_version_id=consent_version["id"],
        student_user_id=student["student_user_id"],
        guardian_user_id=actor.user_id,
        student_profile_id=student["student_profile_id"],
        guardian_id=actor.guardian_id,
        actor_relationship=link["relationship_to_student"],
        status=request.status,
    )
    await session.commit()
    consent_row = await repository.get_latest_parent_summary_sharing_consent(
        student_profile_id=student["student_profile_id"],
        guardian_id=actor.guardian_id,
    )
    if consent_row is None:
        raise HTTPException(status_code=500, detail="Parent summary consent could not be loaded after write")
    return AuthParentSummaryConsentResponse.model_validate(consent_row)


@router.get("/auth/approval-requests", response_model=list[AuthApprovalRequestSummary])
async def auth_approval_requests(
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
    status: str = "pending",
) -> list[AuthApprovalRequestSummary]:
    reviewer_role, reviewer_school_id = _reviewer_scope(actor)
    repository = AuthRepository(session)
    rows = await repository.list_approval_requests_for_reviewer(
        reviewer_role=reviewer_role,
        reviewer_school_id=reviewer_school_id,
        status=status,
    )
    return [AuthApprovalRequestSummary.model_validate(row) for row in rows]


@router.post("/auth/approval-requests/{request_id}/decision", response_model=AuthApprovalRequestSummary)
async def auth_approval_request_decision(
    request_id: UUID,
    request: AuthApprovalDecisionRequest,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> AuthApprovalRequestSummary:
    reviewer_role, reviewer_school_id = _reviewer_scope(actor)
    repository = AuthRepository(session)
    existing_request = await repository.get_approval_request_by_id(request_id=request_id)
    if existing_request is None:
        raise HTTPException(status_code=404, detail="Approval request not found")
    _ensure_request_visible_to_reviewer(
        reviewer_role=reviewer_role,
        reviewer_school_id=reviewer_school_id,
        request_row=existing_request,
    )
    decided = await repository.decide_approval_request(
        request_id=request_id,
        reviewer_user_id=actor.user_id,
        reviewer_notes=request.reviewer_notes,
        status=request.status,
    )
    if decided is None:
        raise HTTPException(status_code=409, detail="Approval request is no longer pending")
    if request.status == "approved":
        await repository.set_user_status(user_id=decided["user_id"], status="active")
    elif request.status in {"rejected", "revoked"}:
        await repository.set_user_status(user_id=decided["user_id"], status="pending")
    await session.commit()
    rows = await repository.list_approval_requests_for_reviewer(
        reviewer_role=reviewer_role,
        reviewer_school_id=reviewer_school_id,
        status=request.status,
    )
    resolved = next((row for row in rows if row["id"] == request_id), None)
    if resolved is None:
        refreshed = await repository.get_approval_request_by_id(request_id=request_id)
        if refreshed is None:
            raise HTTPException(status_code=404, detail="Approval request not found after decision")
        rows = await repository.list_approval_requests_for_reviewer(
            reviewer_role="baha_admin",
            reviewer_school_id=reviewer_school_id,
            status=request.status,
        )
        resolved = next((row for row in rows if row["id"] == request_id), None)
    if resolved is None:
        raise HTTPException(status_code=500, detail="Approval request was updated but could not be reloaded")
    return AuthApprovalRequestSummary.model_validate(resolved)


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
        school_name=actor.school_name,
        user_metadata=actor.user_metadata,
        student_metadata=actor.student_metadata,
    )


@router.get("/mobile/student/linking-state", response_model=StudentLinkingStateResponse)
async def mobile_student_linking_state(
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> StudentLinkingStateResponse:
    _require_student(actor)
    row = await MobileAppRepository(session).get_student_linking_state(
        student_profile_id=actor.student_profile_id
    )
    if row is None:
        raise HTTPException(status_code=404, detail="Student linking state not found")
    return StudentLinkingStateResponse.model_validate(row)


@router.post("/mobile/student/linking-code", response_model=StudentLinkingStateResponse)
async def mobile_student_linking_code(
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> StudentLinkingStateResponse:
    _require_student(actor)
    row = await MobileAppRepository(session).issue_student_guardian_link_code(
        student_profile_id=actor.student_profile_id
    )
    if row is None:
        raise HTTPException(status_code=404, detail="Student linking state not found")
    await session.commit()
    return StudentLinkingStateResponse.model_validate(row)


@router.post("/mobile/student/parent-summary-sharing", response_model=StudentLinkingStateResponse)
async def mobile_student_parent_summary_sharing(
    request: StudentParentSummarySharingRequest,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> StudentLinkingStateResponse:
    _require_student(actor)
    row = await MobileAppRepository(session).set_student_parent_summary_sharing(
        student_profile_id=actor.student_profile_id,
        enabled=request.enabled,
    )
    if row is None:
        raise HTTPException(status_code=404, detail="Student linking state not found")
    await session.commit()
    return StudentLinkingStateResponse.model_validate(row)


@router.delete(
    "/mobile/student/guardians/{guardian_id}",
    response_model=StudentLinkingStateResponse,
)
async def mobile_student_unpair_guardian(
    guardian_id: UUID,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> StudentLinkingStateResponse:
    _require_student(actor)
    repository = MobileAppRepository(session)
    removed = await repository.deactivate_student_guardian_link(
        student_profile_id=actor.student_profile_id,
        guardian_id=guardian_id,
    )
    if not removed:
        raise HTTPException(status_code=404, detail="Active guardian link not found")
    await session.commit()
    row = await repository.get_student_linking_state(
        student_profile_id=actor.student_profile_id
    )
    if row is None:
        raise HTTPException(status_code=404, detail="Student linking state not found")
    return StudentLinkingStateResponse.model_validate(row)


@router.delete(
    "/mobile/parent/students/{student_profile_id}/link",
    response_model=LinkRemovalResponse,
)
async def mobile_parent_unpair_student(
    student_profile_id: UUID,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> LinkRemovalResponse:
    _require_guardian(actor)
    repository = MobileAppRepository(session)
    removed = await repository.deactivate_student_guardian_link(
        student_profile_id=student_profile_id,
        guardian_id=actor.guardian_id,
    )
    if not removed:
        raise HTTPException(status_code=404, detail="Active student link not found")
    await session.commit()
    return LinkRemovalResponse(
        student_profile_id=student_profile_id,
        guardian_id=actor.guardian_id,
        removed=True,
        message="Parent and student link removed",
    )


@router.get("/mobile/support-contacts", response_model=list[MobileSupportContact])
async def mobile_support_contacts(
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> list[MobileSupportContact]:
    rows = await MobileAppRepository(session).list_support_contacts(
        audience_app=actor.app_audience,
        school_id=actor.school_id,
    )
    return [MobileSupportContact.model_validate(row) for row in rows]


@router.get("/mobile/content/feed", response_model=list[MobileContentSummary])
async def mobile_content_feed(
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
    audience_app: str | None = None,
    content_type: str | None = None,
    age_cohort: str | None = None,
    theme: str | None = None,
    topic: str | None = None,
    subtopic: str | None = None,
    limit: int = 20,
) -> list[MobileContentSummary]:
    resolved_audience = _resolve_mobile_content_audience(
        actor=actor,
        requested_audience=audience_app,
    )
    resolved_age_cohort = age_cohort
    if resolved_audience == "student" and "student" in actor.roles and resolved_age_cohort is None:
        resolved_age_cohort = actor.age_cohort
    rows = await MobileAppRepository(session).list_published_content(
        audience_app=resolved_audience,
        age_cohort=resolved_age_cohort,
        content_type=content_type,
        theme=theme,
        topic=topic,
        subtopic=subtopic,
        limit=max(1, min(limit, 50)),
    )
    return [MobileContentSummary.model_validate(row) for row in rows]


@router.get("/mobile/content/{content_item_id}", response_model=MobileContentDetail)
async def mobile_content_detail(
    content_item_id: UUID,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
    audience_app: str | None = None,
    age_cohort: str | None = None,
) -> MobileContentDetail:
    resolved_audience = _resolve_mobile_content_audience(
        actor=actor,
        requested_audience=audience_app,
    )
    resolved_age_cohort = age_cohort
    if resolved_audience == "student" and "student" in actor.roles and resolved_age_cohort is None:
        resolved_age_cohort = actor.age_cohort
    row = await MobileAppRepository(session).get_published_content_detail(
        content_item_id=content_item_id,
        audience_app=resolved_audience,
        age_cohort=resolved_age_cohort,
    )
    if row is None:
        raise HTTPException(status_code=404, detail="Content item not found")
    return MobileContentDetail.model_validate(row)


@router.get("/mobile/student/weekly-summary/latest", response_model=StudentWeeklySummaryResponse)
async def mobile_student_latest_weekly_summary(
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> StudentWeeklySummaryResponse:
    _require_student(actor)
    row = await MobileAppRepository(session).get_latest_student_weekly_summary(
        student_profile_id=actor.student_profile_id,
    )
    if row is None:
        raise HTTPException(status_code=404, detail="Student weekly summary not found")
    return StudentWeeklySummaryResponse.model_validate(row)


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
    theme: str | None = None,
) -> list[MobileModuleSummary]:
    _require_student(actor)
    rows = await MobileAppRepository(session).list_student_modules(
        user_id=actor.user_id,
        student_profile_id=actor.student_profile_id,
        age_cohort=actor.age_cohort,
        theme=theme,
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


@router.get("/mobile/student/games/story-world/state", response_model=StoryWorldStateResponse)
async def mobile_story_world_state(
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> StoryWorldStateResponse:
    _require_student(actor)
    row = await MobileAppRepository(session).get_story_world_state(
        student_profile_id=actor.student_profile_id,
        display_name=actor.display_name,
        age_cohort=actor.age_cohort,
    )
    return StoryWorldStateResponse.model_validate(row)


@router.get("/mobile/student/games/story-world/scenes/{location_id}", response_model=StoryWorldSceneResponse)
async def mobile_story_world_scene(
    location_id: str,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> StoryWorldSceneResponse:
    _require_student(actor)
    if location_id not in STORY_WORLD_LOCATIONS:
        raise HTTPException(status_code=404, detail="Story World location not found")
    row = await MobileAppRepository(session).get_story_world_scene(
        student_profile_id=actor.student_profile_id,
        display_name=actor.display_name,
        age_cohort=actor.age_cohort,
        location_id=location_id,
    )
    return StoryWorldSceneResponse.model_validate(row)


@router.post("/mobile/student/games/story-world/turns", response_model=StoryWorldTurnResponse)
async def mobile_story_world_turn(
    request: StoryWorldTurnRequest,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> StoryWorldTurnResponse:
    _require_student(actor)
    if request.location_id not in STORY_WORLD_LOCATIONS:
        raise HTTPException(status_code=404, detail="Story World location not found")
    safety = assess_safety(request.answer)
    try:
        row = await MobileAppRepository(session).submit_story_world_turn(
            student_profile_id=actor.student_profile_id,
            display_name=actor.display_name,
            age_cohort=actor.age_cohort,
            location_id=request.location_id,
            answer=request.answer,
            expected_chapter=request.expected_chapter,
            emergency=bool(safety.emergency_indicators),
        )
    except ValueError as exc:
        raise HTTPException(status_code=409, detail=str(exc)) from exc
    if safety.emergency_indicators:
        signal = await MobileAppRepository(session).create_monitoring_signal(
            student_profile_id=actor.student_profile_id,
            signal_type="game_behavior_signal",
            severity="emergency",
            title="Emergency language detected in Story World",
            signal_summary="Student entered emergency safety language during Story World gameplay.",
            derived_facts_json=json.dumps(
                {
                    "game_session_id": str(row["session_id"]),
                    "location_id": request.location_id,
                    "answer": request.answer,
                }
            ),
        )
        await MobileAppRepository(session).create_escalation_case(
            student_profile_id=actor.student_profile_id,
            primary_signal_id=signal["id"],
            opened_by_user_id=actor.user_id,
            case_type="crisis",
            severity="emergency",
            title="Story World emergency escalation",
            summary="Story World turn triggered an emergency safeguarding review.",
            privacy_override_active=True,
            override_reason="Emergency Story World signal",
        )
    await session.commit()
    return StoryWorldTurnResponse(
        state=StoryWorldStateResponse.model_validate(row["state"]),
        scene=StoryWorldSceneResponse.model_validate(row["scene"]),
        message=row["message"],
        memory=row["memory"],
        xp_earned=row["xp_earned"],
        coins_earned=row["coins_earned"],
        stars_earned=row["stars_earned"],
        observed_signals=row["observed_signals"],
    )


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
    buddy_chat_service: BuddyChatService = Depends(get_buddy_chat_service),
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

    history_rows = await MobileAppRepository(session).list_chat_messages(
        chat_session_id=session_id,
    )
    chat_result = await buddy_chat_service.generate(
        request=ChatRequest(
            message=request.body,
            audience=(
                "adolescent"
                if actor.app_audience == "student"
                else actor.app_audience
            ),
            age_cohort=actor.age_cohort,
            filters=request.filters,
        ),
        retriever=retriever,
        history=[
            {
                "role": (
                    "assistant" if row["sender_type"] == "assistant" else "user"
                ),
                "content": row["body"],
            }
            for row in history_rows
        ],
    )
    chat_response = chat_result.response
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
        structured_payload_json=json.dumps(
            {
                "answer": chat_response.answer.model_dump(mode="json"),
                "generation": {
                    "backend_used": chat_result.backend_used,
                    "fallback_reason": chat_result.fallback_reason,
                },
            }
        ),
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


@router.post("/mobile/chat/sessions/{session_id}/messages/stream")
async def mobile_create_chat_message_stream(
    session_id: UUID,
    request: MobileChatMessageCreateRequest,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
    retriever: HybridRetriever = Depends(get_retriever),
    buddy_chat_service: BuddyChatService = Depends(get_buddy_chat_service),
) -> StreamingResponse:
    repository = MobileAppRepository(session)
    owned = await repository.get_chat_session_owned(
        session_id=session_id,
        user_id=actor.user_id,
        audience_app=actor.app_audience,
        student_profile_id=actor.student_profile_id if "student" in actor.roles else None,
    )
    if owned is None:
        raise HTTPException(status_code=404, detail="Chat session not found")

    user_message_row = await repository.create_chat_message(
        chat_session_id=session_id,
        sender_type="user",
        message_type="user_query",
        body=request.body,
        retrieval_filters_json=json.dumps(request.filters),
    )

    history_rows = await repository.list_chat_messages(
        chat_session_id=session_id,
    )
    chat_request = ChatRequest(
        message=request.body,
        audience=(
            "adolescent"
            if actor.app_audience == "student"
            else actor.app_audience
        ),
        age_cohort=actor.age_cohort,
        filters=request.filters,
    )
    history = [
        {
            "role": (
                "assistant" if row["sender_type"] == "assistant" else "user"
            ),
            "content": row["body"],
        }
        for row in history_rows
    ]
    plan = await buddy_chat_service.prepare_reply(
        request=chat_request,
        retriever=retriever,
    )

    async def event_stream() -> AsyncIterator[str]:
        accumulated = ""
        backend_used = plan.strategy
        fallback_reason = plan.fallback_reason
        chat_response: ChatResponse
        try:
            yield _stream_event(
                {
                    "type": "ack",
                    "user_message": MobileChatMessage.model_validate(
                        user_message_row
                    ).model_dump(mode="json"),
                    "backend_used": backend_used,
                    "fallback_reason": fallback_reason,
                }
            )

            if plan.response is not None:
                chat_response = plan.response
                accumulated = buddy_chat_service.assistant_text_from_answer(
                    chat_response.answer
                )
                if accumulated:
                    yield _stream_event({"type": "delta", "delta": accumulated})
            else:
                async for delta in buddy_chat_service.stream_reply_text(
                    request=chat_request,
                    plan=plan,
                    history=history,
                ):
                    accumulated += delta
                    yield _stream_event({"type": "delta", "delta": delta})
                if not accumulated.strip():
                    fallback_result = await buddy_chat_service.generate(
                        request=chat_request,
                        retriever=retriever,
                        history=history,
                    )
                    backend_used = f"{fallback_result.backend_used}_fallback"
                    fallback_reason = (
                        fallback_result.fallback_reason
                        or "stream_returned_no_text"
                    )
                    chat_response = fallback_result.response
                    accumulated = buddy_chat_service.assistant_text_from_answer(
                        chat_response.answer
                    )
                    if accumulated:
                        yield _stream_event({"type": "delta", "delta": accumulated})
                    else:
                        raise ValueError("No assistant text was returned from Buddy.")
                else:
                    chat_response = ChatResponse(
                        answer=buddy_chat_service.text_reply_to_answer(
                            condition=plan.condition,
                            perspective=chat_request.audience,
                            query=chat_request.message,
                            reply_text=accumulated,
                            evidence=plan.evidence
                            if plan.strategy == "openai_grounded"
                            else [],
                        ),
                        retrieved=plan.evidence
                        if plan.strategy == "openai_grounded"
                        else [],
                    )

            safety = assess_safety(request.body)
            safety_labels = []
            if safety.emergency_indicators:
                safety_labels.append("emergency")
            if safety.diagnostic_request:
                safety_labels.append("diagnostic_request")

            assistant_message_row = await repository.create_chat_message(
                chat_session_id=session_id,
                sender_type="assistant",
                message_type="assistant_answer",
                body=accumulated.strip(),
                structured_payload_json=json.dumps(
                    {
                        "answer": chat_response.answer.model_dump(mode="json"),
                        "generation": {
                            "backend_used": backend_used,
                            "fallback_reason": fallback_reason,
                        },
                    }
                ),
                safety_labels_json=json.dumps(safety_labels),
            )

            if chat_response.retrieved:
                await repository.add_chat_answer_citations(
                    chat_message_id=assistant_message_row["id"],
                    citations=[
                        {
                            "resource_id": result.document_id,
                            "chunk_id": result.chunk_id,
                            "citation_label": (
                                result.citations[0].title
                                if result.citations
                                else "Retrieved evidence"
                            ),
                            "confidence": result.confidence,
                        }
                        for result in chat_response.retrieved
                    ],
                )

            safety_disposition = None
            if safety.emergency_indicators and actor.student_profile_id is not None:
                signal = await repository.create_monitoring_signal(
                    student_profile_id=actor.student_profile_id,
                    signal_type="chatbot_risk_phrase",
                    severity="emergency",
                    title="Emergency language detected in chat",
                    signal_summary="Student chat message contained emergency self-harm or harm indicators.",
                    derived_facts_json=json.dumps(
                        {
                            "message_id": str(user_message_row["id"]),
                            "session_id": str(session_id),
                        }
                    ),
                )
                await repository.attach_signal_source(
                    monitoring_signal_id=signal["id"],
                    source_type="chat_message",
                    source_record_id=user_message_row["id"],
                    contribution_weight=1.0,
                    summary="Emergency terms detected in student chat message",
                )
                await repository.create_escalation_case(
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

            await repository.touch_chat_session(
                chat_session_id=session_id,
                safety_disposition=safety_disposition,
            )
            await session.commit()

            yield _stream_event(
                {
                    "type": "complete",
                    "assistant_message": MobileChatMessage.model_validate(
                        assistant_message_row
                    ).model_dump(mode="json"),
                    "backend_used": backend_used,
                    "fallback_reason": fallback_reason,
                    "retrieved": [
                        result.model_dump(mode="json")
                        for result in chat_response.retrieved
                    ],
                }
            )
        except Exception as error:
            await session.rollback()
            yield _stream_event({"type": "error", "message": str(error)})

    return StreamingResponse(
        event_stream(),
        media_type="application/x-ndjson",
        headers={"Cache-Control": "no-cache"},
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
        student_summary = await MobileAppRepository(session).get_latest_student_weekly_summary(
            student_profile_id=student_profile_id
        )
        if student_summary is None:
            raise HTTPException(status_code=404, detail="Parent weekly summary not found")
        row = {
            "id": student_summary["id"],
            "student_profile_id": student_summary["student_profile_id"],
            "guardian_id": actor.guardian_id,
            "week_start": student_summary["week_start"],
            "week_end": student_summary["week_end"],
            "consent_status": "granted",
            "visible_tiers": access["visible_tiers"],
            "summary": _build_parent_safe_summary(
                student_summary.get("summary") or {},
                visible_tiers=access["visible_tiers"],
            ),
            "generated_at": student_summary["generated_at"],
        }
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
    school_id, unrestricted = _counselor_scope(actor)
    queue = await MobileAppRepository(session).list_counselor_queue(
        limit=max(1, min(limit, 50)),
        school_id=school_id,
        unrestricted=unrestricted,
    )
    return CounselorQueueResponse.model_validate(queue)


@router.get("/mobile/counselor/dashboard/latest", response_model=CounselorDashboardMetricResponse)
async def mobile_counselor_dashboard_latest(
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> CounselorDashboardMetricResponse:
    school_id, unrestricted = _counselor_scope(actor)
    repository = MobileAppRepository(session)
    row = None
    if not unrestricted and school_id is not None:
        row = await repository.get_latest_baha_dashboard_metric(
            metric_scope="school",
            scope_key=str(school_id),
        )
    if row is None:
        row = await repository.get_latest_baha_dashboard_metric(
            metric_scope="global",
            scope_key="all",
        )
    if row is None:
        raise HTTPException(status_code=404, detail="Counselor dashboard metrics not found")
    return CounselorDashboardMetricResponse.model_validate(row)


@router.get("/mobile/counselor/cases/{case_id}", response_model=CounselorCaseDetailResponse)
async def mobile_counselor_case_detail(
    case_id: UUID,
    actor: ActorContext = Depends(get_actor_context),
    session: AsyncSession = Depends(get_session),
) -> CounselorCaseDetailResponse:
    school_id, unrestricted = _counselor_scope(actor)
    detail = await MobileAppRepository(session).get_counselor_case_detail(
        case_id=case_id,
        school_id=school_id,
        unrestricted=unrestricted,
    )
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
    school_id, unrestricted = _counselor_scope(actor)
    existing = await MobileAppRepository(session).get_counselor_case_detail(
        case_id=case_id,
        school_id=school_id,
        unrestricted=unrestricted,
    )
    if existing is None:
        raise HTTPException(status_code=404, detail="Case not found")
    if existing["case"]["status"] in {"resolved", "closed", "cancelled"}:
        raise HTTPException(status_code=409, detail="Notes cannot be added to a closed or resolved case")
    note = await MobileAppRepository(session).add_case_note(
        case_id=case_id,
        author_user_id=actor.user_id,
        note_type=request.note_type,
        visibility_scope=request.visibility_scope,
        body=request.body,
    )
    await session.commit()
    detail = await MobileAppRepository(session).get_counselor_case_detail(
        case_id=case_id,
        school_id=school_id,
        unrestricted=unrestricted,
    )
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
    ingestion_module = _optional_dependency("baha_rag.ingestion.pipeline", feature="URL ingestion")
    IngestionPipeline = ingestion_module.IngestionPipeline
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
    acquisition_module = _optional_dependency("baha_rag.acquisition.service", feature="Acquisition workflows")
    AcquisitionService = acquisition_module.AcquisitionService
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
    acquisition_module = _optional_dependency("baha_rag.acquisition.service", feature="Acquisition workflows")
    AcquisitionService = acquisition_module.AcquisitionService
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
    acquisition_module = _optional_dependency("baha_rag.acquisition.service", feature="Acquisition workflows")
    AcquisitionService = acquisition_module.AcquisitionService
    service = AcquisitionService(session, settings)
    result = await service.download_due_candidates(limit=request.limit)
    await session.commit()
    return AcquisitionJobResponse(status="ok", detail=result)


@router.get("/admin/acquisition/inventory")
async def acquisition_inventory(
    session: AsyncSession = Depends(get_session),
    settings: Settings = Depends(get_settings),
) -> dict:
    acquisition_module = _optional_dependency("baha_rag.acquisition.service", feature="Acquisition workflows")
    AcquisitionService = acquisition_module.AcquisitionService
    service = AcquisitionService(session, settings)
    return await service.inventory_dashboard()


@router.get("/admin/acquisition/report")
async def acquisition_report(
    session: AsyncSession = Depends(get_session),
    settings: Settings = Depends(get_settings),
) -> dict:
    acquisition_module = _optional_dependency("baha_rag.acquisition.service", feature="Acquisition workflows")
    AcquisitionService = acquisition_module.AcquisitionService
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
    manual_ingestion_module = _optional_dependency(
        "baha_rag.acquisition.manual_ingestion",
        feature="Manual acquisition ingestion",
    )
    ManualResourceIngestionService = manual_ingestion_module.ManualResourceIngestionService
    ManualResourceMetadata = manual_ingestion_module.ManualResourceMetadata
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
    acquisition_module = _optional_dependency("baha_rag.acquisition.service", feature="Acquisition workflows")
    AcquisitionService = acquisition_module.AcquisitionService
    return await AcquisitionService(session, settings).priority_dashboard()


@router.post("/admin/acquisition/gap-closure", response_model=AcquisitionJobResponse)
async def plan_priority_gap_closure(
    max_topics: int = 9,
    session: AsyncSession = Depends(get_session),
) -> AcquisitionJobResponse:
    gap_module = _optional_dependency("baha_rag.acquisition.gap_closure", feature="Priority gap-closure planning")
    PriorityGapClosureEngine = gap_module.PriorityGapClosureEngine
    result = await PriorityGapClosureEngine(session).plan(max_topics=max(1, min(max_topics, 9)))
    await session.commit()
    return AcquisitionJobResponse(status="ok", detail=result)


@router.get("/admin/acquisition/weekly-gap-report")
async def weekly_priority_gap_report(
    session: AsyncSession = Depends(get_session),
) -> dict:
    gap_module = _optional_dependency("baha_rag.acquisition.gap_closure", feature="Priority gap-closure planning")
    PriorityGapClosureEngine = gap_module.PriorityGapClosureEngine
    result = await PriorityGapClosureEngine(session).weekly_report()
    await session.commit()
    return result


@router.get("/admin/acquisition/priority-campaign-report")
async def aha_nimhans_campaign_report(
    session: AsyncSession = Depends(get_session),
) -> dict:
    campaign_module = _optional_dependency("baha_rag.acquisition.campaign", feature="Priority campaign reporting")
    PriorityCampaignService = campaign_module.PriorityCampaignService
    return await PriorityCampaignService(session).report()


@router.get("/admin/acquisition/review-queue")
async def review_queue(session: AsyncSession = Depends(get_session), limit: int = 100) -> list[dict]:
    review_module = _optional_dependency("baha_rag.acquisition.review_queue", feature="Clinical review queue")
    ClinicalReviewQueueService = review_module.ClinicalReviewQueueService
    return await ClinicalReviewQueueService(session).list_pending(limit=limit)


@router.post("/admin/acquisition/review-queue/{review_id}")
async def decide_review_item(
    review_id: UUID,
    request: ReviewDecisionRequest,
    session: AsyncSession = Depends(get_session),
) -> dict[str, str]:
    review_module = _optional_dependency("baha_rag.acquisition.review_queue", feature="Clinical review queue")
    ClinicalReviewQueueService = review_module.ClinicalReviewQueueService
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
