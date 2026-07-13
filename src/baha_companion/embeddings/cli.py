from __future__ import annotations

import argparse
import asyncio
import json
from uuid import UUID

from baha_companion.database.session import get_session_factory
from baha_companion.embeddings.config import get_embedding_settings
from baha_companion.embeddings.repository import EmbeddingRepository
from baha_companion.embeddings.service import EmbeddingService


def build_service(session) -> EmbeddingService:
    return EmbeddingService(EmbeddingRepository(session), settings=get_embedding_settings())


async def embed_object(args: argparse.Namespace) -> None:
    async with get_session_factory()() as session:
        service = build_service(session)
        result = await service.queue_object(
            knowledge_object_id=UUID(args.knowledge_object_id),
            version_label=args.version_label,
            model_key=args.model_key,
            force=args.force,
        )
        if args.run:
            await session.commit()
            result = await service.run(
                limit=max(1, args.run_limit),
                worker_name="cli-embed-object",
                version_label=args.version_label,
                model_key=args.model_key,
            )
        await session.commit()
        print(json.dumps(result, indent=2, default=str))


async def embed_scope(command: str, value: str | None, args: argparse.Namespace) -> None:
    async with get_session_factory()() as session:
        service = build_service(session)
        if command == "embed-topic":
            result = await service.queue_topic(topic=value or "", version_label=args.version_label, model_key=args.model_key, force=args.force)
        elif command == "embed-organisation":
            result = await service.queue_organisation(organisation=value or "", version_label=args.version_label, model_key=args.model_key, force=args.force)
        elif command == "embed-age":
            result = await service.queue_age_group(age_group=value or "", version_label=args.version_label, model_key=args.model_key, force=args.force)
        elif command == "embed-audience":
            result = await service.queue_audience(audience=value or "", version_label=args.version_label, model_key=args.model_key, force=args.force)
        elif command == "embed-all":
            result = await service.queue_all(version_label=args.version_label, model_key=args.model_key, force=args.force)
        else:  # pragma: no cover - defensive guard
            raise ValueError(f"Unsupported command: {command}")
        if getattr(args, "run", False):
            await session.commit()
            result = await service.run(
                limit=max(1, args.run_limit),
                worker_name=f"cli-{command}",
                version_label=args.version_label,
                model_key=args.model_key,
            )
        await session.commit()
        print(json.dumps(result, indent=2, default=str))


async def rebuild_embeddings(args: argparse.Namespace) -> None:
    async with get_session_factory()() as session:
        result = await build_service(session).rebuild(
            version_label=args.version_label,
            model_key=args.model_key,
            topic=args.topic,
            organisation=args.organisation,
            audience=args.audience,
            age_group=args.age_group,
            force=True,
        )
        await session.commit()
        print(json.dumps(result, indent=2, default=str))


async def retry_failed(args: argparse.Namespace) -> None:
    async with get_session_factory()() as session:
        service = build_service(session)
        retried = await service.retry_failed(limit=args.limit)
        await session.commit()
        print(json.dumps({"queued_jobs": retried}, indent=2, default=str))


async def embedding_status() -> None:
    async with get_session_factory()() as session:
        result = await build_service(session).status()
        print(json.dumps(result, indent=2, default=str))


async def embedding_report() -> None:
    async with get_session_factory()() as session:
        result = await build_service(session).statistics()
        print(json.dumps(result, indent=2, default=str))


def parser_with_common_flags(subparser) -> None:
    subparser.add_argument("--version-label")
    subparser.add_argument("--model-key")
    subparser.add_argument("--force", action="store_true")
    subparser.add_argument("--run", action="store_true")
    subparser.add_argument("--run-limit", type=int, default=100)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="baha-companion-embeddings")
    subparsers = parser.add_subparsers(dest="command", required=True)

    embed_object_parser = subparsers.add_parser("embed-object")
    embed_object_parser.add_argument("knowledge_object_id")
    parser_with_common_flags(embed_object_parser)

    embed_topic_parser = subparsers.add_parser("embed-topic")
    embed_topic_parser.add_argument("topic")
    parser_with_common_flags(embed_topic_parser)

    embed_org_parser = subparsers.add_parser("embed-organisation")
    embed_org_parser.add_argument("organisation")
    parser_with_common_flags(embed_org_parser)

    embed_age_parser = subparsers.add_parser("embed-age")
    embed_age_parser.add_argument("age_group")
    parser_with_common_flags(embed_age_parser)

    embed_audience_parser = subparsers.add_parser("embed-audience")
    embed_audience_parser.add_argument("audience")
    parser_with_common_flags(embed_audience_parser)

    embed_all_parser = subparsers.add_parser("embed-all")
    parser_with_common_flags(embed_all_parser)

    rebuild_parser = subparsers.add_parser("rebuild-embeddings")
    rebuild_parser.add_argument("--version-label", default="v1")
    rebuild_parser.add_argument("--model-key")
    rebuild_parser.add_argument("--topic")
    rebuild_parser.add_argument("--organisation")
    rebuild_parser.add_argument("--audience")
    rebuild_parser.add_argument("--age-group")

    retry_parser = subparsers.add_parser("retry-failed")
    retry_parser.add_argument("--limit", type=int, default=100)

    subparsers.add_parser("embedding-status")
    subparsers.add_parser("embedding-report")
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    if args.command == "embed-object":
        asyncio.run(embed_object(args))
    elif args.command in {"embed-topic", "embed-organisation", "embed-age", "embed-audience", "embed-all"}:
        value = getattr(args, "topic", None) or getattr(args, "organisation", None) or getattr(args, "age_group", None) or getattr(args, "audience", None)
        asyncio.run(embed_scope(args.command, value, args))
    elif args.command == "rebuild-embeddings":
        asyncio.run(rebuild_embeddings(args))
    elif args.command == "retry-failed":
        asyncio.run(retry_failed(args))
    elif args.command == "embedding-status":
        asyncio.run(embedding_status())
    elif args.command == "embedding-report":
        asyncio.run(embedding_report())
