from __future__ import annotations

import argparse
import asyncio
import json
from pathlib import Path

from baha_companion.database.session import get_session_factory
from baha_companion.knowledge.classifiers import (
    AudienceClassifier,
    AgeClassifier,
    DemographicClassifier,
    EvidenceClassifier,
    PriorityAssigner,
    ReadingLevelClassifier,
    TopicClassifier,
)
from baha_companion.knowledge.duplicates import DuplicateDetectionService
from baha_companion.knowledge.normalization import KnowledgeNormalizationService
from baha_companion.knowledge.repository import KnowledgeRepository
from baha_companion.knowledge.schemas import ProcessBatchRequest, ProcessDocumentRequest
from baha_companion.knowledge.segmentation import DocumentSegmentationService
from baha_companion.knowledge.service import KnowledgeProcessingService
from baha_companion.knowledge.quality import QualityService


def build_service(session) -> KnowledgeProcessingService:
    return KnowledgeProcessingService(
        KnowledgeRepository(session),
        workspace_root=Path.cwd(),
        normalization_service=KnowledgeNormalizationService(),
        segmentation_service=DocumentSegmentationService(),
        topic_classifier=TopicClassifier(),
        audience_classifier=AudienceClassifier(),
        age_classifier=AgeClassifier(),
        evidence_classifier=EvidenceClassifier(),
        demographic_classifier=DemographicClassifier(),
        priority_assigner=PriorityAssigner(),
        reading_level_classifier=ReadingLevelClassifier(),
        quality_service=QualityService(),
        duplicate_detection_service=DuplicateDetectionService(),
    )


async def run_process_document(args: argparse.Namespace) -> None:
    async with get_session_factory()() as session:
        service = build_service(session)
        result = await service.process_document(
            ProcessDocumentRequest(
                path=args.path,
                organization=args.organization,
                document_url=args.document_url,
                publication_date=args.publication_date,
                country=args.country,
                language=args.language,
                overwrite=args.overwrite,
            )
        )
        await session.commit()
        print(result.model_dump_json(indent=2))


async def run_process_folder(args: argparse.Namespace) -> None:
    async with get_session_factory()() as session:
        service = build_service(session)
        result = await service.process_batch(
            ProcessBatchRequest(
                root_path=args.root_path,
                limit=args.limit,
                organization=args.organization,
                overwrite=args.overwrite,
            )
        )
        await session.commit()
        print(result.model_dump_json(indent=2))


async def run_reprocess(args: argparse.Namespace) -> None:
    args.overwrite = True
    await run_process_folder(args)


async def run_quality_report() -> None:
    async with get_session_factory()() as session:
        report = await build_service(session).quality_report()
        print(json.dumps(report, indent=2, default=str))


async def run_duplicate_report() -> None:
    async with get_session_factory()() as session:
        statistics = await build_service(session).statistics()
        print(json.dumps({"duplicate_summary": statistics["quality_distribution"]}, indent=2, default=str))


async def run_statistics() -> None:
    async with get_session_factory()() as session:
        report = await build_service(session).statistics()
        print(json.dumps(report, indent=2, default=str))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="baha-companion-knowledge")
    subparsers = parser.add_subparsers(dest="command", required=True)

    process_document = subparsers.add_parser("process-document")
    process_document.add_argument("path")
    process_document.add_argument("--organization")
    process_document.add_argument("--document-url")
    process_document.add_argument("--publication-date")
    process_document.add_argument("--country")
    process_document.add_argument("--language")
    process_document.add_argument("--overwrite", action="store_true")

    process_folder = subparsers.add_parser("process-folder")
    process_folder.add_argument("root_path", nargs="?", default="storage/raw")
    process_folder.add_argument("--limit", type=int)
    process_folder.add_argument("--organization")
    process_folder.add_argument("--overwrite", action="store_true")

    reprocess = subparsers.add_parser("reprocess")
    reprocess.add_argument("root_path", nargs="?", default="storage/raw")
    reprocess.add_argument("--limit", type=int)
    reprocess.add_argument("--organization")
    reprocess.add_argument("--overwrite", action="store_true")

    subparsers.add_parser("quality-report")
    subparsers.add_parser("duplicate-report")
    subparsers.add_parser("statistics")
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    if args.command == "process-document":
        asyncio.run(run_process_document(args))
    elif args.command == "process-folder":
        asyncio.run(run_process_folder(args))
    elif args.command == "reprocess":
        asyncio.run(run_reprocess(args))
    elif args.command == "quality-report":
        asyncio.run(run_quality_report())
    elif args.command == "duplicate-report":
        asyncio.run(run_duplicate_report())
    elif args.command == "statistics":
        asyncio.run(run_statistics())

