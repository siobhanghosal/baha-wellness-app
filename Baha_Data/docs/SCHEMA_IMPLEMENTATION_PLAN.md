# BAHA Schema Implementation Plan

## 1. Goal

This document converts the product data architecture into an implementation order for the BAHA platform.

It answers:

- what data work should happen next
- which schemas should be implemented first
- which tables are essential for the first functional app release
- what should remain in the existing knowledge platform
- what should be deferred until the app domains are stable

This plan assumes:

- the raw corpus remains intact
- the current retrieval and acquisition platform remains the knowledge foundation
- the next work is schema-first, not full app implementation

## 2. Recommended Next Step

The immediate next step for the data is:

**build the missing app-facing data schemas in a controlled order, starting with product content and consent.**

That means:

1. keep the current `Baha_Data` knowledge platform as-is
2. add a first-class product content schema
3. add identity and consent schema
4. add operational student wellness schema
5. add support and safeguarding schema
6. add summary read models for stakeholder apps

## 3. What Already Exists

These areas are already reasonably strong:

- source acquisition
- source inventory
- clinical review queue for resources
- taxonomy
- chunking
- embeddings
- retrieval pipeline
- graph foundations
- retrieval evaluation and coverage reporting

These areas are still missing or only implied:

- app-publishable content schema
- consent and privacy schema
- user and stakeholder relationship schema
- check-in and trend schema
- module progress schema
- game session schema
- escalation case schema
- stakeholder-facing summary schema

## 4. Implementation Order

The schema work should happen in this order.

### Phase A: Product Content Schema

Build first because every app depends on app-ready content.

Why first:

- the apps need publishable content, not only raw retrieval
- chatbot answers need approved content objects
- learning modules need a versioned publishing system
- game scenarios and conversation guides also belong here

Core tables:

- `content_items`
- `content_versions`
- `content_assets`
- `content_citations`
- `content_review_queue`
- `content_publish_targets`
- `safe_questions`
- `safe_question_answers`
- `learning_modules`
- `learning_module_sections`
- `learning_module_steps`
- `quizzes`
- `quiz_items`
- `game_scenarios`
- `challenge_templates`
- `copy_blocks`

### Phase B: Identity and Consent Schema

Build second because every app and every protected workflow depends on it.

Why second:

- role separation is core to the product
- privacy promises need enforceable data models
- parent and student relationships need structured representation
- override events need to be auditable

Core tables:

- `users`
- `roles`
- `user_roles`
- `student_profiles`
- `guardians`
- `student_guardian_links`
- `schools`
- `school_enrollments`
- `classes`
- `class_memberships`
- `teacher_profiles`
- `teacher_assignments`
- `consent_records`
- `consent_versions`
- `privacy_tier_settings`
- `override_events`

### Phase C: Student Wellness Schema

Build third because this powers the core student app.

Why third:

- the student experience is the center of the product
- check-ins and trends are a primary product loop
- challenges, badges, and games depend on student state

Core tables:

- `checkin_templates`
- `checkin_questions`
- `checkin_response_sets`
- `checkin_responses`
- `trend_snapshots`
- `reflection_entries`
- `challenge_enrollments`
- `challenge_progress`
- `badge_definitions`
- `badge_awards`
- `game_sessions`
- `game_session_events`
- `game_behavioral_signals`

### Phase D: Learning and Chatbot Runtime Schema

Build fourth because it bridges published content and live user interactions.

Why fourth:

- students, parents, and teachers all consume learning content
- chatbot interactions need runtime storage separate from source content

Core tables:

- `module_progress`
- `module_step_progress`
- `quiz_attempts`
- `quiz_attempt_items`
- `chat_sessions`
- `chat_messages`
- `chat_answer_citations`
- `chat_profile_summaries`

### Phase E: Support and Safeguarding Schema

Build fifth because it depends on identity, consent, and student activity.

Why fifth:

- cases rely on student identity and consent
- signals rely on check-ins, chat, and teacher inputs
- operational workflows need structured action logs

Core tables:

- `help_requests`
- `pastoral_flags`
- `monitoring_signals`
- `signal_sources`
- `escalation_cases`
- `case_assignments`
- `case_events`
- `case_notes`
- `support_contacts`
- `crisis_routing_rules`

### Phase F: Analytics and Read Models

Build last in the first pass because they depend on the runtime schemas above.

Why last:

- read models should reflect real workflows, not guesses
- summary tables are derived and can be iterated faster later

Core tables or materialized views:

- `student_weekly_summaries`
- `parent_weekly_summaries`
- `teacher_cohort_summaries`
- `baha_pilot_dashboard_metrics`
- `content_usage_snapshots`
- `engagement_snapshots`
- `escalation_review_metrics`

## 5. Minimal First-Cut Data for a Functional Launch

If the goal is to reach a usable first functional release quickly, the data minimum is:

### Required immediately

- `content_items`
- `content_versions`
- `content_citations`
- `users`
- `student_profiles`
- `guardians`
- `student_guardian_links`
- `schools`
- `consent_records`
- `privacy_tier_settings`
- `checkin_response_sets`
- `checkin_responses`
- `trend_snapshots`
- `module_progress`
- `chat_sessions`
- `chat_messages`
- `help_requests`
- `monitoring_signals`
- `escalation_cases`
- `case_events`

### Can follow shortly after

- quizzes
- badge system
- challenge progress
- detailed game event logs
- parent/teacher summary materialized views
- richer analytics snapshots

## 6. Exact Table Priorities

### Priority 0

These are the tables that block the basic product:

