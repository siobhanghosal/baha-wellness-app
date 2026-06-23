from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Any

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from baha_rag.acquisition.repository import AcquisitionRepository

LIFE_SKILLS_ORGANIZATIONS = (
    "CASEL",
    "Common Sense Media",
    "Internet Matters",
    "eSafety Commissioner",
    "Attendance Works",
    "Education Endowment Foundation",
    "National Center for School Mental Health",
    "American School Counselor Association",
    "National Association of School Psychologists",
    "OECD",
    "World Economic Forum",
    "SCERT Karnataka",
    "National Institute of Open Schooling",
)

LIFE_SKILLS_TOPICS = (
    "digital wellness",
    "bullying",
    "cyberbullying",
    "screen time",
    "school refusal",
    "school avoidance",
    "communication skills",
    "decision making",
    "emotional intelligence",
    "problem solving",
    "resilience",
    "self awareness",
    "peer pressure",
    "risk taking",
    "performance anxiety",
)

LIFE_SKILLS_TARGETS = {
    "digital wellness": 200,
    "bullying": 200,
    "cyberbullying": 150,
    "screen time": 75,
    "school refusal": 75,
    "school avoidance": 75,
    "communication skills": 50,
    "decision making": 50,
    "emotional intelligence": 50,
    "problem solving": 50,
    "resilience": 50,
    "self awareness": 50,
    "peer pressure": 75,
    "risk taking": 75,
    "performance anxiety": 75,
}

GENERIC_DISCOVERY_TERMS = (
    "resource",
    "publication",
    "research",
    "toolkit",
    "guide",
    "curriculum",
    "framework",
    "lesson",
    "classroom",
    "family",
    "parent",
    "teacher",
    "student",
    "school",
)

SOURCE_TARGET_TERMS: dict[str, tuple[str, ...]] = {
    "CASEL": (
        "social emotional learning",
        "social-emotional learning",
        "sel",
        "self awareness",
        "self management",
        "social awareness",
        "relationship skills",
        "responsible decision making",
        "schoolwide sel",
        "family sel",
    ),
    "Common Sense Media": (
        "digital citizenship",
        "digital wellness",
        "media balance",
        "screen time",
        "online safety",
        "social media",
        "cyberbullying",
        "gaming",
        "digital literacy",
    ),
    "Internet Matters": (
        "screen time",
        "online safety",
        "cyberbullying",
        "social media",
        "gaming",
        "digital wellbeing",
    ),
    "eSafety Commissioner": (
        "online safety",
        "cyberbullying",
        "screen time",
        "digital wellbeing",
        "young people",
        "educators",
        "parents",
    ),
    "Attendance Works": (
        "attendance",
        "chronic absence",
        "chronic absenteeism",
        "school avoidance",
        "student engagement",
    ),
    "Education Endowment Foundation": (
        "social emotional learning",
        "attendance",
        "bullying",
        "behaviour",
        "metacognition",
        "self regulation",
        "student engagement",
    ),
    "National Center for School Mental Health": (
        "school mental health",
        "teacher intervention",
        "referral",
        "school support",
        "student support",
    ),
    "American School Counselor Association": (
        "school counseling",
        "student standards",
        "student support",
        "mindsets and behaviors",
        "counseling framework",
    ),
    "National Association of School Psychologists": (
        "bullying",
        "school psychology",
        "behavior management",
        "school intervention",
        "resilience",
        "school refusal",
    ),
    "OECD": (
        "social and emotional skills",
        "student wellbeing",
        "resilience",
        "problem solving",
        "emotional regulation",
        "digital wellbeing",
    ),
    "World Economic Forum": (
        "life skills",
        "future skills",
        "resilience",
        "problem solving",
        "emotional intelligence",
        "digital wellbeing",
    ),
    "SCERT Karnataka": (
        "life skills",
        "guidance",
        "counselling",
        "student wellbeing",
        "teacher training",
        "school health",
    ),
    "National Institute of Open Schooling": (
        "life skills",
        "psychology",
        "adolescent",
        "self development",
        "communication",
        "decision making",
    ),
}


def is_life_skills_relevant(text_value: str, organization: str) -> bool:
    lowered = text_value.lower()
    terms = SOURCE_TARGET_TERMS.get(organization, ()) + GENERIC_DISCOVERY_TERMS
    return any(term in lowered for term in terms)


