from __future__ import annotations

from typing import Any
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


class ClinicalReviewQueueService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def list_pending(self, limit: int = 100) -> list[dict[str, Any]]:
        result = await self.session.execute(
            text(
                """
                select
                  q.id,
                  q.status,
                  q.priority,
                  q.reason,
                  r.title,
                  r.organization,
                  r.url,
                  r.topic,
                  r.subtopic,
                  r.storage_uri,
                  q.created_at
                from clinical_review_queue q
                join acquired_resources r on r.id = q.resource_id
                where q.status in ('pending', 'needs_re_review')
                order by q.priority desc, q.created_at asc
                limit :limit
                """
            ),
            {"limit": limit},
        )
        return [dict(row._mapping) for row in result.fetchall()]

    async def decide(self, review_id: UUID, *, status: str, reviewer: str, notes: str | None) -> None:
        if status not in {"approved", "rejected", "needs_changes"}:
            raise ValueError("Review status must be approved, rejected, or needs_changes")
        await self.session.execute(
            text(
                """
                update clinical_review_queue
                set status = :status,
                    reviewer = :reviewer,
                    notes = :notes,
                    reviewed_at = now(),
                    updated_at = now()
                where id = :id
                """
            ),
            {"id": review_id, "status": status, "reviewer": reviewer, "notes": notes},
        )