- `content_items`
- `content_versions`
- `content_citations`
- `users`
- `student_profiles`
- `guardians`
- `student_guardian_links`
- `schools`
- `consent_records`
- `privacy_tier_settings`
- `checkin_response_sets`
- `checkin_responses`
- `trend_snapshots`
- `chat_sessions`
- `chat_messages`
- `monitoring_signals`
- `escalation_cases`

### Priority 1

- `learning_modules`
- `learning_module_steps`
- `module_progress`
- `pastoral_flags`
- `case_events`
- `case_notes`
- `teacher_profiles`
- `teacher_assignments`
- `parent_weekly_summaries`
- `teacher_cohort_summaries`

### Priority 2

- `quizzes`
- `quiz_items`
- `quiz_attempts`
- `challenge_templates`
- `challenge_enrollments`
- `badge_definitions`
- `badge_awards`
- `game_sessions`
- `game_behavioral_signals`
- `content_usage_snapshots`

## 7. Recommended Schema Boundaries

To avoid future confusion, each table should clearly belong to one domain.

### Knowledge schema

Use for:

- acquired sources
- cleaned resources
- chunks
- embeddings
- graph nodes and edges
- condition profiles

Do not store:

- live user data
- consent decisions
- app progress
- case notes

### Content schema

Use for:

- reviewed, publishable content
- app-targeted content variants
- approved chatbot answers
- learning objects

Do not store:

- raw source files
- transient session logs

### Operational schema

Use for:

- identity
- consent
- check-ins
- progress
- support workflows

Do not store:

- raw evidence or chunk embeddings

### Analytics schema

Use for:

- summaries
- snapshots
- dashboards

Do not use as source of truth for operational transactions.

## 8. Recommended Naming and Modeling Rules

### 8.1 General rules

- use stable surrogate IDs
- use `created_at` and `updated_at` everywhere
- use explicit status fields, not implicit null-state logic
- use `effective_from` and `effective_to` for publishable or governed records
- use version tables where wording or review state matters

### 8.2 For consent and privacy

- every consent change should create a new record or version row
- never overwrite the previous consent state without preserving history
- store the policy/version text reference used when consent was collected
- store actor relationship clearly

### 8.3 For content

- content should be versioned separately from source documents
- one source can support many content items
- one content item can cite many source documents

### 8.4 For derived summaries

- store derivation timestamp
- store input time window
- store generation version if logic changes

## 9. Suggested Migration Strategy

Do not try to implement everything in one SQL migration.

Recommended migration sequence:

1. `014_product_content_core.sql`
2. `015_identity_and_consent_core.sql`
3. `016_student_wellness_core.sql`
4. `017_learning_and_chat_runtime.sql`
5. `018_support_and_safeguarding_core.sql`
6. `019_app_read_models.sql`

If you later split migration folders by domain, retain a global ordering convention.

Current implementation status in this workspace:

- `014_product_content_core.sql` implemented
- `015_identity_and_consent_core.sql` implemented
- `016_student_wellness_core.sql` implemented
- `017_learning_and_chat_runtime.sql` implemented
- `018_support_and_safeguarding_core.sql` implemented
- `019_app_read_models.sql` implemented
- `020_demo_seed_data.sql` implemented
- current backend focus has moved from schema completion to auth, privacy enforcement, app surfaces, and handoff readiness

## 10. How the Apps Would Consume This Data

### Student App

Needs direct access to:

- student profile
- consent-aware content entitlements
- current and past check-ins
- trend snapshots
- published student modules
- game scenarios
- chatbot sessions

### Parent App

Needs direct access to:

- guardian identity
- linked student relationship
- privacy-tier-approved summaries
- published parent content
- parent learning progress

### Teacher App

Needs direct access to:

- teacher identity
- class memberships
- anonymized cohort summaries
- pastoral flag tools
- published teacher content

### BAHA/Counselor App

Needs direct access to:

- support queue
- case records
- monitoring signals
- review queues
- content operations
- dashboard summaries

## 11. Recommended Immediate Work Items

These are the next data actions I recommend.

### Work item 1

Freeze the schema domains in writing:

- knowledge
- content
- identity and consent
- student wellness
- safeguarding
- analytics

This is mostly complete through the architecture docs and should now become the accepted working model.

### Work item 2

Create the product content schema migration.

This is the highest-value next implementation step because the mobile apps will need:

- reviewed content
- stakeholder-targeted content
- age-targeted content
- chatbot-safe answer objects
- game and challenge definitions

### Work item 3

Create the identity and consent schema migration.

This is the second-highest-value step because:

- all four apps depend on roles
- parent/student linkage is critical
- privacy promises depend on real data constraints

### Work item 4

Define the first read-model queries for:

- student home screen
- parent weekly summary
- teacher class trends
- counselor support queue

### Work item 5

Only after the above, add deeper app telemetry and summary tables.

## 12. What I Recommend Doing Right Now

If continuing immediately, the next concrete data task should be:

**implement the product content schema first.**

Reason:

- it connects the current evidence platform to the actual product
- it is lower-risk than implementing every operational table at once
- it creates a governed publishing layer for chatbot, learning, and game content

After that:

**implement identity and consent core.**

That will create the minimum trustworthy foundation for the app suite.

## 13. Final Recommendation

The next phase of data work should not be:

- collecting more raw data first
- redesigning the whole corpus layout first
- adding a separate graph database first

The next phase should be:

- define app-facing schemas
- publish reviewed content through them
- model consent and stakeholder relationships properly
- then layer runtime student and safeguarding data on top

That is the shortest path from the current knowledge platform to a usable product data backbone.