class LifeSkillsCampaignReporter:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def report(self) -> dict[str, Any]:
        await AcquisitionRepository(self.session).refresh_topic_coverage()
        organizations = list(LIFE_SKILLS_ORGANIZATIONS)
        topics = list(LIFE_SKILLS_TOPICS)
        totals = await self.session.execute(
            text(
                """
                select
                  organization,
                  count(*) filter (where quality_status = 'accepted') as accepted,
                  count(*) filter (where quality_status = 'rejected') as rejected,
                  count(*) filter (
                    where quality_status = 'accepted' and resource_type = 'pdf'
                  ) as pdfs,
                  count(*) filter (
                    where quality_status = 'accepted' and resource_type = 'html'
                  ) as html
                from acquired_resources
                where organization = any(cast(:organizations as text[]))
                group by organization
                order by accepted desc, organization
                """
            ),
            {"organizations": organizations},
        )
        coverage = await self.session.execute(
            text(
                """
                select
                  t.topic,
                  coalesce(c.document_count, 0) as current_count,
                  t.minimum_documents as target_count,
                  greatest(t.minimum_documents - coalesce(c.document_count, 0), 0)
                    as gap_count,
                  round(
                    greatest(t.minimum_documents - coalesce(c.document_count, 0), 0)
                    * 100.0 / t.minimum_documents,
                    2
                  ) as gap_percent,
                  coalesce(c.document_count, 0) >= ceil(t.minimum_documents * 0.9)
                    as below_ten_percent_gap
                from topic_targets t
                left join topic_coverage c using (topic)
                where t.topic = any(cast(:topics as text[]))
                order by gap_count desc, t.topic
                """
            ),
            {"topics": topics},
        )
        audience = await self.session.execute(
            text(
                """
                select organization, coalesce(audience, 'general') as audience, count(*) as resources
                from acquired_resources
                where organization = any(cast(:organizations as text[]))
                  and quality_status = 'accepted'
                group by organization, coalesce(audience, 'general')
                order by organization, audience
                """
            ),
            {"organizations": organizations},
        )
        candidates = await self.session.execute(
            text(
                """
                select organization, status, count(*) as count
                from acquisition_candidates
                where organization = any(cast(:organizations as text[]))
                group by organization, status
                order by organization, status
                """
            ),
            {"organizations": organizations},
        )
        graph = await self.session.execute(
            text(
                """
                select
                  count(*) filter (where node_type = 'Skill') as skill_nodes,
                  count(*) filter (
                    where node_type in (
                      'Skill Intervention', 'Parent Support',
                      'Teacher Support', 'School Support'
                    )
                  ) as support_nodes
                from knowledge_graph_nodes
                """
            )
        )
        graph_edges = await self.session.execute(
            text(
                """
                select relationship, count(*) as count
                from knowledge_graph_edges
                where relationship in (
                  'HAS_SKILL_INTERVENTION', 'HAS_PARENT_SUPPORT',
                  'HAS_TEACHER_SUPPORT', 'HAS_SCHOOL_SUPPORT'
                )
                group by relationship
                order by relationship
                """
            )
        )
        coverage_rows = [dict(row._mapping) for row in coverage.fetchall()]
        report = {
            "organizations": [dict(row._mapping) for row in totals.fetchall()],
            "audience_coverage": [dict(row._mapping) for row in audience.fetchall()],
            "candidate_status": [dict(row._mapping) for row in candidates.fetchall()],
            "topic_coverage": coverage_rows,
            "remaining_above_ten_percent": [
                row for row in coverage_rows if not row["below_ten_percent_gap"]
            ],
            "all_gaps_below_ten_percent": all(
                row["below_ten_percent_gap"] for row in coverage_rows
            ),
            "knowledge_graph": {
                **dict(graph.one()._mapping),
                "edges": [dict(row._mapping) for row in graph_edges.fetchall()],
            },
            "embedding_status": "deferred",
            "generated_at": datetime.now(timezone.utc).isoformat(),
        }
        await self.session.execute(
            text(
                """
                insert into life_skills_campaign_reports (report_date, report)
                values (current_date, cast(:report as jsonb))
                on conflict (report_date) do update set
                  report = excluded.report,
                  created_at = now()
                """
            ),
            {"report": json.dumps(report, default=str)},
        )
        return report
