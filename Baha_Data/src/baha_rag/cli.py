from __future__ import annotations

import argparse
import asyncio
import json
from datetime import date
from pathlib import Path


async def ingest_url(args: argparse.Namespace) -> None:
    from baha_rag.config import get_settings
    from baha_rag.db.session import SessionLocal
    from baha_rag.embeddings.bge import EmbeddingService
    from baha_rag.ingestion.pipeline import IngestionPipeline

    async with SessionLocal() as session:
        pipeline = IngestionPipeline(session, EmbeddingService(get_settings()))
        response = await pipeline.ingest_url(
            url=args.url,
            organization=args.organization,
            audience=args.audience,
            country=args.country,
            evidence_level=args.evidence_level,
        )
        await session.commit()
        print(response.model_dump_json(indent=2))


async def seed_acquisition_sources() -> None:
    from baha_rag.acquisition.service import AcquisitionService
    from baha_rag.config import get_settings
    from baha_rag.db.session import SessionLocal

    async with SessionLocal() as session:
        service = AcquisitionService(session, get_settings())
        count = await service.seed_sources()
        await session.commit()
        print(f"seeded_sources={count}")


async def discover_research(args: argparse.Namespace) -> None:
    from baha_rag.acquisition.service import AcquisitionService
    from baha_rag.config import get_settings
    from baha_rag.db.session import SessionLocal

    async with SessionLocal() as session:
        service = AcquisitionService(session, get_settings())
        count = await service.discover_research(
            limit_per_topic=args.limit_per_topic,
            queries=args.query,
        )
        await session.commit()
        print(f"research_candidates={count}")


async def download_candidates(args: argparse.Namespace) -> None:
    from baha_rag.acquisition.service import AcquisitionService
    from baha_rag.config import get_settings
    from baha_rag.db.session import SessionLocal

    async with SessionLocal() as session:
        service = AcquisitionService(session, get_settings())
        result = await service.download_due_candidates(
            limit=args.limit,
            resource_type=args.resource_type,
            organization=args.organization,
        )
        await session.commit()
        print(result)


async def acquisition_report() -> None:
    from baha_rag.acquisition.service import AcquisitionService
    from baha_rag.config import get_settings
    from baha_rag.db.session import SessionLocal

    async with SessionLocal() as session:
        service = AcquisitionService(session, get_settings())
        print(await service.final_report())

async def phase_report(args: argparse.Namespace) -> None:
    from baha_rag.acquisition.service import AcquisitionService
    from baha_rag.config import get_settings
    from baha_rag.db.session import SessionLocal

    async with SessionLocal() as session:
        report = await AcquisitionService(session, get_settings()).phase_report()
        await session.commit()
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2, default=str))
    print(json.dumps(report, indent=2, default=str))

async def activate_embeddings(args: argparse.Namespace) -> None:
    from baha_rag.config import get_settings
    from baha_rag.db.session import SessionLocal
    from baha_rag.embeddings.indexer import IncrementalEmbeddingIndexer

    async with SessionLocal() as session:
        indexer = IncrementalEmbeddingIndexer(session, get_settings())
        report = await indexer.index(
            resource_limit=args.resource_limit,
            condition_limit=args.condition_limit,
            knowledge_limit=args.knowledge_limit,
        )
        report["index"] = await indexer.report()
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2, default=str))
    print(json.dumps(report, indent=2, default=str))


async def embedding_report(args: argparse.Namespace) -> None:
    from baha_rag.config import get_settings
    from baha_rag.db.session import SessionLocal
    from baha_rag.embeddings.indexer import IncrementalEmbeddingIndexer

    async with SessionLocal() as session:
        report = await IncrementalEmbeddingIndexer(session, get_settings()).report()
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2, default=str))
    print(json.dumps(report, indent=2, default=str))


async def evaluate_retrieval(args: argparse.Namespace) -> None:
    from baha_rag.config import get_settings
    from baha_rag.db.repository import KnowledgeRepository
    from baha_rag.db.session import SessionLocal
    from baha_rag.embeddings.bge import EmbeddingService
    from baha_rag.retrieval.evaluation import RetrievalEvaluator
    from baha_rag.retrieval.hybrid import HybridRetriever

    settings = get_settings()
    async with SessionLocal() as session:
        retriever = HybridRetriever(
            KnowledgeRepository(session),
            EmbeddingService(settings),
        )
        report = await RetrievalEvaluator(retriever).run(top_k=args.top_k)
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2, default=str))
    print(json.dumps(report, indent=2, default=str))


