from __future__ import annotations

import asyncio
import json
import logging
from dataclasses import dataclass
from typing import Protocol
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen
from uuid import UUID

from baha_companion.common.exceptions import ValidationError
from baha_companion.embeddings.config import EmbeddingModelSpec, EmbeddingSettings
from baha_companion.embeddings.jobs import EmbeddingJobRunner
from baha_companion.embeddings.models import JobType
from baha_companion.embeddings.queue import EmbeddingJobQueue
from baha_companion.embeddings.repository import EmbeddingRepository
from baha_companion.embeddings.statistics import EmbeddingStatisticsService
from baha_companion.embeddings.utils import deterministic_embedding

logger = logging.getLogger("baha_companion.embeddings.service")


class EmbeddingProvider(Protocol):
    async def embed_texts(self, texts: list[str]) -> list[list[float]]: ...


@dataclass(slots=True)
class QueueContext:
    spec: EmbeddingModelSpec
    model: object
    version: object


class DeterministicEmbeddingProvider:
    def __init__(self, *, dimensions: int) -> None:
        self.dimensions = dimensions

    async def embed_texts(self, texts: list[str]) -> list[list[float]]:
        return [deterministic_embedding(text, dimensions=self.dimensions) for text in texts]


class OpenAICompatibleProvider:
    def __init__(self, *, spec: EmbeddingModelSpec, settings: EmbeddingSettings) -> None:
        self.spec = spec
        self.settings = settings

    async def embed_texts(self, texts: list[str]) -> list[list[float]]:
        api_base = self.settings.api_base_for(self.spec)
        api_key = self.settings.api_key_for(self.spec)
        if not api_base:
            raise ValidationError(f"API base is not configured for model {self.spec.key}.")
        if not api_key:
            raise ValidationError(f"API key is not configured for model {self.spec.key}.")
        body = await asyncio.to_thread(
            self._request_embeddings,
            api_base=api_base,
            api_key=api_key,
            texts=texts,
        )
        data = body.get("data", [])
        return [item["embedding"] for item in data]

    def _request_embeddings(self, *, api_base: str, api_key: str, texts: list[str]) -> dict:
        payload = json.dumps({"input": texts, "model": self.spec.model_name}).encode("utf-8")
        request = Request(
            f"{api_base.rstrip('/')}/embeddings",
            data=payload,
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            },
            method="POST",
        )
        try:
            with urlopen(request, timeout=30) as response:  # noqa: S310
                return json.loads(response.read().decode("utf-8"))
        except HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="ignore")
            raise ValidationError(
                f"Embedding provider request failed for model {self.spec.key}: {exc.code} {detail}".strip()
            ) from exc
        except URLError as exc:
            raise ValidationError(
                f"Embedding provider is unreachable for model {self.spec.key}: {exc.reason}"
            ) from exc


