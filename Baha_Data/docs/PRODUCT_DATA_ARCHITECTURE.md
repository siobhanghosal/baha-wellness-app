# BAHA Product Data Architecture

## 1. Purpose

This document defines how BAHA data should be organized for:

- future app development
- runtime use by the Student, Parent, Teacher, and BAHA/Counselor apps
- content operations and clinical review
- analytics, reporting, and pilot evaluation
- long-term maintainability without repeatedly reprocessing the full corpus

It builds on the current `Baha_Data` platform and recommends a hybrid model:

- relational system of record for operational app data
- curated knowledge base for reviewed evidence and content sources
- vector retrieval layer for search and chatbot grounding
- knowledge graph layer for relationships and explainability
- object storage for raw and versioned source assets

This is not a recommendation to immediately delete or move the current raw data. It is a target architecture and operating model for organizing it cleanly over time.

For the student-facing learning transformation of this corpus into app material,
see:

- [STUDENT_LEARNING_CONTENT_STRATEGY.md](./STUDENT_LEARNING_CONTENT_STRATEGY.md)

## 1.1 Current Physical Repo Layout

The current `Baha_Data/` folder is about `4.5G` locally and is organized into a few distinct physical areas:

- `storage/raw/`
  This is the main raw source corpus. It is organized first by source/provider name, then by hashed bucket folders for large-volume storage fanout.
- `storage/reports/`
  Generated reports and intermediate output artifacts.
- `migrations/`
  PostgreSQL schema and seed data for the operational and content-serving backend.
- `src/baha_rag/`
  The backend application code, including ingestion, retrieval, embeddings, API routes, and database access layers.
- `docs/`
  Product, architecture, deployment, and handoff documentation.
- `.venv/` and `.pytest_cache/`
  Local development/runtime artifacts, not product data.

So in practical terms:

- the actual source data primarily lives under `storage/raw/`
- the app/runtime database shape lives under `migrations/`
- the product logic that consumes curated database data lives under `src/baha_rag/`
- the documentation describing the intended long-term organization lives under `docs/`

Important current constraint:

- the large raw corpus exists on disk, but the live mobile backend serves only
  the curated publishable content layer
- that is intentional and should remain the product-serving model

Important current runtime status:

- the local backend currently has product content for app screens
- but the retrieval-backed chatbot knowledge index is still effectively unpopulated
- that means BAHA Buddy can now run through the local LLM architecture, but it will correctly stay in scope-guard mode until approved corpus material is imported and indexed into the retrieval tables

For the first Buddy retrieval activation pass, do **not** point the chatbot at the full raw corpus immediately.

Use a curated demo subset first:

- [BUDDY_DEMO_CORPUS_SHORTLIST.md](./BUDDY_DEMO_CORPUS_SHORTLIST.md)
- [BUDDY_DEMO_QUESTION_BANK.md](./BUDDY_DEMO_QUESTION_BANK.md)

That shortlist-first pattern should become the default operating model for future retrieval rollouts too:

- shortlist
- import
- index
- evaluate
- only then widen corpus coverage

## 2. Design Principles

### 2.1 Separate evidence from product content

Source material, cleaned knowledge, and app-facing content should not live in the same conceptual layer.

- A source PDF is not a student learning card.
- A reviewed research paper is not a parent conversation guide.
- A chunk used for retrieval is not a publishable chatbot answer.

### 2.2 Keep transactional data relational

User records, consents, check-ins, progress, game sessions, pastoral flags, and cases should be stored as normalized relational data. These are operational workflows, not graph-first workflows.

### 2.3 Use the graph for relationships, not everything

A knowledge graph is useful for relationship-rich knowledge such as:

- condition -> symptom
- condition -> intervention
- topic -> learning module
- escalation indicator -> support action
- student-facing topic -> parent guide -> teacher view

It is not the right primary store for:

- user accounts
- notification queues
- session state
- consent logs
- analytics events

### 2.4 Preserve provenance

Every app-facing content artifact should trace back to:

- one or more reviewed source documents
- a reviewer
- a review date
- an activation state

### 2.5 Publish content through governed layers

The apps should consume only publishable, reviewed content. The apps should not directly consume raw acquisition output.

### 2.6 Optimize for four separate apps

The data model should assume separate apps for:

- Student
- Parent
- Teacher
- BAHA/Counselor

The backend should support distinct read models and permissions for each.