async def backfill_extraction(args: argparse.Namespace) -> None:
    from baha_rag.acquisition.service import AcquisitionService
    from baha_rag.config import get_settings
    from baha_rag.db.session import SessionLocal

    async with SessionLocal() as session:
        result = await AcquisitionService(session, get_settings()).backfill_quality_and_extraction(
            limit=args.limit,
            force=args.force,
            organization=args.organization,
        )
        await session.commit()
        print(result)


async def coverage_gaps() -> None:
    from baha_rag.acquisition.service import AcquisitionService
    from baha_rag.config import get_settings
    from baha_rag.db.session import SessionLocal

    async with SessionLocal() as session:
        result = await AcquisitionService(session, get_settings()).coverage_gaps()
        await session.commit()
        print(result)


async def embedding_readiness() -> None:
    from baha_rag.acquisition.service import AcquisitionService
    from baha_rag.config import get_settings
    from baha_rag.db.session import SessionLocal

    async with SessionLocal() as session:
        result = await AcquisitionService(session, get_settings()).embedding_readiness()
        await session.commit()
        print(result)


async def discover_gap_research(args: argparse.Namespace) -> None:
    from baha_rag.acquisition.service import AcquisitionService
    from baha_rag.config import get_settings
    from baha_rag.db.session import SessionLocal

    async with SessionLocal() as session:
        result = await AcquisitionService(session, get_settings()).discover_gap_research(
            limit_per_query=args.limit_per_query,
            max_topics=args.max_topics,
        )
        await session.commit()
        print(result)


async def manual_import(args: argparse.Namespace) -> None:
    from baha_rag.acquisition.manual_ingestion import (
        ManualResourceIngestionService,
        ManualResourceMetadata,
    )
    from baha_rag.config import get_settings
    from baha_rag.db.session import SessionLocal

    publication_date = date.fromisoformat(args.publication_date) if args.publication_date else None
    async with SessionLocal() as session:
        service = ManualResourceIngestionService(session, get_settings().storage_root)
        result = await service.import_paths(
            args.paths,
            ManualResourceMetadata(
                organization=args.organization,
                reviewer=args.reviewer,
                source=args.source,
                publication_date=publication_date,
                topic=args.topic,
                audience=args.audience,
                title=args.title,
                language=args.language,
            ),
        )
        await session.commit()
        print(result)


async def priority_dashboard() -> None:
    from baha_rag.acquisition.service import AcquisitionService
    from baha_rag.config import get_settings
    from baha_rag.db.session import SessionLocal

    async with SessionLocal() as session:
        print(await AcquisitionService(session, get_settings()).priority_dashboard())


async def priority_gap_closure(args: argparse.Namespace) -> None:
    from baha_rag.acquisition.gap_closure import PriorityGapClosureEngine
    from baha_rag.db.session import SessionLocal

    async with SessionLocal() as session:
        result = await PriorityGapClosureEngine(session).plan(max_topics=args.max_topics)
        await session.commit()
        print(result)
        if args.exit_when_complete and result["targets_met"]:
            raise SystemExit(20)


async def weekly_priority_gap_report() -> None:
    from baha_rag.acquisition.gap_closure import PriorityGapClosureEngine
    from baha_rag.db.session import SessionLocal

    async with SessionLocal() as session:
        result = await PriorityGapClosureEngine(session).weekly_report()
        await session.commit()
        print(result)


async def priority_campaign_report() -> None:
    from baha_rag.acquisition.campaign import PriorityCampaignService
    from baha_rag.db.session import SessionLocal

    async with SessionLocal() as session:
        print(await PriorityCampaignService(session).report())


