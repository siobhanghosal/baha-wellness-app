from __future__ import annotations

from dataclasses import dataclass
from typing import Any
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


@dataclass(slots=True)
class ParentSummaryAccessDecision:
    allowed: bool
    mode: str
    visible_tiers: list[str]
    reason: str | None = None


class PrivacyService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get_parent_summary_access(
        self,
        *,
        guardian_id: UUID,
        student_profile_id: UUID,
    ) -> ParentSummaryAccessDecision:
        link_row = (
            await self.session.execute(
                text(
                    """
                    select consent_authority
                    from student_guardian_links
                    where student_profile_id = :student_profile_id
                      and guardian_id = :guardian_id
                      and status = 'active'
                    limit 1
                    """
                ),
                {"student_profile_id": student_profile_id, "guardian_id": guardian_id},
            )
        ).mappings().first()
        if link_row is None:
            return ParentSummaryAccessDecision(False, "none", [], "No active guardian link")

        override_row = (
            await self.session.execute(
                text(
                    """
                    select id
                    from escalation_cases
                    where student_profile_id = :student_profile_id
                      and privacy_override_active = true
                      and status in ('open', 'triaged', 'assigned', 'in_progress', 'awaiting_external')
                    order by opened_at desc
                    limit 1
                    """
                ),
                {"student_profile_id": student_profile_id},
            )
        ).mappings().first()
        if override_row is not None:
            return ParentSummaryAccessDecision(
                True,
                "override_only",
                ["tier1", "tier2", "tier3", "safeguarding_only"],
                None,
            )

        consent_row = (
            await self.session.execute(
                text(
                    """
                    select cr.status
                    from consent_records cr
                    where cr.student_profile_id = :student_profile_id
                      and cr.guardian_id = :guardian_id
                      and cr.consent_type = 'parent_summary_sharing'
                    order by coalesce(cr.granted_at, cr.created_at) desc
                    limit 1
                    """
                ),
                {"student_profile_id": student_profile_id, "guardian_id": guardian_id},
            )
        ).mappings().first()
        if consent_row is None or consent_row["status"] != "granted":
            return ParentSummaryAccessDecision(False, "none", [], "Parent summary consent is not granted")

        tiers_row = (
            await self.session.execute(
                text(
                    """
                    select tier_1_enabled, tier_2_enabled, tier_3_enabled
                    from privacy_tier_settings
                    where student_profile_id = :student_profile_id
                      and status = 'active'
                    order by effective_from desc, created_at desc
                    limit 1
                    """
                ),
                {"student_profile_id": student_profile_id},
            )
        ).mappings().first()
        visible_tiers: list[str] = []
        if tiers_row is None:
            visible_tiers = ["tier1"]
        else:
            if tiers_row["tier_1_enabled"]:
                visible_tiers.append("tier1")
            if tiers_row["tier_2_enabled"]:
                visible_tiers.append("tier2")
            if tiers_row["tier_3_enabled"]:
                visible_tiers.append("tier3")

        if not visible_tiers:
            return ParentSummaryAccessDecision(False, "none", [], "No privacy tiers are enabled for guardian summaries")

        return ParentSummaryAccessDecision(True, "approved", visible_tiers, None)

    async def get_active_privacy_tiers(self, *, student_profile_id: UUID) -> list[str]:
        row = (
            await self.session.execute(
                text(
                    """
                    select tier_1_enabled, tier_2_enabled, tier_3_enabled
                    from privacy_tier_settings
                    where student_profile_id = :student_profile_id
                      and status = 'active'
                    order by effective_from desc, created_at desc
                    limit 1
                    """
                ),
                {"student_profile_id": student_profile_id},
            )
        ).mappings().first()
        if row is None:
            return ["tier1"]
        tiers: list[str] = []
        if row["tier_1_enabled"]:
            tiers.append("tier1")
        if row["tier_2_enabled"]:
            tiers.append("tier2")
        if row["tier_3_enabled"]:
            tiers.append("tier3")
        return tiers or ["tier1"]

    async def summarize_parent_access(self, *, guardian_id: UUID, student_profile_id: UUID) -> dict[str, Any]:
        decision = await self.get_parent_summary_access(
            guardian_id=guardian_id,
            student_profile_id=student_profile_id,
        )
        return {
            "allowed": decision.allowed,
            "mode": decision.mode,
            "visible_tiers": decision.visible_tiers,
            "reason": decision.reason,
        }
