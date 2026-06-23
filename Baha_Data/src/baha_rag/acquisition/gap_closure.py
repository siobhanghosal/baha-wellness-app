from __future__ import annotations

from datetime import date, timedelta
from typing import Any

from sqlalchemy.ext.asyncio import AsyncSession

from baha_rag.acquisition.coverage import GapQueryGenerator
from baha_rag.acquisition.priority_sources import PrioritySourceRegistry
from baha_rag.acquisition.repository import AcquisitionRepository


PRIORITY_GAP_TOPICS = (
    "depression",
    "anxiety",
    "stress",
    "sleep",
    "bullying",
    "cyberbullying",
    "digital wellness",
    "self harm",
    "suicide prevention",
)


class PriorityGapClosureEngine:
    def __init__(self, session: AsyncSession) -> None:
        self.repository = AcquisitionRepository(session)
        self.sources = PrioritySourceRegistry()
        self.query_generator = GapQueryGenerator()

    async def plan(self, *, max_topics: int = 9) -> dict[str, Any]:
        deficits = await self.repository.priority_topic_gaps(PRIORITY_GAP_TOPICS)
        selected = deficits[:max_topics]
        run_key = date.today().isoformat()
        planned = 0
        searches: list[dict[str, Any]] = []
        for deficit in selected:
            topic = deficit["topic"]
            for source in self.sources.all():
                for query in self.query_generator.generate(topic):
                    site_query = self.sources.site_query(source, query)
                    await self.repository.upsert_priority_gap_search(
                        topic=topic,
                        organization=source.organization,
                        priority_rank=source.priority_rank,
                        query=site_query,
                        search_url=source.search_url(query),
                        run_key=run_key,
                    )
                    planned += 1
                    searches.append(
                        {
                            "topic": topic,
                            "organization": source.organization,
                            "priority_rank": source.priority_rank,
                            "query": site_query,
                            "search_url": source.search_url(query),
                        }
                    )
        return {
            "run_key": run_key,
            "targets_met": not selected,
            "deficits": selected,
            "searches_planned": planned,
            "searches_preview": searches[:30],
            "searches_truncated": max(len(searches) - 30, 0),
        }

    async def weekly_report(self) -> dict[str, Any]:
        today = date.today()
        week_start = today - timedelta(days=today.weekday())
        dashboard = await self.repository.priority_coverage_dashboard()
        deficits = await self.repository.priority_topic_gaps(PRIORITY_GAP_TOPICS)
        report = {
            "week_start": week_start.isoformat(),
            "priority_order": [
                {"organization": source.organization, "priority_rank": source.priority_rank}
                for source in self.sources.all()
            ],
            "coverage": dashboard,
            "deficits": deficits,
            "all_targets_met": not deficits,
        }
        await self.repository.persist_weekly_priority_report(week_start, report)
        return report
