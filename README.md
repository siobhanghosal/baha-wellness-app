# BAHA Wellness Companion RAG Platform

This repository implements the backend knowledge platform for the BAHA Wellness Companion: an evidence-bound Retrieval-Augmented Generation system for adolescent wellbeing, life skills, sleep, digital wellness, substance awareness, nutrition, physical activity, and social wellbeing.

The platform is deliberately designed to avoid diagnosis, clinical treatment, or suicide-risk prediction. It retrieves from approved sources, returns citations, encourages professional consultation, and flags emergencies.

## Architecture

The implementation follows nine layers:

1. Data collection: approved-source web, PDF, research, guideline, and educational ingestion.
2. Data processing: boilerplate removal, metadata extraction, reference capture, table placeholders, deduplication, and chunking.
3. Metadata enrichment: taxonomy mapping, audience, severity, country, language, and evidence-level fields.
4. Embedding: `BAAI/bge-large-en-v1.5` through `sentence-transformers`, with a deterministic hash backend for local tests.
5. Vector database: PostgreSQL plus pgvector, full-text indexes, versioned documents, chunks, embeddings, citations, and taxonomy.
6. Retrieval: dense vector search, PostgreSQL full-text lexical search, metadata filters, knowledge-graph expansion, source-diverse reranking, and weighted confidence scoring.
7. LLM reasoning: evidence-bounded response composer with safety guardrails and citation-only answers.
8. API: FastAPI endpoints for search, views, resources, interventions, conditions, and chat.
9. Dashboard: analytics services for source coverage, condition coverage, retrieval quality, freshness, and embedding statistics.

## Why These Components

PostgreSQL is selected because the project needs durable metadata, version history, auditability, full-text search, and analytics in one operational store. pgvector adds dense retrieval without introducing a second database during the first production phase. FastAPI gives typed request and response contracts for product, dashboard, and integration teams. BGE large English embeddings are a strong open model for retrieval quality while keeping deployment options flexible.

## Quick Start

```bash
cp .env.example .env
docker compose up --build
```

The API will be available at `http://localhost:8000`.

For local syntax checks without installing dependencies:

```bash
python3 -m compileall src tests
```

## Safety Contract

Every answer is composed from retrieved evidence. The system always includes citations, avoids diagnostic language, avoids clinical treatment instructions, and recommends urgent local emergency or crisis support when emergency indicators appear.

## Documentation

See [docs/ARCHITECTURE.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/ARCHITECTURE.md) for the full system design, deployment model, and implementation roadmap.

See [docs/DATA_ACQUISITION.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/DATA_ACQUISITION.md) for the complete acquisition platform: Scrapy discovery, research downloaders, raw storage, update detection, source inventory, and clinical review queue.

The acquisition platform includes a BAHA/IAP-first manual ingestion module for PDF, DOCX,
PPTX, transcript, bulk-directory, and ZIP imports, plus priority coverage dashboards and
weekly gap-closure reporting.

## Tier-3 Acquisition And Embeddings

Discover and acquire one approved Tier-3 organization at a time:

```bash
PYTHONPATH=src .venv/bin/python -m baha_rag.cli discover-documents --organization CDC
PYTHONPATH=src EMBEDDING_AUTO_INDEX=false .venv/bin/python -m baha_rag.cli \
  download-documents --organization CDC --limit 500
```

Activate incremental BGE embeddings for accepted resources, condition profiles,
and knowledge graph nodes:

```bash
PYTHONPATH=src EMBEDDING_BACKEND=bge .venv/bin/python -m baha_rag.cli \
  activate-embeddings --resource-limit 100000 --condition-limit 1000 \
  --knowledge-limit 100000
```

After the first full population, apply
`migrations/012_rebuild_vector_indexes.sql`, then generate the reports:

```bash
PYTHONPATH=src .venv/bin/python -m baha_rag.cli embedding-report
PYTHONPATH=src EMBEDDING_BACKEND=bge .venv/bin/python -m baha_rag.cli \
  evaluate-retrieval --top-k 10
```

## OpenAI RAG Chatbot

The `/chat` endpoint now uses retrieval from PostgreSQL/pgvector and sends the
grounded evidence to the OpenAI Responses API for the final answer. Configure an
API key and model in `.env`:

```bash
OPENAI_API_KEY=your_api_key_here
OPENAI_CHAT_MODEL=gpt-5.4-nano
```

Start the API:

```bash
PYTHONPATH=src .venv/bin/uvicorn baha_rag.app:app --reload
```

Example chat request:

```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "How can a parent support a teenager with exam stress?",
    "audience": "parent",
    "top_k": 6
  }'
```

You can also test it from the terminal:

```bash
PYTHONPATH=src .venv/bin/python -m baha_rag.cli chat \
  --audience parent \
  "How can I support a teenager with exam stress?"
```
