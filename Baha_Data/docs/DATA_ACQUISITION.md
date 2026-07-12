# BAHA Data Acquisition Platform

## Goal

The acquisition platform discovers, downloads, updates, classifies, stores, and queues approved adolescent wellbeing resources for clinical review before they enter the RAG knowledge base.

## Services

- Source Registry Service: canonical approved organizations, domains, seed URLs, country, rate limits, and robots.txt policy.
- Web Crawler Service: Scrapy spider for approved source domains with robots.txt compliance, AutoThrottle, retry handling, rate limiting, and depth limits.
- PDF Downloader: async HTTP downloader with content hashing, metadata extraction, and storage.
- Research Paper Downloader: PubMed, Europe PMC, and Semantic Scholar discovery with resource download support.
- Dataset Downloader: CSV, XLSX, ZIP, and other dataset artifact storage.
- Metadata Extraction Pipeline: title, author, publication date, language, topic, subtopic, organization, country, URL, source, and resource type.
- Duplicate Detection: normalized URL keys, SHA-256 content hashes, and text fingerprints.
- Incremental Update Detection: content hash, ETag, and Last-Modified checks.
- Storage Service: deterministic raw file storage under `STORAGE_ROOT`.
- Clinical Review Queue: downloaded resources must be approved before downstream RAG ingestion.
- Priority Acquisition: BAHA, IAP, NIMHANS, WHO, UNICEF, and UNESCO are ranked in that order for candidate download and gap closure.
- Manual Resource Ingestion: PDFs, DOCX, PPTX, transcripts, directories, and safe ZIP archives enter through an audited review path under `STORAGE_ROOT/manual_resource_ingestion`.
- Curated HTML Snapshot Ingestion: reviewed `.html` and `.htm` source snapshots can also be manually imported for retrieval demos and future curated knowledge workflows.

## Approved Sources

The source registry includes WHO, UNICEF, UNESCO, NIMHANS, Indian Academy of Pediatrics, NCERT, CBSE, NCPCR, Ministry of Health and Family Welfare, NICE, NHS, CDC, SAMHSA, American Academy of Pediatrics, PubMed, Europe PMC, and Semantic Scholar.

## Topics

Discovery covers adolescent mental health, anxiety, depression, stress, bullying, cyberbullying, sleep, digital wellness, social wellbeing, life skills, nutrition, physical activity, and substance abuse.

## Database

The acquisition schema is implemented in [002_acquisition.sql](/Users/solomonkaruppiah/Desktop/Baha_Data/migrations/002_acquisition.sql).

Main tables:

- `acquisition_sources`: approved source registry.
- `acquisition_candidates`: discovered URLs awaiting download.
- `acquired_resources`: downloaded files and metadata.
- `resource_duplicates`: duplicate relationships.
- `acquisition_jobs`: discovery and download job status.
- `clinical_review_queue`: review workflow before RAG ingestion.
- `priority_sources`: canonical BAHA/IAP-first source ranking.
- `manual_ingestion_batches` and `manual_resource_ingestion`: reviewer-attributed manual upload audit trail.
- `priority_gap_targets` and `priority_gap_searches`: persisted gap closure targets and approved-source search plans.
- `weekly_priority_gap_reports`: weekly BAHA/IAP coverage snapshots and deficits.
- `discovered_urls`, `downloaded_documents`, `datasets`, `research_papers`, `metadata`, `crawl_jobs`, and `review_queue`: reporting views matching the external data-acquisition contract.
- `crawl_logs`: operational crawl logs.

## API

- `POST /admin/acquisition/sources/seed`: seed approved sources into PostgreSQL.
- `POST /admin/acquisition/research/discover`: discover PubMed, Europe PMC, and Semantic Scholar candidates.
- `POST /admin/acquisition/download`: download due candidates.
- `GET /admin/acquisition/inventory`: source inventory dashboard data.
- `GET /admin/acquisition/report`: final acquisition report with totals, source coverage, topic coverage, and missing topics.
- `GET /admin/acquisition/review-queue`: pending clinical review items.
- `POST /admin/acquisition/review-queue/{review_id}`: approve, reject, or request changes.
- `POST /admin/acquisition/manual`: multipart upload for PDF, DOCX, PPTX, transcript, and ZIP resources.
- `GET /admin/acquisition/priority-dashboard`: BAHA and IAP coverage by topic and audience.
- `POST /admin/acquisition/gap-closure`: persist a priority-ordered approved-source search plan.
- `GET /admin/acquisition/weekly-gap-report`: generate and persist the current weekly report.

## CLI Jobs

```bash
baha-rag seed-sources
baha-rag discover-documents
baha-rag discover-documents --organization WHO
baha-rag discover-research --limit-per-topic 25
baha-rag download-documents --limit 500
baha-rag download-research --limit 500
baha-rag generate-report
baha-rag manual-import ./resources --organization BAHA --reviewer "Reviewer Name" \
  --source "BAHA library" --audience parent --topic anxiety
baha-rag manual-import ./iap-pdfs --organization IAP --reviewer "Reviewer Name"
baha-rag manual-import ./curated-html --organization "Common Sense Media" --reviewer "Reviewer Name" \
  --source "Buddy demo shortlist" --audience adolescent --topic "digital wellness"
baha-rag priority-dashboard
baha-rag priority-gap-closure --max-topics 9
baha-rag weekly-gap-report
```

Manual uploads preserve the original binary. HTML snapshots, DOCX and PPTX Open XML content, and supplied
`.txt`, `.md`, `.vtt`, or `.srt` transcripts are extracted locally. The module does not
transcribe raw video media; a human- or system-produced transcript must be supplied.

ZIP imports reject traversal paths, archives with more than 500 files, members larger than
250 MiB, and expanded archives larger than 1 GiB.

## Docker

Default `docker compose up --build` is now optimized for the Flutter/mobile API handoff, not for acquisition-heavy admin operations.

That default runtime:

- uses the lightweight `Dockerfile`
- keeps `EMBEDDING_BACKEND=hash`
- omits acquisition-only crawler and document-processing dependencies

If you need the full acquisition runtime locally, build:

```bash
docker build -f Dockerfile.full -t baha_data-api:full .
```

or install the full dependency set directly in a Python environment.

The heavier acquisition endpoints return `503` in the lightweight runtime instead of crashing the API process.

For the lightweight mobile/backend runtime:

```bash
cp .env.example .env
docker compose up --build
```

The compose deployment starts PostgreSQL with pgvector, initializes migrations, runs the API, and stores raw acquisition files in the `acquisition-storage` volume.

## Kubernetes

The Kubernetes manifests include:

- API deployment and service.
- PersistentVolumeClaim for raw storage.
- Web discovery CronJob.
- Research discovery CronJob.
- Candidate download CronJob.
- ConfigMap and Secret examples.

For production, use managed PostgreSQL, object storage instead of a node-local PVC, NetworkPolicies, ExternalSecrets, and private container registry images.

## Final Report

`GET /admin/acquisition/report` returns:

- `total_documents_downloaded`
- `total_pdfs`
- `total_research_papers`
- `total_datasets`
- `sources_with_downloads`
- `covered_topics`
- `source_coverage`
- `country_coverage`
- `condition_coverage`
- `missing_topics`
- `generated_at`