### 2.7 Keep mobile apps API-first

The Flutter apps should consume HTTPS APIs, not direct database connections.

That means:

- PostgreSQL remains a backend system of record
- consent and privacy logic stays server-side
- app-specific UI can evolve without exposing internal tables to clients
- the same backend can later support Android and iOS consistently

### 2.8 Target hosted shape

The current recommended hosted backend shape is:

- FastAPI backend hosted as a containerized API service
- managed PostgreSQL with `pgvector` as the system of record and retrieval store
- object storage for raw source files and larger media assets

Current preferred vendor split:

- Supabase for PostgreSQL
- Render for API hosting
- Cloudflare R2 as an optional raw-file storage optimization

External cloud credentials should be provisioned later, after the remaining backend implementation work is complete.

## 3. External Patterns Used

The recommendations in this document are consistent with patterns from primary sources:

- Microsoft guidance on advanced RAG emphasizes metadata-rich chunking, hierarchical retrieval, alignment optimization, and staged update strategies:
  <https://learn.microsoft.com/en-us/azure/developer/ai/advanced-retrieval-augmented-generation>
- Microsoft guidance on RAG retrieval architecture emphasizes metadata storage, chunk optimization, versioning, and retrieval pipelines:
  <https://learn.microsoft.com/en-us/azure/architecture/ai-ml/guide/rag/rag-information-retrieval>
- Weaviate documentation reinforces explicit filtering and metadata-aware retrieval rather than pure vector lookup:
  <https://docs.weaviate.io/weaviate/search/filters>
- Neo4j’s graph-RAG and multi-hop material is useful for relationship-heavy reasoning and explainable traversal:
  <https://neo4j.com/developer-blog/knowledge-graphs-llms-multi-hop-question-answering/>
- HL7 FHIR Consent is a useful reference point for treating consent as a first-class, versioned, auditable record:
  <https://build.fhir.org/consent.html>

These sources should inform the architecture, but the BAHA product should remain simpler than a full medical-record system.

## 4. Recommended Logical Data Layers

The product should be organized into five logical layers.

### 4.1 Layer A: Source Corpus

Purpose:

- retain original source files
- preserve provenance
- allow reprocessing when chunking, taxonomy, or extraction logic changes

Examples:

- PDFs
- HTML snapshots
- PPTX uploads
- CSV/XLSX datasets
- manual uploads from BAHA

Current mapping:

- `storage/raw/*`
- `acquired_resources`
- `document_versions`

Storage recommendation:

- object storage or existing raw-storage path
- immutable or append-only where practical

### 4.2 Layer B: Curated Knowledge Base

Purpose:

- convert raw evidence into reviewed, searchable knowledge
- support citations, retrieval, and downstream content creation

Examples:

- cleaned resources
- chunks
- citations
- taxonomy tags
- condition profiles
- embeddings
- quality and review status

Current mapping:

- `documents`
- `chunks`
- `embeddings`
- `citations`
- `condition_profiles`
- `resource_chunks`
- `resource_embeddings`
- `condition_embeddings`

Storage recommendation:

- PostgreSQL + pgvector

### 4.3 Layer C: Product Content Layer

Purpose:

- store app-ready content that is safe to publish
- decouple mobile apps from raw evidence structures

Examples:

- student learning modules
- parent guides
- teacher awareness content
- counselor quick-reference content
- safe questions and approved answers
- game scenarios
- challenge templates
- conversation guides
- escalation copy
- onboarding and privacy copy

Current mapping:

- partially implied by current PRD and RAG content flow
- not yet modeled as a distinct first-class content publishing layer

Storage recommendation:

- PostgreSQL for metadata and publish states
- object storage for assets

### 4.4 Layer D: Operational App Data

Purpose:

- support actual app usage
- track privacy, consent, progression, and safety operations

Examples:

- users and roles
- student profiles
- guardian relationships
- school and class structure
- consent records
- check-ins
- module progress
- chatbot sessions
- game sessions
- pastoral flags
- escalation cases
- notifications

Current mapping:

- not yet modeled in the current `Baha_Data` repo

Storage recommendation:

- PostgreSQL as the system of record

### 4.5 Layer E: Analytics and Derived Signals

Purpose:

- generate dashboards, pilot metrics, and trend summaries
- keep expensive analytics queries off core runtime paths

Examples:

