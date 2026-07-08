from __future__ import annotations

import json
import re
from datetime import date, datetime, timezone
from typing import Any
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from baha_rag.acquisition.models import DownloadedResource, ResourceCandidate
from baha_rag.acquisition.source_registry import SourceDefinition


def _json_dumps(value: Any) -> str:
    def sanitize(item: Any) -> Any:
        if isinstance(item, str):
            return re.sub(r"[\x00-\x08\x0b\x0c\x0e-\x1f]", " ", item)
        if isinstance(item, dict):
            return {sanitize(key): sanitize(nested) for key, nested in item.items()}
        if isinstance(item, (list, tuple)):
            return [sanitize(nested) for nested in item]
        return item

    return json.dumps(sanitize(value), default=str)


class AcquisitionRepository:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def seed_source(self, source: SourceDefinition) -> UUID:
        result = await self.session.execute(
            text(
                """
                insert into acquisition_sources (
                  organization, source_type, country, base_domains, seed_urls,
                  rate_limit_seconds, robots_required, active
                )
                values (
                  :organization, :source_type, :country, :base_domains, :seed_urls,
                  :rate_limit_seconds, :robots_required, true
                )
                on conflict (organization) do update set
                  source_type = excluded.source_type,
                  country = excluded.country,
                  base_domains = excluded.base_domains,
                  seed_urls = excluded.seed_urls,
                  rate_limit_seconds = excluded.rate_limit_seconds,
                  robots_required = excluded.robots_required,
                  active = true,
                  updated_at = now()
                returning id
                """
            ),
            {
                "organization": source.organization,
                "source_type": source.kind.value,
                "country": source.country,
                "base_domains": list(source.base_domains),
                "seed_urls": list(source.seed_urls),
                "rate_limit_seconds": source.rate_limit_seconds,
                "robots_required": source.robots_required,
            },
        )
        return result.scalar_one()

    async def upsert_candidate(self, candidate: ResourceCandidate) -> UUID:
        result = await self.session.execute(
            text(
                """
                insert into acquisition_candidates (
                  url, normalized_url, organization, source, title, author,
                  publication_date_raw, country, language, topic, subtopic,
                  resource_type, content_type, discovered_via, metadata, status,
                  discovered_at, updated_at
                )
                values (
                  :url, :normalized_url, :organization, :source, :title, :author,
                  :publication_date_raw, :country, :language, :topic, :subtopic,
                  :resource_type, :content_type, :discovered_via, cast(:metadata as jsonb),
                  'discovered', now(), now()
                )
                on conflict (normalized_url) do update set
                  title = coalesce(excluded.title, acquisition_candidates.title),
                  author = coalesce(excluded.author, acquisition_candidates.author),
                  publication_date_raw = coalesce(
                    excluded.publication_date_raw,
                    acquisition_candidates.publication_date_raw
                  ),
                  topic = coalesce(excluded.topic, acquisition_candidates.topic),
                  subtopic = coalesce(excluded.subtopic, acquisition_candidates.subtopic),
                  content_type = coalesce(excluded.content_type, acquisition_candidates.content_type),
                  metadata = acquisition_candidates.metadata || excluded.metadata,
                  updated_at = now()
                returning id
                """
            ),
            self._candidate_params(candidate),
        )
        return result.scalar_one()

    async def get_due_candidates(
        self,
        limit: int = 100,
        resource_type: str | None = None,
        organization: str | None = None,
    ) -> list[dict[str, Any]]:
        filters = []
        params: dict[str, Any] = {"limit": limit}
        if resource_type:
            filters.append("resource_type = :resource_type")
            params["resource_type"] = resource_type
        if organization:
            filters.append("organization = :organization")
            params["organization"] = organization
        filter_sql = "and " + " and ".join(filters) if filters else ""
        result = await self.session.execute(
            text(
                f"""
                select *
                from acquisition_candidates
                where status in ('discovered', 'updated', 'retry')
                {filter_sql}
                order by coalesce(
                  (select priority_rank from priority_sources p
                   where p.organization = acquisition_candidates.organization),
                  999
                ), discovered_at asc
                limit :limit
                """
            ),
            params,
        )
        return [dict(row._mapping) for row in result.fetchall()]

    async def mark_candidate_status(self, candidate_id: UUID, status: str, error: str | None = None) -> None:
        await self.session.execute(
            text(
                """
                update acquisition_candidates
                set status = :status, error = :error, updated_at = now()
                where id = :id
                """
            ),
            {"id": candidate_id, "status": status, "error": error},
        )

    async def existing_resource_for_url(self, normalized_url: str) -> dict[str, Any] | None:
        result = await self.session.execute(
            text(
                """
                select id, content_hash, etag, last_modified
                from acquired_resources
                where normalized_url = :normalized_url
                """
            ),
            {"normalized_url": normalized_url},
        )
        row = result.first()
        return dict(row._mapping) if row else None

    async def existing_resource_for_hash(self, content_hash: str) -> dict[str, Any] | None:
        result = await self.session.execute(
            text(
                """
                select id, normalized_url
                from acquired_resources
                where content_hash = :content_hash
                order by downloaded_at asc
                limit 1
                """
            ),
            {"content_hash": content_hash},
        )
        row = result.first()
        return dict(row._mapping) if row else None

    async def record_duplicate(
        self,
        *,
        canonical_resource_id: UUID,
        duplicate_resource_id: UUID,
        duplicate_type: str,
        score: float = 1.0,
    ) -> None:
        if canonical_resource_id == duplicate_resource_id:
            return
        await self.session.execute(
            text(
                """
                insert into resource_duplicates (
                  canonical_resource_id, duplicate_resource_id, duplicate_type, score
                )
                values (:canonical_resource_id, :duplicate_resource_id, :duplicate_type, :score)
                on conflict (canonical_resource_id, duplicate_resource_id) do nothing
                """
            ),
            {
                "canonical_resource_id": canonical_resource_id,
                "duplicate_resource_id": duplicate_resource_id,
                "duplicate_type": duplicate_type,
                "score": score,
            },
        )

    async def record_download(self, downloaded: DownloadedResource) -> UUID:
        result = await self.session.execute(
            text(
                """
                insert into acquired_resources (
                  url, normalized_url, organization, source, title, author,
                  publication_date_raw, country, language, topic, subtopic,
                  resource_type, content_type, storage_uri, content_hash,
                  byte_size, etag, last_modified, metadata, downloaded_at, version,
                  priority_rank, source_weight, audience,
                  is_baha_resource, is_iap_resource,
                  is_aha_resource, is_nimhans_resource, priority_score
                )
                values (
                  :url, :normalized_url, :organization, :source, :title, :author,
                  :publication_date_raw, :country, :language, :topic, :subtopic,
                  :resource_type, :content_type, :storage_uri, :content_hash,
                  :byte_size, :etag, :last_modified, cast(:metadata as jsonb),
                  :downloaded_at, 1,
                  (select priority_rank from priority_sources where organization = :organization),
                  coalesce(
                    (select source_weight from priority_sources where organization = :organization),
                    0.700
                  ),
                  coalesce(:audience, 'general'),
                  :organization = 'Bangalore Adolescent Health Academy',
                  :organization in (
                    'Indian Academy of Pediatrics',
                    'IAP Adolescent Health Academy'
                  ),
                  :organization = 'IAP Adolescent Health Academy',
                  :organization = 'NIMHANS',
                  coalesce(
                    (select source_weight from priority_sources where organization = :organization),
                    0.700
                  )
                )
                on conflict (normalized_url) do update set
                  title = coalesce(excluded.title, acquired_resources.title),
                  author = coalesce(excluded.author, acquired_resources.author),
                  publication_date_raw = coalesce(
                    excluded.publication_date_raw,
                    acquired_resources.publication_date_raw
                  ),
                  topic = coalesce(excluded.topic, acquired_resources.topic),
                  subtopic = coalesce(excluded.subtopic, acquired_resources.subtopic),
                  storage_uri = excluded.storage_uri,
                  byte_size = excluded.byte_size,
                  etag = excluded.etag,
                  last_modified = excluded.last_modified,
                  metadata = acquired_resources.metadata || excluded.metadata,
                  source_weight = excluded.source_weight,
                  priority_score = excluded.priority_score,
                  is_aha_resource = excluded.is_aha_resource,
                  is_nimhans_resource = excluded.is_nimhans_resource,
                  audience = case
                    when acquired_resources.audience = 'general' then excluded.audience
                    else acquired_resources.audience
                  end,
                  downloaded_at = excluded.downloaded_at,
                  updated_at = now(),
                  version = case
                    when acquired_resources.content_hash <> excluded.content_hash
                    then acquired_resources.version + 1
                    else acquired_resources.version
                  end,
                  content_hash = excluded.content_hash
                returning id
                """
            ),
            {
                **self._candidate_params(downloaded.candidate),
                "storage_uri": downloaded.storage_uri,
                "content_hash": downloaded.content_hash,
                "byte_size": downloaded.byte_size,
                "etag": downloaded.etag,
                "last_modified": downloaded.last_modified,
                "downloaded_at": downloaded.downloaded_at,
                "audience": downloaded.candidate.metadata.get("audience"),
            },
        )
        resource_id = result.scalar_one()
        priority_rank = await self._priority_rank(downloaded.candidate.organization)
        await self.enqueue_review(
            resource_id,
            priority=100 - priority_rank if priority_rank else 3,
            reason=(
                f"New or updated priority-source resource: {downloaded.candidate.organization}"
                if priority_rank
                else "New or updated approved-source resource"
            ),
        )
        return resource_id

    async def record_manual_download(
        self,
        downloaded: DownloadedResource,
        *,
        reviewer: str,
        audience: str,
        priority_rank: int,
        is_baha: bool,
        is_iap: bool,
    ) -> UUID:
        resource_id = await self.record_download(downloaded)
        await self.session.execute(
            text(
                """
                update acquired_resources
                set reviewer = :reviewer,
                    audience = :audience,
                    priority_rank = :priority_rank,
                    is_baha_resource = :is_baha,
                    is_iap_resource = :is_iap,
                    ingestion_method = 'manual_resource_ingestion',
                    updated_at = now()
                where id = :id
                """
            ),
            {
                "id": resource_id,
                "reviewer": reviewer,
                "audience": audience,
                "priority_rank": priority_rank,
                "is_baha": is_baha,
                "is_iap": is_iap,
            },
        )
        return resource_id

    async def mark_resource_quality(
        self,
        resource_id: UUID,
        *,
        status: str,
        errors: tuple[str, ...],
    ) -> None:
        await self.session.execute(
            text(
                """
                update acquired_resources
                set quality_status = :status,
                    quality_errors = :errors,
                    updated_at = now()
                where id = :id
                """
            ),
            {"id": resource_id, "status": status, "errors": list(errors)},
        )

    async def resources_for_extraction(
        self,
        *,
        limit: int = 1000,
        only_unchecked: bool = True,
        organization: str | None = None,
    ) -> list[dict[str, Any]]:
        filters = []
        if only_unchecked:
            filters.append("quality_status = 'unchecked'")
        if organization:
            filters.append("organization = :organization")
        quality_filter = f"where {' and '.join(filters)}" if filters else ""
        result = await self.session.execute(
            text(
                f"""
                select *
                from acquired_resources
                {quality_filter}
                order by downloaded_at asc
                limit :limit
                """
            ),
            {"limit": limit, "organization": organization},
        )
        return [dict(row._mapping) for row in result.fetchall()]

    async def update_extracted_metadata(
        self,
        resource_id: UUID,
        *,
        extracted: dict[str, Any],
    ) -> None:
        await self.session.execute(
            text(
                """
                update acquired_resources
                set extracted_metadata = cast(:extracted as jsonb),
                    topic = coalesce(:topic, topic),
                    subtopic = coalesce(:subtopic, subtopic),
                    audience = coalesce(:audience, audience),
                    metadata = metadata || cast(:metadata_patch as jsonb),
                    updated_at = now()
                where id = :id
                """
            ),
            {
                "id": resource_id,
                "extracted": _json_dumps(extracted),
                "topic": extracted.get("topic"),
                "subtopic": extracted.get("subtopic"),
                "audience": extracted.get("audience"),
                "metadata_patch": _json_dumps(
                    {
                        "audience": extracted.get("audience"),
                        "keywords": extracted.get("keywords", []),
                        "entities": extracted.get("entities", []),
                        "summary": extracted.get("summary"),
                        "recommended_age_group": extracted.get("recommended_age_group"),
                        "skills": extracted.get("skills", []),
                    }
                ),
            },
        )

    async def upsert_condition_profile(
        self,
        *,
        condition: str,
        profile: dict[str, Any],
        resource_id: UUID,
    ) -> None:
        await self.session.execute(
            text(
                """
                insert into condition_profiles (condition, profile, evidence_chunk_ids, review_status)
                values (:condition, cast(:profile as jsonb), '{}', 'draft')
                on conflict (condition) do update set
                  profile = condition_profiles.profile || excluded.profile,
                  review_status = 'draft',
                  updated_at = now()
                """
            ),
            {
                "condition": condition,
                "profile": _json_dumps({**profile, "latest_resource_id": str(resource_id)}),
            },
        )
        await self.session.execute(
            text(
                """
                update condition_profile_targets
                set profile_exists = true, last_updated = now()
                where condition = :condition
                """
            ),
            {"condition": condition},
        )

    async def upsert_knowledge_graph(
        self,
        *,
        condition: str,
        profile: dict[str, Any],
        resource_id: UUID,
    ) -> None:
        condition_id = await self._upsert_node("Condition", condition, {"condition": condition})
        relationships = {
            "symptoms": "HAS_SYMPTOM",
            "risk_factors": "HAS_RISK_FACTOR",
            "parent_signs": "HAS_PARENT_SIGN",
            "teacher_signs": "HAS_TEACHER_SIGN",
            "interventions": "HAS_INTERVENTION",
            "parent_interventions": "HAS_INTERVENTION",
            "teacher_interventions": "HAS_INTERVENTION",
            "counselor_interventions": "HAS_INTERVENTION",
            "escalation_indicators": "HAS_ESCALATION_INDICATOR",
            "emergency_indicators": "HAS_ESCALATION_INDICATOR",
        }
        node_types = {
            "symptoms": "Symptom",
            "risk_factors": "Risk Factor",
            "parent_signs": "Parent Sign",
            "teacher_signs": "Teacher Sign",
            "interventions": "Intervention",
            "parent_interventions": "Intervention",
            "teacher_interventions": "Intervention",
            "counselor_interventions": "Intervention",
            "escalation_indicators": "Escalation Indicator",
            "emergency_indicators": "Escalation Indicator",
        }
        for field, relationship in relationships.items():
            values = profile.get(field) or []
            if isinstance(values, str):
                values = [values]
            for value in values[:10]:
                label = self._short_label(value)
                if not label:
                    continue
                target_id = await self._upsert_node(node_types[field], label, {"source_field": field})
                await self._upsert_edge(
                    condition_id,
                    target_id,
                    relationship,
                    resource_id,
                    {"source_field": field},
                )

    async def upsert_skill_knowledge_graph(
        self,
        *,
        skills: list[str],
        extracted: dict[str, Any],
        resource_id: UUID,
    ) -> None:
        relationships = {
            "interventions": ("HAS_SKILL_INTERVENTION", "Skill Intervention"),
            "parent_support": ("HAS_PARENT_SUPPORT", "Parent Support"),
            "teacher_support": ("HAS_TEACHER_SUPPORT", "Teacher Support"),
            "school_support": ("HAS_SCHOOL_SUPPORT", "School Support"),
        }
        for skill in skills:
            skill_id = await self._upsert_node(
                "Skill",
                skill.title(),
                {"topic": skill},
            )
            for field, (relationship, node_type) in relationships.items():
                values = extracted.get(field) or []
                if isinstance(values, str):
                    values = [values]
                for value in values[:12]:
                    label = self._short_label(value)
                    if not label:
                        continue
                    target_id = await self._upsert_node(
                        node_type,
                        label,
                        {"source_field": field},
                    )
                    await self._upsert_edge(
                        skill_id,
                        target_id,
                        relationship,
                        resource_id,
                        {"source_field": field, "skill": skill},
                    )

    async def refresh_topic_coverage(self) -> None:
        await self.session.execute(
            text(
                """
                insert into topic_coverage (
                  topic, document_count, pdf_count, research_count,
                  target_count, gap_count, target_met, last_updated
                )
                select
                  t.topic,
                  coalesce(count(r.id), 0)::integer as document_count,
                  coalesce(count(r.id) filter (where r.resource_type = 'pdf'), 0)::integer as pdf_count,
                  coalesce(count(r.id) filter (
                    where r.resource_type = 'research_paper'
                       or r.organization in ('PubMed', 'Europe PMC', 'Semantic Scholar')
                  ), 0)::integer as research_count,
                  t.minimum_documents as target_count,
                  greatest(t.minimum_documents - coalesce(count(r.id), 0), 0)::integer as gap_count,
                  coalesce(count(r.id), 0) >= t.minimum_documents as target_met,
                  now()
                from topic_targets t
                left join acquired_resources r
                  on r.topic = t.topic
                 and r.quality_status <> 'rejected'
                group by t.topic, t.minimum_documents
                on conflict (topic) do update set
                  document_count = excluded.document_count,
                  pdf_count = excluded.pdf_count,
                  research_count = excluded.research_count,
                  target_count = excluded.target_count,
                  gap_count = excluded.gap_count,
                  target_met = excluded.target_met,
                  last_updated = now()
                """
            )
        )

    async def topic_gaps(self) -> list[dict[str, Any]]:
        await self.refresh_topic_coverage()
        result = await self.session.execute(
            text(
                """
                select *
                from topic_coverage
                where target_met = false
                order by gap_count desc, topic
                """
            )
        )
        return [dict(row._mapping) for row in result.fetchall()]

    async def embedding_readiness(self) -> dict[str, Any]:
        await self.refresh_topic_coverage()
        totals = await self.session.execute(
            text(
                """
                select
                  count(*) as documents_count,
                  count(*) filter (
                    where resource_type = 'research_paper'
                       or organization in ('PubMed', 'Europe PMC', 'Semantic Scholar')
                  ) as research_papers_count
                from acquired_resources
                where quality_status <> 'rejected'
                """
            )
        )
        gaps = await self.topic_gaps()
        totals_map = dict(totals.one()._mapping)
        major_topics = {
            "depression", "anxiety", "stress", "bullying", "cyberbullying",
            "sleep", "digital wellness", "nutrition", "physical activity",
            "adhd", "autism", "self harm", "suicide prevention", "substance abuse",
        }
        major_gaps = [
            {
                "topic": gap["topic"],
                "gap_percent": round(
                    (gap["gap_count"] / gap["target_count"]) * 100, 2
                ) if gap["target_count"] else 0,
            }
            for gap in gaps
            if gap["topic"] in major_topics
            and gap["target_count"]
            and (gap["gap_count"] / gap["target_count"]) >= 0.20
        ]
        unmet_topics = [gap["topic"] for gap in major_gaps]
        ready = (
            totals_map["documents_count"] >= 1000
            and totals_map["research_papers_count"] >= 500
            and not major_gaps
        )
        await self.session.execute(
            text(
                """
                insert into embedding_readiness_checks (
                  documents_count, research_papers_count, unmet_topics, ready
                )
                values (:documents_count, :research_papers_count, :unmet_topics, :ready)
                """
            ),
            {
                "documents_count": totals_map["documents_count"],
                "research_papers_count": totals_map["research_papers_count"],
                "unmet_topics": unmet_topics,
                "ready": ready,
            },
        )
        return {
            **totals_map,
            "requirements": {
                "documents": 1000,
                "research_papers": 500,
                "maximum_major_topic_gap_percent": 20,
            },
            "major_topic_gaps": major_gaps,
            "unmet_topics": unmet_topics,
            "status": "READY" if ready else "NOT_READY",
            "ready": ready,
        }

    async def persist_daily_report(self, report: dict[str, Any]) -> None:
        await self.session.execute(
            text(
                """
                insert into daily_acquisition_reports (report_date, report)
                values (current_date, cast(:report as jsonb))
                on conflict (report_date) do update set
                  report = excluded.report,
                  created_at = now()
                """
            ),
            {"report": _json_dumps(report)},
        )

    async def enqueue_review(
        self,
        resource_id: UUID,
        *,
        priority: int = 3,
        reason: str = "New or updated approved-source resource",
    ) -> UUID:
        result = await self.session.execute(
            text(
                """
                insert into clinical_review_queue (resource_id, status, priority, reason)
                values (:resource_id, 'pending', :priority, :reason)
                on conflict (resource_id) do update set
                  status = case
                    when clinical_review_queue.status = 'approved' then 'needs_re_review'
                    else clinical_review_queue.status
                  end,
                  priority = greatest(clinical_review_queue.priority, excluded.priority),
                  reason = excluded.reason,
                  updated_at = now()
                returning id
                """
            ),
            {"resource_id": resource_id, "priority": priority, "reason": reason},
        )
        return result.scalar_one()

    async def set_review_priority(self, resource_id: UUID, *, priority: int, reason: str) -> None:
        await self.enqueue_review(resource_id, priority=priority, reason=reason)

    async def create_manual_batch(
        self,
        *,
        organization: str,
        reviewer: str,
        source: str,
        submitted_count: int,
        metadata: dict[str, Any],
    ) -> UUID:
        result = await self.session.execute(
            text(
                """
                insert into manual_ingestion_batches (
                  organization, reviewer, source, submitted_count, metadata
                )
                values (
                  :organization, :reviewer, :source, :submitted_count, cast(:metadata as jsonb)
                )
                returning id
                """
            ),
            {
                "organization": organization,
                "reviewer": reviewer,
                "source": source,
                "submitted_count": submitted_count,
                "metadata": _json_dumps(metadata),
            },
        )
        return result.scalar_one()

    async def complete_manual_batch(
        self,
        batch_id: UUID,
        *,
        status: str,
        imported: int,
        duplicates: int,
        rejected: int,
        errors: int,
    ) -> None:
        await self.session.execute(
            text(
                """
                update manual_ingestion_batches
                set status = :status,
                    imported_count = :imported,
                    duplicate_count = :duplicates,
                    rejected_count = :rejected,
                    error_count = :errors,
                    finished_at = now()
                where id = :id
                """
            ),
            {
                "id": batch_id,
                "status": status,
                "imported": imported,
                "duplicates": duplicates,
                "rejected": rejected,
                "errors": errors,
            },
        )

    async def record_manual_ingestion(
        self,
        *,
        batch_id: UUID,
        resource_id: UUID,
        organization: str,
        reviewer: str,
        resource_type: str,
        original_filename: str,
        publication_date: date | None,
        source: str,
        topic: str | None,
        audience: str,
        content_hash: str,
        storage_uri: str,
        status: str,
        is_baha: bool,
        is_iap: bool,
        metadata: dict[str, Any],
    ) -> UUID:
        result = await self.session.execute(
            text(
                """
                insert into manual_resource_ingestion (
                  batch_id, resource_id, organization, reviewer, resource_type,
                  original_filename, publication_date, source, topic, audience,
                  content_hash, storage_uri, status, is_baha_resource,
                  is_iap_resource, metadata
                )
                values (
                  :batch_id, :resource_id, :organization, :reviewer, :resource_type,
                  :original_filename, :publication_date, :source, :topic, :audience,
                  :content_hash, :storage_uri, :status, :is_baha, :is_iap,
                  cast(:metadata as jsonb)
                )
                returning id
                """
            ),
            {
                "batch_id": batch_id,
                "resource_id": resource_id,
                "organization": organization,
                "reviewer": reviewer,
                "resource_type": resource_type,
                "original_filename": original_filename,
                "publication_date": publication_date,
                "source": source,
                "topic": topic,
                "audience": audience,
                "content_hash": content_hash,
                "storage_uri": storage_uri,
                "status": status,
                "is_baha": is_baha,
                "is_iap": is_iap,
                "metadata": _json_dumps(metadata),
            },
        )
        return result.scalar_one()

    async def record_manual_error(
        self,
        *,
        batch_id: UUID,
        organization: str,
        reviewer: str,
        source: str,
        original_filename: str,
        resource_type: str,
        publication_date: date | None,
        topic: str | None,
        audience: str,
        error: str,
        is_baha: bool,
        is_iap: bool,
    ) -> UUID:
        result = await self.session.execute(
            text(
                """
                insert into manual_resource_ingestion (
                  batch_id, organization, reviewer, resource_type, original_filename,
                  publication_date, source, topic, audience, status, error,
                  is_baha_resource, is_iap_resource
                )
                values (
                  :batch_id, :organization, :reviewer, :resource_type, :original_filename,
                  :publication_date, :source, :topic, :audience, 'error', :error,
                  :is_baha, :is_iap
                )
                returning id
                """
            ),
            {
                "batch_id": batch_id,
                "organization": organization,
                "reviewer": reviewer,
                "resource_type": resource_type,
                "original_filename": original_filename,
                "publication_date": publication_date,
                "source": source,
                "topic": topic,
                "audience": audience,
                "error": error[:4000],
                "is_baha": is_baha,
                "is_iap": is_iap,
            },
        )
        return result.scalar_one()

    async def priority_topic_gaps(self, topics: tuple[str, ...]) -> list[dict[str, Any]]:
        result = await self.session.execute(
            text(
                """
                select
                  t.topic,
                  t.minimum_documents as target_count,
                  count(r.id)::integer as current_count,
                  greatest(t.minimum_documents - count(r.id), 0)::integer as gap_count,
                  count(r.id) >= t.minimum_documents as target_met
                from priority_gap_targets t
                left join acquired_resources r
                  on r.topic = t.topic
                 and r.quality_status <> 'rejected'
                where t.active = true and t.topic = any(cast(:topics as text[]))
                group by t.topic, t.minimum_documents
                having count(r.id) < t.minimum_documents
                order by gap_count desc, t.topic
                """
            ),
            {"topics": list(topics)},
        )
        return [dict(row._mapping) for row in result.fetchall()]

    async def upsert_priority_gap_search(
        self,
        *,
        topic: str,
        organization: str,
        priority_rank: int,
        query: str,
        search_url: str | None,
        run_key: str,
    ) -> UUID:
        result = await self.session.execute(
            text(
                """
                insert into priority_gap_searches (
                  topic, organization, priority_rank, query, search_url, run_key
                )
                values (
                  :topic, :organization, :priority_rank, :query, :search_url, :run_key
                )
                on conflict (topic, organization, query, run_key) do update set
                  search_url = excluded.search_url
                returning id
                """
            ),
            {
                "topic": topic,
                "organization": organization,
                "priority_rank": priority_rank,
                "query": query,
                "search_url": search_url,
                "run_key": run_key,
            },
        )
        return result.scalar_one()

    async def priority_coverage_dashboard(self) -> dict[str, Any]:
        organization_rows = await self.session.execute(
            text(
                """
                select
                  p.organization,
                  p.priority_rank,
                  count(r.id) filter (where r.quality_status <> 'rejected') as resources,
                  count(r.id) filter (
                    where r.quality_status <> 'rejected' and r.resource_type = 'pdf'
                  ) as pdfs,
                  count(r.id) filter (
                    where r.quality_status <> 'rejected'
                      and r.ingestion_method = 'manual_resource_ingestion'
                  ) as manual_resources,
                  max(r.downloaded_at) as latest_resource_at
                from priority_sources p
                left join acquired_resources r on r.organization = p.organization
                where p.active = true
                group by p.organization, p.priority_rank
                order by p.priority_rank
                """
            )
        )
        audience_rows = await self.session.execute(
            text(
                """
                select
                  p.organization,
                  a.audience,
                  count(r.id) as resources
                from priority_sources p
                cross join (
                  values ('parent'), ('teacher'), ('counselor'), ('adolescent')
                ) as a(audience)
                left join acquired_resources r
                  on r.organization = p.organization
                 and r.audience = a.audience
                 and r.quality_status <> 'rejected'
                where p.is_baha_source or p.is_iap_source
                group by p.organization, p.priority_rank, a.audience
                order by p.priority_rank, a.audience
                """
            )
        )
        topic_rows = await self.session.execute(
            text(
                """
                select
                  p.organization,
                  t.topic,
                  count(r.id) as resources
                from priority_sources p
                cross join priority_gap_targets t
                left join acquired_resources r
                  on r.organization = p.organization
                 and r.topic = t.topic
                 and r.quality_status <> 'rejected'
                where (p.is_baha_source or p.is_iap_source)
                  and t.active = true
                group by p.organization, p.priority_rank, t.topic
                order by p.priority_rank, t.topic
                """
            )
        )
        batch_rows = await self.session.execute(
            text(
                """
                select
                  organization,
                  count(*) as batches,
                  sum(imported_count) as imported,
                  sum(duplicate_count) as duplicates,
                  sum(rejected_count) as rejected,
                  sum(error_count) as errors
                from manual_ingestion_batches
                group by organization
                order by organization
                """
            )
        )
        organizations = [dict(row._mapping) for row in organization_rows.fetchall()]
        audiences = [dict(row._mapping) for row in audience_rows.fetchall()]
        topics = [dict(row._mapping) for row in topic_rows.fetchall()]
        manual = [dict(row._mapping) for row in batch_rows.fetchall()]

        def organization_coverage(organization: str) -> dict[str, Any]:
            summary = next(
                (row for row in organizations if row["organization"] == organization),
                {"organization": organization, "resources": 0, "pdfs": 0, "manual_resources": 0},
            )
            return {
                "summary": summary,
                "audiences": {
                    row["audience"]: row["resources"]
                    for row in audiences
                    if row["organization"] == organization
                },
                "priority_topics": [
                    row for row in topics if row["organization"] == organization
                ],
            }

        return {
            "baha_coverage": organization_coverage("Bangalore Adolescent Health Academy"),
            "iap_coverage": organization_coverage("Indian Academy of Pediatrics"),
            "priority_sources": organizations,
            "audience_coverage": audiences,
            "topic_coverage": topics,
            "manual_ingestion": manual,
        }

    async def priority_campaign_report(
        self,
        *,
        organizations: tuple[str, ...],
        expected_topics: list[str],
        expected_resource_types: list[str],
    ) -> dict[str, Any]:
        params = {"organizations": list(organizations)}
        totals_result = await self.session.execute(
            text(
                """
                select
                  organization,
                  count(*) as downloaded,
                  count(*) filter (where quality_status <> 'rejected') as accepted,
                  count(*) filter (where quality_status = 'rejected') as rejected
                from acquired_resources
                where organization = any(cast(:organizations as text[]))
                group by organization
                order by organization
                """
            ),
            params,
        )
        audience_result = await self.session.execute(
            text(
                """
                select
                  organization,
                  coalesce(nullif(audience, 'general'), metadata ->> 'audience', 'general') as audience,
                  count(*) as resources
                from acquired_resources
                where organization = any(cast(:organizations as text[]))
                  and quality_status <> 'rejected'
                group by organization,
                  coalesce(nullif(audience, 'general'), metadata ->> 'audience', 'general')
                order by organization, audience
                """
            ),
            params,
        )
        topic_result = await self.session.execute(
            text(
                """
                select organization, topic, count(*) as resources
                from acquired_resources
                where organization = any(cast(:organizations as text[]))
                  and quality_status <> 'rejected'
                  and topic is not null
                group by organization, topic
                order by organization, topic
                """
            ),
            params,
        )
        condition_result = await self.session.execute(
            text(
                """
                select
                  organization,
                  extracted_metadata ->> 'condition' as condition,
                  count(*) as resources
                from acquired_resources
                where organization = any(cast(:organizations as text[]))
                  and quality_status <> 'rejected'
                  and extracted_metadata ->> 'condition' is not null
                group by organization, extracted_metadata ->> 'condition'
                order by organization, condition
                """
            ),
            params,
        )
        type_result = await self.session.execute(
            text(
                """
                select organization, resource_type, count(*) as resources
                from acquired_resources
                where organization = any(cast(:organizations as text[]))
                  and quality_status <> 'rejected'
                group by organization, resource_type
                order by organization, resource_type
                """
            ),
            params,
        )
        urls_result = await self.session.execute(
            text(
                """
                select
                  organization, url, title, resource_type, topic, audience,
                  quality_status, source_weight, downloaded_at
                from acquired_resources
                where organization = any(cast(:organizations as text[]))
                order by organization, url
                """
            ),
            params,
        )
        failed_result = await self.session.execute(
            text(
                """
                select organization, url, status, error
                from acquisition_candidates
                where organization = any(cast(:organizations as text[]))
                  and status in ('failed', 'retry')
                order by organization, url
                """
            ),
            params,
        )
        totals = [dict(row._mapping) for row in totals_result.fetchall()]
        audiences = [dict(row._mapping) for row in audience_result.fetchall()]
        topics = [dict(row._mapping) for row in topic_result.fetchall()]
        conditions = [dict(row._mapping) for row in condition_result.fetchall()]
        resource_types = [dict(row._mapping) for row in type_result.fetchall()]
        urls = [dict(row._mapping) for row in urls_result.fetchall()]
        topic_names = {row["topic"] for row in topics}
        type_names = {row["resource_type"] for row in resource_types}
        return {
            "aha_resource_count": next(
                (
                    row["accepted"]
                    for row in totals
                    if row["organization"] == "IAP Adolescent Health Academy"
                ),
                0,
            ),
            "nimhans_resource_count": next(
                (row["accepted"] for row in totals if row["organization"] == "NIMHANS"),
                0,
            ),
            "organization_totals": totals,
            "audience_coverage": audiences,
            "topic_coverage": topics,
            "condition_coverage": conditions,
            "resource_type_coverage": resource_types,
            "missing_topics": [
                topic for topic in expected_topics if topic not in topic_names
            ],
            "missing_resource_types": [
                resource_type
                for resource_type in expected_resource_types
                if resource_type not in type_names
            ],
            "collected_urls": urls,
            "failed_urls": [dict(row._mapping) for row in failed_result.fetchall()],
            "generated_at": datetime.now(timezone.utc).isoformat(),
        }

    async def persist_weekly_priority_report(
        self,
        week_start: date,
        report: dict[str, Any],
    ) -> None:
        await self.session.execute(
            text(
                """
                insert into weekly_priority_gap_reports (week_start, report)
                values (:week_start, cast(:report as jsonb))
                on conflict (week_start) do update set
                  report = excluded.report,
                  created_at = now()
                """
            ),
            {"week_start": week_start, "report": _json_dumps(report)},
        )

    async def create_job(self, job_type: str, payload: dict[str, Any]) -> UUID:
        result = await self.session.execute(
            text(
                """
                insert into acquisition_jobs (job_type, status, payload, started_at)
                values (:job_type, 'running', cast(:payload as jsonb), now())
                returning id
                """
            ),
            {"job_type": job_type, "payload": _json_dumps(payload)},
        )
        return result.scalar_one()

    async def complete_job(
        self,
        job_id: UUID,
        *,
        status: str,
        discovered_count: int = 0,
        downloaded_count: int = 0,
        error_count: int = 0,
        error: str | None = None,
    ) -> None:
        await self.session.execute(
            text(
                """
                update acquisition_jobs
                set status = :status,
                    discovered_count = :discovered_count,
                    downloaded_count = :downloaded_count,
                    error_count = :error_count,
                    error = :error,
                    finished_at = now()
                where id = :id
                """
            ),
            {
                "id": job_id,
                "status": status,
                "discovered_count": discovered_count,
                "downloaded_count": downloaded_count,
                "error_count": error_count,
                "error": error,
            },
        )

    async def source_inventory(self) -> dict[str, Any]:
        source_rows = await self.session.execute(
            text(
                """
                select
                  s.organization,
                  s.country,
                  s.source_type,
                  coalesce(count(distinct c.id), 0) as candidates,
                  coalesce(count(distinct r.id), 0) as downloaded,
                  max(r.downloaded_at) as latest_downloaded_at
                from acquisition_sources s
                left join priority_sources p on p.organization = s.organization
                left join acquisition_candidates c on c.organization = s.organization
                left join acquired_resources r on r.organization = s.organization
                group by s.organization, s.country, s.source_type, p.priority_rank
                order by coalesce(p.priority_rank, 999), s.organization
                """
            )
        )
        topic_rows = await self.session.execute(
            text(
                """
                select topic, count(*) as documents
                from acquired_resources
                where topic is not null
                group by topic
                order by topic
                """
            )
        )
        return {
            "sources": [dict(row._mapping) for row in source_rows.fetchall()],
            "condition_coverage": [dict(row._mapping) for row in topic_rows.fetchall()],
        }

    async def phase_report(self) -> dict[str, Any]:
        await self.refresh_topic_coverage()
        campaign_rows = await self.session.execute(
            text(
                """
                select
                  r.organization,
                  count(distinct r.id) filter (where r.quality_status <> 'rejected') as accepted,
                  count(distinct r.id) filter (where r.quality_status = 'rejected') as rejected,
                  count(distinct d.duplicate_resource_id) as duplicates,
                  count(distinct r.id) filter (
                    where r.quality_status <> 'rejected' and r.resource_type = 'pdf'
                  ) as pdfs,
                  count(distinct r.id) filter (
                    where r.quality_status <> 'rejected' and r.audience = 'teacher'
                  ) as teacher_resources,
                  count(distinct r.id) filter (
                    where r.quality_status <> 'rejected' and r.audience = 'parent'
                  ) as parent_resources,
                  count(distinct r.id) filter (
                    where r.quality_status <> 'rejected' and r.audience = 'adolescent'
                  ) as adolescent_resources
                from acquired_resources r
                left join resource_duplicates d on d.duplicate_resource_id = r.id
                where r.organization in ('IAP Adolescent Health Academy', 'NIMHANS')
                group by r.organization
                order by r.organization
                """
            )
        )
        source_rows = await self.session.execute(
            text(
                """
                with resource_counts as (
                  select
                    organization,
                    count(*) filter (where quality_status = 'accepted') as accepted_count,
                    count(*) filter (
                      where quality_status = 'accepted' and resource_type = 'pdf'
                    ) as pdf_count
                  from acquired_resources
                  group by organization
                ),
                condition_counts as (
                  select
                    r.organization,
                    count(distinct conditions.condition) as condition_count
                  from acquired_resources r
                  cross join lateral jsonb_object_keys(
                    case
                      when jsonb_typeof(r.extracted_metadata -> 'clinical_profiles') = 'object'
                      then r.extracted_metadata -> 'clinical_profiles'
                      else '{}'::jsonb
                    end
                  ) as conditions(condition)
                  where r.quality_status = 'accepted'
                  group by r.organization
                )
                select
                  rc.organization,
                  rc.accepted_count,
                  rc.pdf_count,
                  coalesce(cc.condition_count, 0) as clinical_profiles,
                  coalesce(cc.condition_count, 0) as condition_count
                from resource_counts rc
                left join condition_counts cc using (organization)
                where rc.accepted_count > 0
                order by rc.accepted_count desc, rc.organization
                """
            )
        )
        requested_topics = (
            "depression", "anxiety", "stress", "sleep", "bullying",
            "cyberbullying", "digital wellness", "nutrition", "physical activity",
            "adhd", "autism", "self harm", "suicide prevention", "substance abuse",
        )
        topic_rows = await self.session.execute(
            text(
                """
                select
                  topic,
                  document_count as current_count,
                  target_count,
                  gap_count as gap
                from topic_coverage
                where topic = any(cast(:topics as text[]))
                order by array_position(cast(:topics as text[]), topic)
                """
            ),
            {"topics": list(requested_topics)},
        )
        gap_rows = await self.session.execute(
            text(
                """
                select topic, document_count as current_count, target_count, gap_count as gap
                from topic_coverage
                where gap_count > 0
                order by gap_count desc, topic
                limit 10
                """
            )
        )
        condition_rows = await self.session.execute(
            text(
                """
                select
                  t.condition,
                  exists (
                    select 1 from condition_profiles p where p.condition = t.condition
                  ) as profile_exists,
                  p.review_status,
                  p.updated_at
                from condition_profile_targets t
                left join condition_profiles p on p.condition = t.condition
                where t.required = true
                order by t.condition
                """
            )
        )
        graph_rows = await self.session.execute(
            text(
                """
                select
                  (select count(*) from knowledge_graph_nodes) as node_count,
                  (select count(*) from knowledge_graph_edges) as edge_count,
                  (select count(*) from condition_profiles) as condition_profile_count
                """
            )
        )
        node_rows = await self.session.execute(
            text(
                """
                select node_type, count(*) as count
                from knowledge_graph_nodes
                group by node_type
                order by count(*) desc, node_type
                """
            )
        )
        edge_rows = await self.session.execute(
            text(
                """
                select relationship, count(*) as count
                from knowledge_graph_edges
                group by relationship
                order by count(*) desc, relationship
                """
            )
        )
        queue_rows = await self.session.execute(
            text(
                """
                select organization, status, count(*) as count
                from acquisition_candidates
                where organization in ('IAP Adolescent Health Academy', 'NIMHANS')
                group by organization, status
                order by organization, status
                """
            )
        )
        conditions = [dict(row._mapping) for row in condition_rows.fetchall()]
        return {
            "campaign_acquisition": [dict(row._mapping) for row in campaign_rows.fetchall()],
            "source_coverage": [dict(row._mapping) for row in source_rows.fetchall()],
            "topic_coverage": [dict(row._mapping) for row in topic_rows.fetchall()],
            "top_10_gaps": [dict(row._mapping) for row in gap_rows.fetchall()],
            "condition_profiles": {
                "total": sum(1 for row in conditions if row["profile_exists"]),
                "target": 25,
                "profiles": conditions,
                "missing": [row["condition"] for row in conditions if not row["profile_exists"]],
            },
            "knowledge_graph": {
                **dict(graph_rows.one()._mapping),
                "nodes_by_type": [dict(row._mapping) for row in node_rows.fetchall()],
                "edges_by_relationship": [dict(row._mapping) for row in edge_rows.fetchall()],
            },
            "campaign_candidate_status": [dict(row._mapping) for row in queue_rows.fetchall()],
            "generated_at": datetime.now(timezone.utc).isoformat(),
        }

    async def final_report(self, expected_topics: list[str]) -> dict[str, Any]:
        totals = await self.session.execute(
            text(
                """
                select
                  count(*) as total_documents_downloaded,
                  count(*) filter (where resource_type = 'pdf') as total_pdfs,
                  count(*) filter (
                    where resource_type = 'research_paper'
                       or organization in ('PubMed', 'Europe PMC', 'Semantic Scholar')
                  ) as total_research_papers,
                  count(*) filter (where resource_type = 'dataset') as total_datasets,
                  count(distinct organization) as sources_with_downloads,
                  count(distinct topic) filter (where topic is not null) as covered_topics
                from acquired_resources
                """
            )
        )
        coverage_rows = await self.session.execute(
            text(
                """
                select organization, count(*) as documents
                from acquired_resources
                group by organization
                order by organization
                """
            )
        )
        topic_rows = await self.session.execute(
            text(
                """
                select topic, count(*) as documents
                from acquired_resources
                where topic is not null
                group by topic
                order by topic
                """
            )
        )
        country_rows = await self.session.execute(
            text(
                """
                select coalesce(country, 'Unknown') as country, count(*) as documents
                from acquired_resources
                group by coalesce(country, 'Unknown')
                order by country
                """
            )
        )
        condition_rows = await self.session.execute(
            text(
                """
                select topic as condition, count(*) as documents
                from acquired_resources
                where topic is not null
                group by topic
                order by topic
                """
            )
        )
        topic_counts = {row._mapping["topic"]: row._mapping["documents"] for row in topic_rows.fetchall()}
        await self.refresh_topic_coverage()
        gap_rows = await self.session.execute(
            text(
                """
                select topic, document_count, pdf_count, research_count, target_count, gap_count
                from topic_coverage
                where target_met = false
                order by gap_count desc, topic
                """
            )
        )
        graph_counts = await self.session.execute(
            text(
                """
                select
                  (select count(*) from condition_profiles) as clinical_profile_count,
                  (select count(*) from knowledge_graph_nodes) as knowledge_graph_node_count,
                  (select count(*) from knowledge_graph_edges) as knowledge_graph_edge_count
                """
            )
        )
        failed_sources = await self.session.execute(
            text(
                """
                select organization, count(*) as failures
                from acquisition_candidates
                where status in ('failed', 'retry')
                group by organization
                order by organization
                """
            )
        )
        report = {
            **dict(totals.one()._mapping),
            **dict(graph_counts.one()._mapping),
            "source_coverage": [dict(row._mapping) for row in coverage_rows.fetchall()],
            "country_coverage": [dict(row._mapping) for row in country_rows.fetchall()],
            "condition_coverage": topic_counts,
            "condition_coverage_detail": [dict(row._mapping) for row in condition_rows.fetchall()],
            "topic_gaps": [dict(row._mapping) for row in gap_rows.fetchall()],
            "missing_topics": [topic for topic in expected_topics if topic not in topic_counts],
            "failed_sources": [dict(row._mapping) for row in failed_sources.fetchall()],
            "generated_at": datetime.now(timezone.utc).isoformat(),
        }
        await self.persist_daily_report(report)
        return report

    def _candidate_params(self, candidate: ResourceCandidate) -> dict[str, Any]:
        return {
            "url": candidate.url,
            "normalized_url": candidate.url.split("#", 1)[0].rstrip("/").lower(),
            "organization": candidate.organization,
            "source": candidate.source,
            "title": candidate.title,
            "author": candidate.author,
            "publication_date_raw": candidate.publication_date,
            "country": candidate.country,
            "language": candidate.language,
            "topic": candidate.topic,
            "subtopic": candidate.subtopic,
            "resource_type": candidate.resource_type,
            "content_type": candidate.content_type,
            "discovered_via": candidate.discovered_via,
            "metadata": _json_dumps(candidate.metadata),
            "audience": candidate.metadata.get("audience"),
        }

    async def _upsert_node(self, node_type: str, label: str, metadata: dict[str, Any]) -> UUID:
        result = await self.session.execute(
            text(
                """
                insert into knowledge_graph_nodes (node_type, label, normalized_label, metadata)
                values (:node_type, :label, :normalized_label, cast(:metadata as jsonb))
                on conflict (node_type, normalized_label) do update set
                  metadata = knowledge_graph_nodes.metadata || excluded.metadata,
                  updated_at = now()
                returning id
                """
            ),
            {
                "node_type": node_type,
                "label": label,
                "normalized_label": label.lower().strip(),
                "metadata": _json_dumps(metadata),
            },
        )
        return result.scalar_one()

    async def _upsert_edge(
        self,
        source_node_id: UUID,
        target_node_id: UUID,
        relationship: str,
        resource_id: UUID,
        metadata: dict[str, Any],
    ) -> None:
        await self.session.execute(
            text(
                """
                insert into knowledge_graph_edges (
                  source_node_id, target_node_id, relationship,
                  evidence_resource_id, confidence, metadata
                )
                values (
                  :source_node_id, :target_node_id, :relationship,
                  :resource_id, 0.55, cast(:metadata as jsonb)
                )
                on conflict (source_node_id, target_node_id, relationship, evidence_resource_id)
                do update set metadata = knowledge_graph_edges.metadata || excluded.metadata
                """
            ),
            {
                "source_node_id": source_node_id,
                "target_node_id": target_node_id,
                "relationship": relationship,
                "resource_id": resource_id,
                "metadata": _json_dumps(metadata),
            },
        )

    def _short_label(self, value: str) -> str:
        words = value.strip().split()
        return " ".join(words[:18])[:180]

    async def _priority_rank(self, organization: str) -> int | None:
        result = await self.session.execute(
            text(
                """
                select priority_rank
                from priority_sources
                where organization = :organization and active = true
                """
            ),
            {"organization": organization},
        )
        return result.scalar_one_or_none()
