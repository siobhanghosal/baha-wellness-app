from sqlalchemy import event
from sqlalchemy.orm import Session, with_loader_criteria

from baha_companion.common.models import Base, SoftDeleteMixin
from baha_companion.authentication.models import EmailVerificationToken, LoginAttempt, PasswordResetToken, RefreshToken  # noqa: F401
from baha_companion.chat.models import Conversation, Message  # noqa: F401
from baha_companion.embeddings.models import (  # noqa: F401
    EmbeddingJob,
    EmbeddingModel,
    EmbeddingStatistics,
    EmbeddingVersion,
    KnowledgeEmbedding,
)
from baha_companion.knowledge.models import (  # noqa: F401
    KnowledgeActivity,
    KnowledgeCitation,
    KnowledgeFaq,
    KnowledgeKeyword,
    KnowledgeMetadata,
    KnowledgeObject,
    KnowledgeQuality,
    KnowledgeTopic,
)
from baha_companion.users.models import User  # noqa: F401

__all__ = [
    "Base",
    "User",
    "RefreshToken",
    "PasswordResetToken",
    "EmailVerificationToken",
    "LoginAttempt",
    "Conversation",
    "Message",
    "KnowledgeObject",
    "KnowledgeMetadata",
    "KnowledgeTopic",
    "KnowledgeKeyword",
    "KnowledgeCitation",
    "KnowledgeFaq",
    "KnowledgeActivity",
    "KnowledgeQuality",
    "EmbeddingModel",
    "EmbeddingVersion",
    "KnowledgeEmbedding",
    "EmbeddingJob",
    "EmbeddingStatistics",
]


@event.listens_for(Session, "do_orm_execute")
def _filter_soft_deleted_rows(execute_state) -> None:
    if (
        execute_state.is_select
        and not execute_state.is_column_load
        and not execute_state.is_relationship_load
        and not execute_state.execution_options.get("include_deleted", False)
    ):
        execute_state.statement = execute_state.statement.options(
            with_loader_criteria(
                SoftDeleteMixin,
                lambda cls: cls.deleted_at.is_(None),
                include_aliases=True,
            )
        )