- weekly parent summaries
- teacher cohort trends
- BAHA pilot dashboards
- retrieval quality evaluation
- topic coverage
- escalation false-positive review
- content usage metrics

Current mapping:

- `retrieval_events`
- `topic_coverage`
- `retrieval_evaluation_*`
- `daily_acquisition_reports`
- `storage/reports/*`

Storage recommendation:

- PostgreSQL summary tables now
- event pipeline or warehouse later if scale demands it

## 5. Recommended Product Data Domains

The logical layers above should be implemented through distinct data domains.

### 5.1 Knowledge Domain

Owns:

- approved sources
- acquired resources
- raw file provenance
- cleaned chunks
- taxonomy
- condition profiles
- citations
- embeddings

Primary consumers:

- BAHA Buddy
- content admins
- retrieval pipeline
- analytics

### 5.2 Content Domain

Owns:

- safe questions
- approved answers
- learning modules
- quizzes
- game scenario definitions
- challenge definitions
- conversation guides
- escalation copy
- content versioning and review workflow

Primary consumers:

- Student App
- Parent App
- Teacher App
- BAHA/Counselor App

### 5.3 Identity and Consent Domain

Owns:

- stakeholder accounts
- role assignments
- student-guardian links
- school associations
- consent versions
- assent records
- privacy-tier settings
- override logs

Primary consumers:

- all apps
- audit layer
- escalation workflows

### 5.4 Student Wellness Domain

Owns:

- student profile
- age cohort
- preference state
- weekly check-ins
- reflections
- trend summaries
- streaks
- badges
- challenge enrollments
- game-derived signals

Primary consumers:

- Student App
- analytics
- escalation rules

### 5.5 Support and Safeguarding Domain

Owns:

- help requests
- pastoral flags
- escalation rules
- acute disclosures
- case assignments
- case notes
- closure states
- override events

Primary consumers:

- BAHA/Counselor App
- Teacher App
- notification workflows

### 5.6 Analytics Domain

Owns:

- app event metrics
- cohort summaries
- pilot dashboards
- retrieval-quality metrics
- content performance metrics
- intervention-effectiveness aggregates

Primary consumers:

- BAHA/Counselor App
- internal reporting

## 6. Knowledge Graph Recommendation

### 6.1 Short answer

Yes, use a knowledge graph.

### 6.2 But use it as a semantic layer

The graph should sit on top of curated knowledge and product content. It should not replace relational storage for the operational app.

### 6.3 Why it helps this product

This product has many relationship-heavy questions:

- which student-facing topics map to parent guidance?
- which topics should appear for a given age cohort?
- which learning cards support a specific trend or concern?
- which game scenarios reinforce a specific life skill?
- which symptoms or indicators are linked to an escalation pathway?
- which sources justify a chatbot answer?

Those are graph-shaped questions.

### 6.4 Why it should not be the center of everything

The main runtime behaviors are still transactional:

- login
- consent capture
- check-in submission
- module progress
- case creation
- notification dispatch

That is relational, not graph-native.

### 6.5 Recommended graph scope

Use graph nodes for:

- `Condition`
- `Theme`
- `Topic`
- `Subtopic`
- `Symptom`
- `RiskFactor`
- `ProtectiveFactor`
- `Intervention`
- `EscalationIndicator`
- `Audience`
- `AgeCohort`
- `ContentItem`
- `LearningModule`
- `SafeQuestion`
- `GameScenario`
- `Challenge`
- `SourceDocument`

Use graph edges for:

- `has_symptom`
- `has_risk_factor`
- `has_protective_factor`
- `supports`
- `escalate_if`
- `recommended_for_audience`
- `recommended_for_age_cohort`
- `derived_from`
- `cites`
- `related_to`
- `teaches`
- `reinforces`
- `visible_in_app`

### 6.6 Recommended technology choice

Do not introduce a separate graph database yet.

Reason:

- the current platform already has `knowledge_graph_nodes` and `knowledge_graph_edges`
- the product is still early
- a second operational datastore adds complexity

Recommendation:

- keep the graph in PostgreSQL first
- use the existing graph tables
- add stricter node and edge typing
- add graph-building jobs from curated content
- revisit dedicated graph tooling only if traversal-heavy workloads become a bottleneck

## 7. Recommended Storage Pattern

### 7.1 PostgreSQL

Use as the main operational store for:

- app data
- content metadata
- review state
- graph nodes and edges
- analytics summary tables

### 7.2 pgvector

Use for:

- chunk retrieval
- approved answer retrieval
- semantic content recommendations
- graph-node embeddings where helpful

### 7.3 Object storage

Use for:

- original source files
- derived binary assets
- large reports
- media attached to modules or games

### 7.4 JSONB

Use for:

- flexible metadata
- extraction output
- app-specific presentation metadata

Do not use JSONB as an excuse to avoid schema design for core workflows.

### 7.5 Event log

Optional now, useful later.

Eventually use an append-only event table for:

- check-in submitted
- consent changed
- chatbot answer delivered
- case escalated
- module completed
- badge awarded

This will simplify analytics and auditability.

## 8. Recommended Schema Strategy

### 8.1 Keep the existing corpus schema

The current acquisition and retrieval tables are directionally correct and should be retained.

### 8.2 Add a first-class product content schema

Recommended core tables:

- `content_items`
- `content_versions`
- `content_assets`
- `content_citations`
- `content_review_queue`
- `safe_questions`
- `safe_question_answers`
- `learning_modules`
- `learning_module_steps`
- `quizzes`
- `quiz_items`
- `game_scenarios`
- `challenge_templates`
- `copy_blocks`

Recommended `content_items` fields:

- `id`
- `content_type`
- `audience_app`
- `age_cohort`
- `theme`
- `topic`
- `subtopic`
- `language`
- `status`
- `review_status`
- `reviewed_by`
- `reviewed_at`
- `effective_from`
- `effective_to`
- `risk_level`
- `consent_sensitivity`
- `source_document_ids`

### 8.3 Add operational app schemas

Recommended domain tables:

Identity and consent:

- `users`
- `student_profiles`
- `guardians`
- `student_guardian_links`
- `schools`
- `classes`
- `teacher_assignments`
- `consent_records`
- `consent_versions`
- `privacy_tier_settings`
- `override_events`

Student wellness:

- `checkin_templates`
- `checkin_response_sets`
- `checkin_responses`
- `trend_snapshots`
- `reflection_entries`
- `challenge_enrollments`
- `challenge_progress`
- `badge_awards`
- `game_sessions`
- `game_behavioral_signals`

Current implementation note:

- the adaptive student daily check-in now lives primarily in `checkin_templates`, `checkin_response_sets`, and `checkin_responses`
- one-time wellbeing profile answers are currently stored locally in the mobile app until a dedicated backend profile write model is introduced

Support and safeguarding:

- `help_requests`
- `pastoral_flags`
- `monitoring_signals`
- `escalation_cases`
- `case_events`
- `case_assignments`
- `case_notes`
- `support_contacts`

Learning and chatbot:

- `module_progress`
- `quiz_attempts`
- `chat_sessions`
- `chat_messages`
- `chat_answer_citations`

### 8.4 Add analytics summary tables

Recommended summary tables:

- `student_weekly_summaries`
- `parent_weekly_summaries`
- `teacher_cohort_summaries`
- `baha_pilot_dashboard_metrics`
- `retrieval_quality_snapshots`
- `content_usage_snapshots`
- `escalation_review_metrics`

## 9. Recommended Folder Organization

This does not require immediate destructive movement of current files. It is the target logical layout.

```text
Baha_Data/
  docs/
    PRODUCT_DATA_ARCHITECTURE.md
    DATA_COLLECTION_INVENTORY.md
    DATA_ACQUISITION.md
    ARCHITECTURE.md
  storage/
    raw/                   immutable source corpus
    curated/               optional future cleaned exports
    assets/                app-facing binary assets
    reports/               generated reports
  src/
    baha_rag/              knowledge and retrieval platform
  migrations/
    knowledge/             corpus and retrieval schema
    content/               app content schema
    operational/           app runtime schema
    analytics/             summary and reporting schema
```

Recommended logical separation even if physical movement is deferred:

- `raw evidence`
- `curated knowledge`
- `product content`
- `operational app data`
- `analytics outputs`

## 10. App-Facing Read Models

The mobile apps should not query the raw knowledge layer directly for most screens.

### 10.1 Student App read models

Should read from:

- student profile
- current consent state
- current week check-in state
- precomputed trend summary
- published student content
- published game/challenge definitions
- safe questions and grounded chatbot responses

### 10.2 Parent App read models