async def life_skills_campaign_report(args: argparse.Namespace) -> None:
    from baha_rag.acquisition.life_skills_campaign import LifeSkillsCampaignReporter
    from baha_rag.db.session import SessionLocal

    async with SessionLocal() as session:
        report = await LifeSkillsCampaignReporter(session).report()
        await session.commit()
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2, default=str))
    coverage_output = output.with_name("life-skills-coverage-report.json")
    gap_output = output.with_name("life-skills-gap-closure-report.json")
    coverage_output.write_text(
        json.dumps(report["topic_coverage"], indent=2, default=str)
    )
    gap_output.write_text(
        json.dumps(
            {
                "remaining_above_ten_percent": report["remaining_above_ten_percent"],
                "all_gaps_below_ten_percent": report["all_gaps_below_ten_percent"],
                "generated_at": report["generated_at"],
            },
            indent=2,
            default=str,
        )
    )
    print(json.dumps(report, indent=2, default=str))


def main() -> None:
    parser = argparse.ArgumentParser(prog="baha-rag")
    subcommands = parser.add_subparsers(dest="command", required=True)
    ingest = subcommands.add_parser("ingest-url")
    ingest.add_argument("url")
    ingest.add_argument("--organization", required=True)
    ingest.add_argument("--audience", default="general")
    ingest.add_argument("--country")
    ingest.add_argument("--evidence-level", default="unknown")
    subcommands.add_parser("seed-sources")
    subcommands.add_parser("seed-acquisition-sources")
    scrapy = subcommands.add_parser("discover-documents")
    scrapy.add_argument("--organization")
    scrapy_alias = subcommands.add_parser("discover-web")
    scrapy_alias.add_argument("--organization")
    research = subcommands.add_parser("discover-research")
    research.add_argument("--limit-per-topic", type=int, default=25)
    research.add_argument("--query", action="append")
    download = subcommands.add_parser("download-documents")
    download.add_argument("--limit", type=int, default=100)
    download.add_argument("--resource-type")
    download.add_argument("--organization")
    download_alias = subcommands.add_parser("download-candidates")
    download_alias.add_argument("--limit", type=int, default=100)
    download_alias.add_argument("--resource-type")
    download_alias.add_argument("--organization")
    download_research = subcommands.add_parser("download-research")
    download_research.add_argument("--limit", type=int, default=100)
    subcommands.add_parser("generate-report")
    subcommands.add_parser("acquisition-report")
    backfill = subcommands.add_parser("backfill-extraction")
    backfill.add_argument("--limit", type=int, default=1000)
    backfill.add_argument("--force", action="store_true")
    backfill.add_argument("--organization")
    subcommands.add_parser("coverage-gaps")
    subcommands.add_parser("embedding-readiness")
    gap_research = subcommands.add_parser("discover-gap-research")
    gap_research.add_argument("--limit-per-query", type=int, default=25)
    gap_research.add_argument("--max-topics", type=int, default=10)
    manual = subcommands.add_parser("manual-import")
    manual.add_argument("paths", nargs="+")
    manual.add_argument("--organization", required=True)
    manual.add_argument("--reviewer", required=True)
    manual.add_argument("--source", default="BAHA/IAP manual library")
    manual.add_argument("--publication-date")
    manual.add_argument("--topic")
    manual.add_argument(
        "--audience",
        choices=["parent", "teacher", "counselor", "adolescent", "administrator", "general"],
        default="general",
    )
    manual.add_argument("--title")
    manual.add_argument("--language", default="en")
    subcommands.add_parser("priority-dashboard")
    gap_closure = subcommands.add_parser("priority-gap-closure")
    gap_closure.add_argument("--max-topics", type=int, default=9)
    gap_closure.add_argument("--exit-when-complete", action="store_true")
    subcommands.add_parser("weekly-gap-report")
    campaign_discovery = subcommands.add_parser("discover-priority-campaign")
    campaign_discovery.add_argument(
        "--organization",
        choices=["AHA", "NIMHANS"],
        required=True,
    )
    campaign_download = subcommands.add_parser("download-priority-campaign")
    campaign_download.add_argument("--organization", choices=["AHA", "NIMHANS"])
    campaign_download.add_argument("--limit", type=int, default=1000)
    subcommands.add_parser("priority-campaign-report")
    life_discovery = subcommands.add_parser("discover-life-skills-campaign")
    life_discovery.add_argument("--organization")
    life_download = subcommands.add_parser("download-life-skills-campaign")
    life_download.add_argument("--organization")
    life_download.add_argument("--limit", type=int, default=1000)
    life_report = subcommands.add_parser("life-skills-campaign-report")
    life_report.add_argument(
        "--output",
        default="storage/reports/life-skills-campaign-report.json",
    )
    phase = subcommands.add_parser("phase-report")
    phase.add_argument("--output", default="storage/reports/phase-report.json")
    activate = subcommands.add_parser("activate-embeddings")
    activate.add_argument("--resource-limit", type=int, default=100000)
    activate.add_argument("--condition-limit", type=int, default=1000)
    activate.add_argument("--knowledge-limit", type=int, default=100000)
    activate.add_argument("--output", default="storage/reports/embedding-report.json")
    embedding_stats = subcommands.add_parser("embedding-report")
    embedding_stats.add_argument("--output", default="storage/reports/vector-index-report.json")
    retrieval_eval = subcommands.add_parser("evaluate-retrieval")
    retrieval_eval.add_argument("--top-k", type=int, default=10)
    retrieval_eval.add_argument("--output", default="storage/reports/retrieval-quality-report.json")
    args = parser.parse_args()
    if args.command == "ingest-url":
        asyncio.run(ingest_url(args))
    elif args.command in {"seed-sources", "seed-acquisition-sources"}:
        asyncio.run(seed_acquisition_sources())
    elif args.command in {"discover-documents", "discover-web"}:
        from baha_rag.acquisition.runner import run_scrapy_discovery

        run_scrapy_discovery(organization=args.organization)
    elif args.command == "discover-research":
        asyncio.run(discover_research(args))
    elif args.command in {"download-documents", "download-candidates"}:
        asyncio.run(download_candidates(args))
    elif args.command == "download-research":
        args.resource_type = "research_paper"
        args.organization = None
        asyncio.run(download_candidates(args))
    elif args.command in {"generate-report", "acquisition-report"}:
        asyncio.run(acquisition_report())
    elif args.command == "backfill-extraction":
        asyncio.run(backfill_extraction(args))
    elif args.command == "coverage-gaps":
        asyncio.run(coverage_gaps())
    elif args.command == "embedding-readiness":
        asyncio.run(embedding_readiness())
    elif args.command == "discover-gap-research":
        asyncio.run(discover_gap_research(args))
    elif args.command == "manual-import":
        asyncio.run(manual_import(args))
    elif args.command == "priority-dashboard":
        asyncio.run(priority_dashboard())
    elif args.command == "priority-gap-closure":
        asyncio.run(priority_gap_closure(args))
    elif args.command == "weekly-gap-report":
        asyncio.run(weekly_priority_gap_report())
    elif args.command == "discover-priority-campaign":
        from baha_rag.acquisition.runner import run_scrapy_discovery

        organization = (
            "IAP Adolescent Health Academy"
            if args.organization == "AHA"
            else args.organization
        )
        run_scrapy_discovery(organization=organization, campaign=True)
    elif args.command == "download-priority-campaign":
        args.resource_type = None
        args.organization = (
            "IAP Adolescent Health Academy"
            if args.organization == "AHA"
            else args.organization
        )
        asyncio.run(download_candidates(args))
    elif args.command == "priority-campaign-report":
        asyncio.run(priority_campaign_report())
    elif args.command == "discover-life-skills-campaign":
        from baha_rag.acquisition.runner import run_scrapy_discovery

        run_scrapy_discovery(
            organization=args.organization,
            campaign="life-skills",
        )
    elif args.command == "download-life-skills-campaign":
        args.resource_type = None
        asyncio.run(download_candidates(args))
    elif args.command == "life-skills-campaign-report":
        asyncio.run(life_skills_campaign_report(args))
    elif args.command == "phase-report":
        asyncio.run(phase_report(args))
    elif args.command == "activate-embeddings":
        asyncio.run(activate_embeddings(args))
    elif args.command == "embedding-report":
        asyncio.run(embedding_report(args))
    elif args.command == "evaluate-retrieval":
        asyncio.run(evaluate_retrieval(args))


if __name__ == "__main__":
    main()
