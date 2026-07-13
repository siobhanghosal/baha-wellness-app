from __future__ import annotations

from typing import Annotated
from pathlib import Path

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from baha_companion.authentication.notifications import AuthenticationNotificationService
from baha_companion.authentication.repository import AuthenticationRepository
from baha_companion.authentication.service import AuthenticationService
from baha_companion.chat.repository import ChatRepository
from baha_companion.chat.service import ChatService
from baha_companion.config import AppSettings, get_settings
from baha_companion.database.session import get_session
from baha_companion.embeddings.config import EmbeddingSettings, get_embedding_settings
from baha_companion.embeddings.repository import EmbeddingRepository
from baha_companion.embeddings.service import EmbeddingService
from baha_companion.llm.client import OpenAIChatClient
from baha_companion.llm.config import LLMSettings, get_llm_settings
from baha_companion.llm.context_composer import ContextComposer
from baha_companion.llm.cost_tracker import CostTracker
from baha_companion.llm.prompt_builder import PromptBuilder
from baha_companion.llm.response_validator import ResponseValidator
from baha_companion.llm.service import LLMService
from baha_companion.llm.streaming import get_stream_manager
from baha_companion.llm.token_counter import TokenCounter
from baha_companion.knowledge.classifiers import (
    AudienceClassifier,
    AgeClassifier,
    DemographicClassifier,
    EvidenceClassifier,
    PriorityAssigner,
    ReadingLevelClassifier,
    TopicClassifier,
)
from baha_companion.knowledge.duplicates import DuplicateDetectionService
from baha_companion.knowledge.normalization import KnowledgeNormalizationService
from baha_companion.knowledge.quality import QualityService
from baha_companion.knowledge.repository import KnowledgeRepository
from baha_companion.knowledge.segmentation import DocumentSegmentationService
from baha_companion.knowledge.service import KnowledgeProcessingService
from baha_companion.retrieval.config import RetrievalSettings, get_retrieval_settings
from baha_companion.retrieval.repository import RetrievalRepository
from baha_companion.retrieval.service import RetrievalService
from baha_companion.users.repository import UserRepository
from baha_companion.users.service import UserService


def get_auth_repository(session: Annotated[AsyncSession, Depends(get_session)]) -> AuthenticationRepository:
    return AuthenticationRepository(session)


def get_user_repository(session: Annotated[AsyncSession, Depends(get_session)]) -> UserRepository:
    return UserRepository(session)


def get_auth_notification_service() -> AuthenticationNotificationService:
    return AuthenticationNotificationService()


def get_authentication_service(
    settings: Annotated[AppSettings, Depends(get_settings)],
    auth_repository: Annotated[AuthenticationRepository, Depends(get_auth_repository)],
    user_repository: Annotated[UserRepository, Depends(get_user_repository)],
    notifications: Annotated[AuthenticationNotificationService, Depends(get_auth_notification_service)],
) -> AuthenticationService:
    return AuthenticationService(
        settings=settings,
        auth_repository=auth_repository,
        user_repository=user_repository,
        notification_service=notifications,
    )


def get_user_service(
    user_repository: Annotated[UserRepository, Depends(get_user_repository)],
) -> UserService:
    return UserService(user_repository)


def get_chat_service(session: Annotated[AsyncSession, Depends(get_session)]) -> ChatService:
    return ChatService(ChatRepository(session))


def get_knowledge_repository(session: Annotated[AsyncSession, Depends(get_session)]) -> KnowledgeRepository:
    return KnowledgeRepository(session)


def get_embedding_repository(session: Annotated[AsyncSession, Depends(get_session)]) -> EmbeddingRepository:
    return EmbeddingRepository(session)


def get_retrieval_repository(session: Annotated[AsyncSession, Depends(get_session)]) -> RetrievalRepository:
    return RetrievalRepository(session)


def get_knowledge_processing_service(
    repository: Annotated[KnowledgeRepository, Depends(get_knowledge_repository)],
) -> KnowledgeProcessingService:
    return KnowledgeProcessingService(
        repository,
        workspace_root=Path.cwd(),
        normalization_service=KnowledgeNormalizationService(),
        segmentation_service=DocumentSegmentationService(),
        topic_classifier=TopicClassifier(),
        audience_classifier=AudienceClassifier(),
        age_classifier=AgeClassifier(),
        evidence_classifier=EvidenceClassifier(),
        demographic_classifier=DemographicClassifier(),
        priority_assigner=PriorityAssigner(),
        reading_level_classifier=ReadingLevelClassifier(),
        quality_service=QualityService(),
        duplicate_detection_service=DuplicateDetectionService(),
    )


def get_embedding_service(
    repository: Annotated[EmbeddingRepository, Depends(get_embedding_repository)],
    settings: Annotated[EmbeddingSettings, Depends(get_embedding_settings)],
) -> EmbeddingService:
    return EmbeddingService(repository, settings=settings)


def get_retrieval_service(
    repository: Annotated[RetrievalRepository, Depends(get_retrieval_repository)],
    retrieval_settings: Annotated[RetrievalSettings, Depends(get_retrieval_settings)],
    embedding_settings: Annotated[EmbeddingSettings, Depends(get_embedding_settings)],
) -> RetrievalService:
    return RetrievalService(
        repository,
        retrieval_settings=retrieval_settings,
        embedding_settings=embedding_settings,
    )


def get_llm_client(
    settings: Annotated[LLMSettings, Depends(get_llm_settings)],
) -> OpenAIChatClient:
    return OpenAIChatClient(settings=settings)


def get_llm_service(
    chat_service: Annotated[ChatService, Depends(get_chat_service)],
    retrieval_service: Annotated[RetrievalService, Depends(get_retrieval_service)],
    llm_settings: Annotated[LLMSettings, Depends(get_llm_settings)],
    client: Annotated[OpenAIChatClient, Depends(get_llm_client)],
) -> LLMService:
    token_counter = TokenCounter()
    return LLMService(
        chat_service=chat_service,
        retrieval_service=retrieval_service,
        settings=llm_settings,
        client=client,
        context_composer=ContextComposer(llm_settings, token_counter=token_counter),
        prompt_builder=PromptBuilder(),
        response_validator=ResponseValidator(),
        token_counter=token_counter,
        cost_tracker=CostTracker(),
        stream_manager=get_stream_manager(),
    )