Should read from:

- privacy-tier-approved summaries
- published parent guidance
- parent learning modules
- conversation guides

Should not read from:

- raw student check-in responses
- raw chat logs
- raw case notes

### 10.3 Teacher App read models

Should read from:

- anonymized cohort summaries
- teacher learning content
- pastoral input forms
- referral state

### 10.4 BAHA/Counselor App read models

Should read from:

- case queue
- monitoring signals
- review queue
- graph-backed topic relationships
- analytics summaries
- source and citation provenance when required

## 11. Review and Publishing Workflow

Recommended lifecycle:

1. Acquire raw source
2. Extract metadata and normalize
3. Run quality checks
4. Queue for BAHA review
5. Mark reviewed resources as eligible for knowledge ingestion
6. Chunk, tag, cite, and embed
7. Create condition/topic knowledge objects
8. Create app-facing content items
9. Review app-facing content separately
10. Publish to one or more stakeholder apps
11. Monitor usage, feedback, and safety outcomes
12. Revise or archive content versions

Important rule:

Clinical review of a source document is not the same as product publication approval for a mobile app surface.

## 12. Consent and Privacy Documentation Requirements

Consent should be a first-class domain, not a single boolean field.

Each consent record should capture:

- subject
- actor granting consent
- relationship
- scope
- categories covered
- effective date
- expiry or review date
- version
- status
- evidence of agreement
- override conditions
- source policy text version

This is one place where FHIR Consent is a useful design reference, even if BAHA does not implement full FHIR.

## 13. Mapping From Current Repository to Target Architecture

### 13.1 Keep as foundation

Keep:

- acquisition schemas
- resource storage
- taxonomy
- condition profiles
- chunking and embeddings
- retrieval evaluation artifacts
- graph tables

### 13.2 Tighten

Tighten:

- graph typing and edge semantics
- source-review state versus content-publication state
- metadata consistency across resources and chunks
- organization of reports versus runtime data

### 13.3 Add

Add:

- product content schema
- operational app schema
- consent schema
- student wellness schema
- safeguarding schema
- analytics summaries for app views

### 13.4 De-prioritize as core runtime dependencies

Do not make the mobile apps depend directly on:

- raw acquisition files
- raw chunk tables for ordinary UI rendering
- graph traversals for every screen

Use curated read models instead.

## 14. Incremental Implementation Plan

### Step 1: Freeze the logical model

Decide and document:

- knowledge domain boundaries
- content domain boundaries
- operational app domain boundaries
- analytics boundaries

### Step 2: Preserve current corpus and retrieval pipeline

Do not reorganize raw assets destructively.

Add documentation and schema discipline first.

### Step 3: Introduce the product content layer

This is the highest-value next step because the apps need app-ready content, not just retrieved documents.

### Step 4: Add operational app schemas

Build the real transactional model for:

- consent
- check-ins
- progress
- cases

### Step 5: Strengthen the graph

Use it for:

- content relationships
- explainable recommendations
- coverage gaps
- counselor context

### Step 6: Add summary views

Precompute:

- parent summaries
- teacher cohort summaries
- BAHA dashboards

### Step 7: Introduce lifecycle governance

Every content object should have:

- review state
- publish state
- source provenance
- effective dates

## 15. Recommended Immediate Actions

1. Keep the current `storage/raw` corpus intact.
2. Treat the current RAG platform as the knowledge foundation, not the entire product data model.
3. Add a first-class product content schema before app development accelerates.
4. Model consent and safeguarding as separate transactional domains.
5. Keep the knowledge graph inside PostgreSQL for now.
6. Publish app content through reviewed read models instead of direct raw retrieval.

## 16. Final Recommendation

The right long-term approach for BAHA is a hybrid architecture:

- object storage for source evidence
- PostgreSQL as the operational system of record
- pgvector for retrieval and similarity search
- knowledge graph tables for semantic relationships
- curated product content for mobile app delivery
- summary tables for stakeholder-specific views

That is more suitable than:

- graph-only storage
- vector-only storage
- raw-document-driven app rendering
- using the chatbot corpus as the only content system

The current `Baha_Data` repository already contains a strong foundation for the knowledge and retrieval layers. The biggest missing piece is not more raw data. It is a cleaner boundary between:

- evidence
- curated knowledge
- publishable product content
- runtime app state
- analytics and safeguarding operations
