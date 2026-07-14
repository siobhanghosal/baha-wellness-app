from __future__ import annotations

import shutil
import tempfile
from datetime import date
from pathlib import Path
from uuid import UUID, uuid4

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from baha_rag.acquisition.gap_closure import PriorityGapClosureEngine
from baha_rag.acquisition.campaign import PriorityCampaignService
from baha_rag.acquisition.manual_ingestion import (
    ManualResourceIngestionService,
    ManualResourceMetadata,
)
from baha_rag.acquisition.review_queue import ClinicalReviewQueueService
from baha_rag.acquisition.service import AcquisitionService
from baha_rag.config import Settings, get_settings
from baha_rag.dashboard.metrics import DashboardService
from baha_rag.db.repository import KnowledgeRepository
from baha_rag.db.session import get_session
from baha_rag.embeddings.bge import EmbeddingService
from baha_rag.extraction.condition_profile import ConditionProfileExtractor
from baha_rag.generation.composer import EvidenceComposer
from baha_rag.generation.openai_chat import OpenAIChatService
from baha_rag.ingestion.pipeline import IngestionPipeline
from baha_rag.retrieval.hybrid import HybridRetriever
from baha_rag.schemas import (
    AcquisitionDiscoverRequest,
    AcquisitionDownloadRequest,
    AcquisitionJobResponse,
    ChatRequest,
    ChatResponse,
    ConditionSummary,
    IngestResponse,
    IngestUrlRequest,
    SearchRequest,
    SearchResponse,
    ReviewDecisionRequest,
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


def get_chat_service(settings: Settings = Depends(get_settings)) -> OpenAIChatService:
    return OpenAIChatService(settings)


@router.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


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
    chat_service: OpenAIChatService = Depends(get_chat_service),
) -> ChatResponse:
    results = await retriever.search(request.message, top_k=request.top_k, filters=request.filters)
    condition = next(iter(find_conditions(request.message)), "General Wellbeing")
    try:
        answer = await chat_service.generate(
            query=request.message,
            perspective=request.audience,
            condition=condition,
            evidence=results,
            history=request.history,
        )
    except ValueError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc
    return ChatResponse(answer=answer, retrieved=results)


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
