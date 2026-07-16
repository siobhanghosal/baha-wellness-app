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
7. LLM reasoning: a Buddy generation layer that uses OpenAI for final answer generation while staying grounded in locally retrieved BAHA evidence and safety guardrails.
8. API: FastAPI endpoints for search, views, resources, interventions, conditions, and chat.
9. Dashboard: analytics services for source coverage, condition coverage, retrieval quality, freshness, and embedding statistics.

## Why These Components

PostgreSQL is selected because the project needs durable metadata, version history, auditability, full-text search, and analytics in one operational store. pgvector adds dense retrieval without introducing a second database during the first production phase. FastAPI gives typed request and response contracts for product, dashboard, and integration teams. BGE large English embeddings are a strong open model for retrieval quality while keeping deployment options flexible.

## Quick Start

Default local backend for Flutter and mobile API work:

```bash
cp .env.example .env
docker compose -f docker-compose.yml up --build
```

The API will be available at `http://localhost:8000`.
The local Postgres port exposed on the host is `5433`.

This default runtime is intentionally lightweight:

- `EMBEDDING_BACKEND=hash`
- no `torch`
- no `sentence-transformers`
- no acquisition-only crawler and document-processing dependencies

If you need the full acquisition and retrieval runtime locally, use:

```bash
docker build -f Dockerfile.full -t baha_data-api:full .
```

If you want the stronger Buddy demo runtime against the imported Solomon corpus, use:

```bash
docker compose -f docker-compose.yml -f docker-compose.buddy-demo.yml up --build
```

That keeps the same database but switches the API container to the full retrieval runtime and `EMBEDDING_BACKEND=bge`.
If you previously started the Buddy demo override and want to go back to the lighter mobile/API runtime, recreate the API with:

```bash
docker compose -f docker-compose.yml up -d --build --force-recreate api
```

For Android emulator testing, use `http://10.0.2.2:8000` as the API base URL.
For a physical device on the same network, use your machine's LAN IP instead of `localhost`.

Current mobile prototype note:

- the live Flutter demo is now one unified app at `Baha_Mobile/apps/student_app`
- role-specific student, guardian, teacher, and counselor experiences are routed inside that single app
- separate Flutter app shells are no longer part of the active demo architecture

For local syntax checks without installing dependencies:

```bash
python3 -m compileall src tests
```

Buddy note:

- retrieval stays local to the BAHA Postgres/pgvector stack
- the final answer-generation step now runs through OpenAI only
- `BUDDY_GENERATION_BACKEND` remains fixed to `openai`
- the default configured model string is now `gpt-5-nano`
- Buddy now synthesizes a short remembered session context from recent user turns so it can carry forward simple facts inside one conversation
- Buddy now uses two OpenAI-backed reply modes under one server-side safety layer:
  - conversational OpenAI replies for greetings, venting, and general supportive conversation
  - retrieval-grounded OpenAI replies for advice-style wellbeing questions where approved BAHA evidence is useful
- Buddy now adapts reply style by student age cohort:
  - `9_12` gets shorter, simpler, less abstract replies
  - `13_14` gets plain, easy-to-follow language
  - `15_18` and `18_plus` get slightly more nuance while staying concise
- the hard scope gate is now softened:
  - weak or missing retrieval falls back to conversational OpenAI instead of a cold refusal
  - only emergency handling stays strictly server-controlled
- the mobile runtime now also exposes `POST /mobile/chat/sessions/{session_id}/messages/stream`
  - this lets the Flutter Buddy UI render the assistant reply progressively while the backend is still receiving deltas from OpenAI
  - the final assistant message is still persisted normally at the end of the stream
- actual OpenAI model availability should still be verified against the specific API account being used

Current demo-facing mobile UX improvements:

- the student home dashboard stays in a real empty state until live check-in data exists
- once data exists, the dashboard adds narrative callouts:
  - `What changed`
  - `What improved`
  - `What to watch`
  - `What to try next`
- the student dashboard now labels the combined chart as `Overall pulse`
  - it uses real submission dates on the x-axis
  - it explains that higher points mean higher combined strain across tracked factors
  - it is powered only by actual check-ins, not placeholder graph lines
- the student wellbeing model is now framed in product language as:
  - sleep
  - energy
  - mood
  - stress
  - physical symptoms
  - support
- daily check-in wording is now age-adapted across `9_12`, `13_14`, `15_18`, and `18_plus`
- the post-check-in result view now shows a short personalized takeaway based on today's factors versus recent averages
- dashboard and insight surfaces now trim recent check-ins to the latest three entries instead of rendering a long history block
- student discovery is now clearly separated into `Learning` and `Activities`
- the student app now also includes a first real `9_12` learning-lane slice:
  - child-facing topic cards instead of only the older teen theme cards
  - topic-level progress rollup
  - saved practice tools inside the lane
  - soft badge/reward states instead of heavy gamification
  - `3` ordered modules per `9_12` topic across:
    - Sleep
    - Stress
    - Bullying
    - Healthy Gaming
    - Alcohol Safety
