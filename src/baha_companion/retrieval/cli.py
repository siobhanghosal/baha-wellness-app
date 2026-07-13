from __future__ import annotations

import argparse
import asyncio
import json
from pathlib import Path

from baha_companion.database.session import get_session_factory
from baha_companion.embeddings.config import get_embedding_settings
from baha_companion.retrieval.config import get_retrieval_settings
from baha_companion.retrieval.models import BenchmarkCase, RetrievalFilters
from baha_companion.retrieval.repository import RetrievalRepository
from baha_companion.retrieval.service import RetrievalService


def build_service(session) -> RetrievalService:
    return RetrievalService(
        RetrievalRepository(session),
        retrieval_settings=get_retrieval_settings(),
        embedding_settings=get_embedding_settings(),
    )


def build_filters(args: argparse.Namespace) -> RetrievalFilters:
    return RetrievalFilters(
        topic=getattr(args, "topic", None),
        audience=getattr(args, "audience", None),
        organisation=getattr(args, "organisation", None),
    )


async def run_retrieve(args: argparse.Namespace, *, debug: bool = False) -> None:
    async with get_session_factory()() as session:
        payload = await build_service(session).retrieve(
            query=args.query,
            filters=build_filters(args),
            top_k=args.top_k,
            debug=debug,
        )
        print(json.dumps(payload, indent=2, default=str))


async def run_retrieve_topic(args: argparse.Namespace) -> None:
    async with get_session_factory()() as session:
        payload = await build_service(session).retrieve_by_topic(
            topic=args.topic,
            query=args.query,
            top_k=args.top_k,
        )
        print(json.dumps(payload, indent=2, default=str))


async def run_retrieve_organisation(args: argparse.Namespace) -> None:
    async with get_session_factory()() as session:
        payload = await build_service(session).retrieve_by_organisation(
            organisation=args.organisation,
            query=args.query,
            top_k=args.top_k,
        )
        print(json.dumps(payload, indent=2, default=str))


async def run_benchmark(args: argparse.Namespace) -> None:
    payload = json.loads(Path(args.case_file).read_text(encoding="utf-8"))
    cases = [
        BenchmarkCase(
            name=item["name"],
            query=item["query"],
            expected_ids=item.get("expected_ids", []),
            expected_titles=item.get("expected_titles", []),
            filters=RetrievalFilters(**item.get("filters", {})),
            top_k=item.get("top_k", 5),
        )
        for item in payload["cases"]
    ]
    async with get_session_factory()() as session:
        result = await build_service(session).benchmark(cases=cases)
        print(json.dumps(result, indent=2, default=str))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="baha-companion-retrieval")
    subparsers = parser.add_subparsers(dest="command", required=True)

    retrieve_parser = subparsers.add_parser("retrieve")
    retrieve_parser.add_argument("query")
    retrieve_parser.add_argument("--top-k", type=int, default=5)
    retrieve_parser.add_argument("--topic")
    retrieve_parser.add_argument("--audience")
    retrieve_parser.add_argument("--organisation")

    retrieve_debug_parser = subparsers.add_parser("retrieve-debug")
    retrieve_debug_parser.add_argument("query")
    retrieve_debug_parser.add_argument("--top-k", type=int, default=5)
    retrieve_debug_parser.add_argument("--topic")
    retrieve_debug_parser.add_argument("--audience")
    retrieve_debug_parser.add_argument("--organisation")

    retrieve_topic_parser = subparsers.add_parser("retrieve-topic")
    retrieve_topic_parser.add_argument("topic")
    retrieve_topic_parser.add_argument("--query", default="")
    retrieve_topic_parser.add_argument("--top-k", type=int, default=5)

    retrieve_organisation_parser = subparsers.add_parser("retrieve-organisation")
    retrieve_organisation_parser.add_argument("organisation")
    retrieve_organisation_parser.add_argument("--query", default="")
    retrieve_organisation_parser.add_argument("--top-k", type=int, default=5)

    benchmark_parser = subparsers.add_parser("retrieve-benchmark")
    benchmark_parser.add_argument("case_file")
    return parser


def main() -> None:
    args = build_parser().parse_args()
    if args.command == "retrieve":
        asyncio.run(run_retrieve(args))
    elif args.command == "retrieve-debug":
        asyncio.run(run_retrieve(args, debug=True))
    elif args.command == "retrieve-topic":
        asyncio.run(run_retrieve_topic(args))
    elif args.command == "retrieve-organisation":
        asyncio.run(run_retrieve_organisation(args))
    elif args.command == "retrieve-benchmark":
        asyncio.run(run_benchmark(args))