class EmbeddingService:
    def __init__(self, repository: EmbeddingRepository, *, settings: EmbeddingSettings) -> None:
        self.repository = repository
        self.settings = settings
        self.queue = EmbeddingJobQueue(repository)
        self.statistics_service = EmbeddingStatisticsService(repository)

    async def queue_object(self, *, knowledge_object_id: UUID, version_label: str | None = None, model_key: str | None = None, force: bool = False) -> dict:
        context = await self._ensure_context(version_label=version_label, model_key=model_key)
        queued = await self.queue.enqueue(
            knowledge_object_ids=[knowledge_object_id],
            model=context.model,
            version=context.version,
            job_type=JobType.OBJECT.value,
            scope_key="knowledge_object_id",
            scope_value=str(knowledge_object_id),
            force=force,
            max_attempts=self.settings.embedding_job_max_attempts,
        )
        return {"queued_jobs": queued, "model_key": context.spec.key, "version_label": context.version.version_label, "scope": "object"}

    async def queue_topic(self, *, topic: str, version_label: str | None = None, model_key: str | None = None, force: bool = False) -> dict:
        return await self._queue_scope(
            scope_key="topic",
            scope_value=topic,
            version_label=version_label,
            model_key=model_key,
            force=force,
            knowledge_object_ids=await self.repository.list_knowledge_object_ids(topic=topic),
        )

    async def queue_organisation(self, *, organisation: str, version_label: str | None = None, model_key: str | None = None, force: bool = False) -> dict:
        return await self._queue_scope(
            scope_key="organisation",
            scope_value=organisation,
            version_label=version_label,
            model_key=model_key,
            force=force,
            knowledge_object_ids=await self.repository.list_knowledge_object_ids(organisation=organisation),
        )

    async def queue_audience(self, *, audience: str, version_label: str | None = None, model_key: str | None = None, force: bool = False) -> dict:
        return await self._queue_scope(
            scope_key="audience",
            scope_value=audience,
            version_label=version_label,
            model_key=model_key,
            force=force,
            knowledge_object_ids=await self.repository.list_knowledge_object_ids(audience=audience),
        )

    async def queue_age_group(self, *, age_group: str, version_label: str | None = None, model_key: str | None = None, force: bool = False) -> dict:
        return await self._queue_scope(
            scope_key="age_group",
            scope_value=age_group,
            version_label=version_label,
            model_key=model_key,
            force=force,
            knowledge_object_ids=await self.repository.list_knowledge_object_ids(age_group=age_group),
        )

    async def queue_all(self, *, version_label: str | None = None, model_key: str | None = None, force: bool = False) -> dict:
        return await self._queue_scope(
            scope_key="corpus",
            scope_value="all",
            version_label=version_label,
            model_key=model_key,
            force=force,
            knowledge_object_ids=await self.repository.list_knowledge_object_ids(),
        )

    async def rebuild(self, *, version_label: str, model_key: str | None = None, topic: str | None = None, organisation: str | None = None, audience: str | None = None, age_group: str | None = None, force: bool = True) -> dict:
        knowledge_object_ids = await self.repository.list_knowledge_object_ids(
            topic=topic,
            organisation=organisation,
            audience=audience,
            age_group=age_group,
        )
        context = await self._ensure_context(version_label=version_label, model_key=model_key)
        queued = await self.queue.enqueue(
            knowledge_object_ids=knowledge_object_ids,
            model=context.model,
            version=context.version,
            job_type=JobType.REBUILD.value,
            scope_key="rebuild",
            scope_value=topic or organisation or audience or age_group or "all",
            force=force,
            max_attempts=self.settings.embedding_job_max_attempts,
        )
        return {
            "queued_jobs": queued,
            "model_key": context.spec.key,
            "version_label": context.version.version_label,
            "scope": "rebuild",
        }

    async def retry_failed(self, *, limit: int) -> int:
        return await self.repository.retry_failed_jobs(limit=limit)

    async def run(self, *, limit: int, worker_name: str, version_label: str | None = None, model_key: str | None = None) -> dict:
        context = await self._ensure_context(version_label=version_label, model_key=model_key)
        provider = self._provider_for(context.spec)
        jobs = await self.queue.lease(
            worker_name=worker_name,
            limit=limit,
            lease_seconds=self.settings.embedding_worker_lease_seconds,
            model=context.model,
            version=context.version,
        )
        report = await EmbeddingJobRunner(self.repository, provider, settings=self.settings).process_jobs(
            jobs,
            model=context.model,
            version=context.version,
        )
        await self.statistics_service.snapshot(model_id=context.model.id, version_id=context.version.id)
        return {
            "leased_jobs": report.leased_jobs,
            "completed_jobs": report.completed_jobs,
            "failed_jobs": report.failed_jobs,
            "retried_jobs": report.retried_jobs,
            "skipped_jobs": report.skipped_jobs,
            "worker_name": worker_name,
            "model_key": context.spec.key,
            "version_label": context.version.version_label,
        }

    async def status(self) -> dict:
        counts = await self.repository.status_counts()
        recent_jobs = await self.repository.list_recent_jobs()
        return {
            "pending": counts["pending"],
            "processing": counts["processing"],
            "completed": counts["completed"],
            "failed": counts["failed"],
            "cancelled": counts["cancelled"],
            "retry": counts["retry"],
            "active_model_key": self.settings.active_model.key,
            "active_version": self.settings.embedding_active_version,
            "recent_jobs": recent_jobs,
        }

    async def statistics(self) -> dict:
        return await self.statistics_service.snapshot()

    async def models(self) -> list[dict]:
        usage = {item["model_key"]: item["usage_count"] for item in await self.repository.list_models_with_usage()}
        models: list[dict] = []
        for spec in self.settings.model_catalog:
            hydrated = self.settings._hydrate_model_spec(spec)
            models.append(
                {
                    "model_key": hydrated.key,
                    "provider_name": hydrated.provider_name,
                    "provider_type": hydrated.provider_type,
                    "model_name": hydrated.model_name,
                    "dimensions": hydrated.dimensions,
                    "is_active": hydrated.key == self.settings.active_model.key,
                    "api_key_configured": bool(self.settings.api_key_for(hydrated) or hydrated.provider_type == "local_deterministic"),
                    "usage_count": usage.get(hydrated.key, 0),
                }
            )
        return models

    async def _queue_scope(self, *, scope_key: str, scope_value: str, version_label: str | None, model_key: str | None, force: bool, knowledge_object_ids: list[UUID]) -> dict:
        context = await self._ensure_context(version_label=version_label, model_key=model_key)
        job_type_by_scope = {
            "topic": JobType.TOPIC.value,
            "organisation": JobType.ORGANISATION.value,
            "audience": JobType.AUDIENCE.value,
            "age_group": JobType.AGE_GROUP.value,
            "corpus": JobType.CORPUS.value,
        }
        queued = await self.queue.enqueue(
            knowledge_object_ids=knowledge_object_ids,
            model=context.model,
            version=context.version,
            job_type=job_type_by_scope.get(scope_key, JobType.OBJECT.value),
            scope_key=scope_key,
            scope_value=scope_value,
            force=force,
            max_attempts=self.settings.embedding_job_max_attempts,
        )
        return {
            "queued_jobs": queued,
            "model_key": context.spec.key,
            "version_label": context.version.version_label,
            "scope": scope_key,
        }

    async def _ensure_context(self, *, version_label: str | None, model_key: str | None) -> QueueContext:
        spec = self._select_model_spec(model_key)
        model = await self.repository.ensure_model(spec, active=(spec.key == self.settings.active_model.key))
        version = await self.repository.ensure_version(
            model=model,
            version_label=version_label or self.settings.embedding_active_version,
            content_schema_version=self.settings.embedding_content_schema_version,
            activate=True,
        )
        return QueueContext(spec=spec, model=model, version=version)

    def _select_model_spec(self, model_key: str | None) -> EmbeddingModelSpec:
        target_key = model_key or self.settings.active_model.key
        for spec in self.settings.model_catalog:
            if spec.key == target_key:
                return self.settings._hydrate_model_spec(spec)
        raise ValidationError(f"Unknown embedding model key: {target_key}")

    def _provider_for(self, spec: EmbeddingModelSpec) -> EmbeddingProvider:
        if spec.provider_type == "local_deterministic":
            return DeterministicEmbeddingProvider(dimensions=spec.dimensions)
        if spec.provider_type in {"openai", "openai_compatible", "local_http"}:
            return OpenAICompatibleProvider(spec=spec, settings=self.settings)
        raise ValidationError(f"Unsupported provider type: {spec.provider_type}")
