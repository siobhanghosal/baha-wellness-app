from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends

from baha_companion.api.dependencies import get_retrieval_service
from baha_companion.authentication.dependencies import get_current_user
from baha_companion.retrieval.models import BenchmarkCase, RetrievalFilters
from baha_companion.retrieval.schemas import (
    BenchmarkRequest,
    BenchmarkResponse,
    RetrieveAudienceRequest,
    RetrieveDebugResponse,
    RetrieveOrganisationRequest,
    RetrieveRequest,
    RetrieveResponse,
    RetrieveTopicRequest,
    RetrievalStatisticsResponse,
)
from baha_companion.retrieval.service import RetrievalService
from baha_companion.users.models import User

router = APIRouter(prefix="/retrieve", tags=["Retrieval"])


@router.post("", response_model=RetrieveResponse)
async def retrieve(
    request: RetrieveRequest,
    _current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[RetrievalService, Depends(get_retrieval_service)],
) -> RetrieveResponse:
    payload = await service.retrieve(
        query=request.query,
        filters=RetrievalFilters(**request.filters.model_dump()),
        top_k=request.top_k,
    )
    return RetrieveResponse(
        query=payload["query"],
        understanding=payload["understanding"],
        filters=payload["filters"],
        items=payload["items"],
        top_k=payload["top_k"],
    )


@router.post("/debug", response_model=RetrieveDebugResponse)
async def retrieve_debug(
    request: RetrieveRequest,
    _current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[RetrievalService, Depends(get_retrieval_service)],
) -> RetrieveDebugResponse:
    payload = await service.retrieve(
        query=request.query,
        filters=RetrievalFilters(**request.filters.model_dump()),
        top_k=request.top_k,
        debug=True,
    )
    return RetrieveDebugResponse(
        query=payload["query"],
        understanding=payload["understanding"],
        filters=payload["filters"],
        items=payload["items"],
        top_k=payload["top_k"],
        bm25_results=payload["bm25_results"],
        vector_results=payload["vector_results"],
        merged_results=payload["merged_results"],
        reranker_results=payload["reranker_results"],
        timing=payload["timing"],
    )


@router.post("/topic", response_model=RetrieveResponse)
async def retrieve_topic(
    request: RetrieveTopicRequest,
    _current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[RetrievalService, Depends(get_retrieval_service)],
) -> RetrieveResponse:
    payload = await service.retrieve_by_topic(topic=request.topic, query=request.query, top_k=request.top_k)
    return RetrieveResponse(
        query=payload["query"],
        understanding=payload["understanding"],
        filters=payload["filters"],
        items=payload["items"],
        top_k=payload["top_k"],
    )


@router.post("/audience", response_model=RetrieveResponse)
async def retrieve_audience(
    request: RetrieveAudienceRequest,
    _current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[RetrievalService, Depends(get_retrieval_service)],
) -> RetrieveResponse:
    payload = await service.retrieve_by_audience(
        audience=request.audience,
        query=request.query,
        top_k=request.top_k,
    )
    return RetrieveResponse(
        query=payload["query"],
        understanding=payload["understanding"],
        filters=payload["filters"],
        items=payload["items"],
        top_k=payload["top_k"],
    )


@router.post("/organisation", response_model=RetrieveResponse)
async def retrieve_organisation(
    request: RetrieveOrganisationRequest,
    _current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[RetrievalService, Depends(get_retrieval_service)],
) -> RetrieveResponse:
    payload = await service.retrieve_by_organisation(
        organisation=request.organisation,
        query=request.query,
        top_k=request.top_k,
    )
    return RetrieveResponse(
        query=payload["query"],
        understanding=payload["understanding"],
        filters=payload["filters"],
        items=payload["items"],
        top_k=payload["top_k"],
    )


@router.get("/statistics", response_model=RetrievalStatisticsResponse)
async def retrieval_statistics(
    _current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[RetrievalService, Depends(get_retrieval_service)],
) -> RetrievalStatisticsResponse:
    return RetrievalStatisticsResponse(**(await service.statistics()))


@router.post("/benchmark", response_model=BenchmarkResponse, include_in_schema=False)
async def retrieval_benchmark(
    request: BenchmarkRequest,
    _current_user: Annotated[User, Depends(get_current_user)],
    service: Annotated[RetrievalService, Depends(get_retrieval_service)],
) -> BenchmarkResponse:
    payload = await service.benchmark(
        cases=[
            BenchmarkCase(
                name=item.name,
                query=item.query,
                expected_ids=item.expected_ids,
                expected_titles=item.expected_titles,
                filters=RetrievalFilters(**item.filters.model_dump()),
                top_k=item.top_k,
            )
            for item in request.cases
        ]
    )
    return BenchmarkResponse(**payload)
