# BAHA RAG And Pipeline Summary

This document captures what has been completed for the BAHA Wellness Companion backend RAG stack, from corpus acquisition through retrieval and LLM orchestration.

## Current Corpus State

- Raw source corpus on disk: `8,664` files under `storage/raw` excluding `.DS_Store`, across `23` source buckets.
- Documented ingestion inventory:
  - `8,869` total acquired records
  - `8,026` accepted resources
  - `843` rejected resources
  - `8,670` raw files retained

## What Has Been Built

### 1. Data Acquisition And Corpus Curation

- Source discovery, crawling, downloading, and deduplication pipelines are in place.
- Approved public health, education, and wellbeing sources were collected and retained with provenance.
- Quality gates preserve accepted and rejected records, hashes, source URLs, and extraction outputs.
- Inventory and storage reports document corpus state and source coverage.

### 2. Knowledge Processing Pipeline

- Document parsing supports HTML, PDF, JSON, DOCX, markdown, and text inputs.
- Normalization, segmentation, quality scoring, duplicate detection, and classification are implemented.
- Metadata extraction covers topic, audience, age group, gender, evidence level, organization, language, and priority.
- Knowledge objects are stored in a structured relational schema for downstream retrieval.

### 3. Embedding Pipeline

- Embedding jobs, queues, statistics, and versioned model tracking are implemented.
- The pipeline supports incremental embedding updates rather than full rebuilds.
- Vector storage is wired for current and historical embeddings.
- Automatic embedding can be controlled through configuration.

### 4. Hybrid Retrieval Engine

- Retrieval combines metadata filtering, BM25 scoring, vector similarity, and reranking.
- Query understanding expands and normalizes user intent before search.
- Candidate scoring uses relevance, priority, evidence, recency, and reranker weights.
- Retrieval output is structured for downstream LLM context assembly.

### 5. Backend Foundation

- FastAPI application structure, dependency injection, and router composition are implemented.
- PostgreSQL-compatible SQLAlchemy models and Alembic migrations are in place.
- JWT authentication supports register, login, refresh, logout, session handling, and password reset flows.
- Security controls include request context logging, security headers, rate limiting, CORS, trusted hosts, and validation handling.

### 6. Chat And Conversation Storage

- Conversation and message persistence are implemented with UUID primary keys, timestamps, soft delete support, and relationships.
- Conversation CRUD, message storage, and message pagination are available.
- Chat persistence is prepared for future summarization and retrieval-driven assistant responses.

### 7. LLM Orchestration Layer

- A dedicated `llm/` package was added for production-grade generation orchestration.
- GPT-4o mini is integrated through the official OpenAI SDK with lazy import handling.
- Model settings are configurable and future models can be added without code changes.
- The orchestration pipeline now includes:
  - user question
  - conversation context
  - hybrid retrieval
  - context composition
  - prompt building
  - OpenAI generation
  - response validation
  - streaming
  - conversation storage
- Prompt templates are profile-aware for student, parent, teacher, counsellor, and administrator use cases.
- Context composition deduplicates and ranks retrieved evidence before it reaches the model.
- Responses are validated for citations, unsafe advice, and weak evidence conditions.
- Token and cost tracking are stored per assistant message.

## API Surface

Implemented chat and LLM endpoints include:

- `POST /chat`
- `POST /chat/stream`
- `POST /chat/regenerate`
- `POST /chat/stop`
- `GET /chat/models`
- `GET /chat/statistics`

Existing backend surfaces remain available for auth, users, conversations, retrieval, embeddings, knowledge, and health checks.

## Operational Features

- Structured JSON logging includes request ID, user ID, conversation ID, latency, response size, warnings, and errors.
- Environment-driven configuration supports development, testing, staging, and production settings.
- Docker and Compose support are included for local and deployable backend runs.
- OpenAPI documentation is generated from FastAPI schemas and request/response models.

## Testing And Verification

- Backend tests cover authentication, chat, retrieval, knowledge pipeline, migrations, and the new LLM orchestration layer.
- The latest verification run completed with `49` passing backend tests and `91%` total backend coverage.

## Intentionally Not Included

- Flutter frontend implementation
- Story Engine
- Games
- Behaviour analytics
- Long-term memory systems
- Vector search or RAG changes outside the existing retrieval pipeline

## Bottom Line

The backend is now ready as a production-oriented RAG and LLM foundation for the BAHA Wellness Companion. The corpus pipeline, retrieval stack, chat persistence, and GPT-4o mini orchestration are connected end to end, with testing and observability already in place.