- the parent weekly summary now includes a privacy-safe response layer with:
  - `What changed`
  - `Conversation starter`
  - `What to watch next week`
  - `Support action to try`

If a currently running local API returns `404` for the new Buddy stream route after pulling these changes, it usually means the old container/process is still running. Recreate the API container:

```bash
docker compose -f docker-compose.yml up -d --build --force-recreate api
```

Optional branch artifact note:

- the `Solomon_RAG_Vector_DB` branch includes an LFS-tracked Postgres dump at `backups/baha_rag_20260714-183725.dump`
- that dump is useful as a restore/import source for retrieval experiments, but it is not required by the current backend runtime and was not made a boot-time dependency
- the current local workflow for using that donor corpus is documented in [docs/BUDDY_DEMO_RAG_SETUP.md](/Users/sudharshan/Desktop/PES/RF%20Internship/Baha_Data/docs/BUDDY_DEMO_RAG_SETUP.md)

Local database note:

- if you already have an existing local Postgres volume, newly added SQL seed or migration files may not appear automatically just from rebuilding containers
- in that case, either reinitialize the local database volume or apply the new SQL manually against the running local database
- this mattered for the newer learning and onboarding seed slices such as:
  - `028_age_9_12_learning_lanes.sql`
  - `029_multi_cohort_learning_refresh.sql`
  - `030_dashboard_showcase_seed.sql`
  - `031_student_linking_and_learning_depth.sql`
  - `032_fix_guardian_demo_password.sql`

## Safety Contract

Every answer is composed from retrieved evidence. The system always includes citations, avoids diagnostic language, avoids clinical treatment instructions, and recommends urgent local emergency or crisis support when emergency indicators appear.

## Documentation

See [docs/ARCHITECTURE.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/ARCHITECTURE.md) for the full system design, deployment model, and implementation roadmap.

See [docs/DATA_ACQUISITION.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/DATA_ACQUISITION.md) for the complete acquisition platform: Scrapy discovery, research downloaders, raw storage, update detection, source inventory, and clinical review queue.

See [docs/PRODUCT_DATA_ARCHITECTURE.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/PRODUCT_DATA_ARCHITECTURE.md) for the recommended product-facing data architecture: evidence layers, content publishing, operational app data, graph usage, and app-ready read models.

See [docs/SCHEMA_IMPLEMENTATION_PLAN.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/SCHEMA_IMPLEMENTATION_PLAN.md) for the recommended implementation order, core table groups, migration sequence, and the next concrete data tasks.

See [docs/DATABASE_SETUP_AND_DEPLOYMENT.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/DATABASE_SETUP_AND_DEPLOYMENT.md) for local database startup, migration validation, and production PostgreSQL deployment guidance.

See [docs/FLUTTER_BACKEND_DELIVERY_PLAN.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/FLUTTER_BACKEND_DELIVERY_PLAN.md) for the recommended mobile-client architecture, local Android testing rules, and the cloud deployment path for Flutter apps.

See [docs/MOBILE_API_SURFACES.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/MOBILE_API_SURFACES.md) for the first mobile-facing backend routes, temporary request identity model, and the Flutter integration contract.

See [docs/HOSTING_COST_AND_SCALE.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/HOSTING_COST_AND_SCALE.md) for the current repository data footprint, free-tier fit check, and a practical first-pass hosting cost and scale estimate.

See [docs/BACKEND_HANDOFF_FOR_FLUTTER.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/BACKEND_HANDOFF_FOR_FLUTTER.md) for the practical backend handoff reference: local URLs, demo identities, seeded data, and the implemented mobile API surfaces.

See [docs/ACCOUNT_ONBOARDING_SYSTEM.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/ACCOUNT_ONBOARDING_SYSTEM.md) for the current users-based onboarding model, approval workflow, guardian linking flow, and guardian-managed consent behavior for both platform participation and parent summaries.

See [docs/STUDENT_CHECKIN_PROFILE_LOGIC.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/STUDENT_CHECKIN_PROFILE_LOGIC.md) for the current student onboarding baseline, adaptive daily check-in logic, scoring model, and trend/risk interpretation rules.

See [docs/STUDENT_DEMO_SCENARIOS.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/STUDENT_DEMO_SCENARIOS.md) for the seeded student demo accounts, sign-in identities, and the narrative each one is intended to demonstrate on the dashboard.

See [docs/AGE_9_12_CONTENT_DELIVERY_BLUEPRINT.md](/Users/sudharshan/Desktop/PES/RF%20Internship/Baha_Data/docs/AGE_9_12_CONTENT_DELIVERY_BLUEPRINT.md) for the concrete plan for turning the new `9-12` content sample into topic lanes, micro-modules, practice interactions, and soft reward loops.

See [docs/ENVIRONMENT_AND_SECRETS.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/ENVIRONMENT_AND_SECRETS.md) for the runtime configuration, hosted auth variables, and object-storage environment contract.

See [docs/DATA_ACQUISITION.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/DATA_ACQUISITION.md) for when to use the heavier acquisition/runtime profile instead of the default lightweight mobile API runtime.

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
