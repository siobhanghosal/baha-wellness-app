# BAHA Flutter Backend Delivery Plan

## 1. Recommended Direction

The best path for BAHA is:

- Flutter apps as clients
- FastAPI as the shared backend
- managed PostgreSQL with `pgvector` in the cloud
- Docker for backend packaging and local development

This is the right shape for the product because:

- the mobile apps should not connect directly to Postgres
- the apps need one governed backend for consent, content, progress, and safeguarding logic
- the backend already uses PostgreSQL and `pgvector`
- Docker keeps the backend reproducible across local development and hosted deployment

## 2. Recommended Hosted Architecture

### Application path

Use:

- Flutter apps for Student, Parent, Teacher, and BAHA/Counselor
- FastAPI backend from this repo
- managed PostgreSQL for operational and retrieval data
- managed object storage for large raw files and media later

### Recommended platform split

Recommended default for this stage:

- Supabase for managed PostgreSQL and future auth support
- Render for hosting the Dockerized FastAPI backend

Recommended cost-optimized variant:

- Supabase for managed PostgreSQL
- Render for the Dockerized FastAPI backend
- Cloudflare R2 for raw corpus storage if reducing storage cost matters more than single-vendor simplicity

Why this split:

- Supabase supports the `pgvector` extension and Flutter/Dart client tooling
- Render fully supports Docker-based deployment from a project Dockerfile
- this keeps the mobile apps on HTTPS APIs instead of direct database access

## 3. Evidence For The Recommendation

This recommendation is based on current primary-source docs:

- Supabase documents the `pgvector` extension for embeddings and vector similarity:
  <https://supabase.com/docs/guides/database/extensions/pgvector>
- Supabase maintains Dart and Flutter client documentation:
  <https://supabase.com/docs/reference/dart/introduction>
- Render documents Docker-based deployment from a project Dockerfile:
  <https://render.com/docs/docker>

Inference:

- Supabase is a strong fit for the BAHA database because the product already depends on PostgreSQL plus `pgvector`
- Render is a strong fit for the current API because the repo already has a Dockerfile and containerized local workflow

## 4. Local Development Model For Flutter

### Local backend

Use Docker locally for the database and optionally for the API:

- Postgres host port: `5433`
- API host port: `8000`
- default API runtime uses `EMBEDDING_BACKEND=hash`
- default API runtime is intentionally lighter than the acquisition/full-retrieval runtime

### Android emulator base URL

From Android emulator:

- use `http://10.0.2.2:8000`

### Physical Android device base URL

From a physical device on the same Wi-Fi network:

- use `http://<your-lan-ip>:8000`

Do not use:

- `localhost` from the phone
- direct mobile connections to Postgres

## 5. Cloud Runtime Model

The production or pilot runtime should be:

1. Flutter app signs in
2. Flutter app sends HTTPS requests to BAHA API
3. BAHA API enforces consent, access rules, and safety logic
4. BAHA API reads and writes PostgreSQL
5. BAHA API uses retrieval tables and content tables for grounded responses

This matters because:

- consent logic should live server-side
- student privacy rules should not be enforced only in the client
- future counselor and school workflows need auditable server-side actions

## 6. What To Use Supabase For

Use Supabase for:

- managed PostgreSQL
- enabling `pgvector`
- future auth integration
- future file storage if needed

Recommended auth mapping:

- Supabase auth user ID becomes `users.external_auth_id`
- app-specific profile and role data remains in BAHA tables like `users`, `user_roles`, `student_profiles`, and `guardians`
- the existing BAHA tables are the canonical runtime identity model; do not add a second parallel profile system for mobile auth

Hosted-auth bridge behavior:

- if a bearer token `sub` already matches `users.external_auth_id`, the backend uses that BAHA user directly
- if no direct match exists and the token email matches exactly one active BAHA user, the backend links that row by writing `users.external_auth_id`
- if multiple active BAHA users share the same email, automatic linking is rejected and the data must be cleaned up manually

Do not make the Flutter app talk directly to product tables for sensitive workflows.
Keep FastAPI as the policy and workflow layer.

## 7. What To Use Render For

Use Render for:

- hosting the FastAPI backend over HTTPS
- building from the lightweight default Dockerfile
- setting runtime environment variables
- exposing `/health` for service monitoring

This repo now includes a Render blueprint file at the workspace root:

- [render.yaml](/Users/sudharshan/Desktop/PES/RF Internship/render.yaml)

## 8. Immediate Backend Priorities For Flutter

To support real Flutter development, the backend should now move in this order:

1. deploy the API to a reachable hosted environment
2. wire the hosted API to a managed PostgreSQL database
3. add authentication and request identity plumbing
4. implement app-facing endpoints for:
   - student check-ins
   - module progress
   - chat sessions
   - guardian summaries
   - teacher cohort summaries
5. implement the safeguarding schema and workflow endpoints

Current implementation status:

- request identity plumbing is now present for `/mobile/*`
- backend auth/onboarding APIs now exist for users-based bootstrap and approval handling
- guardian consent APIs now cover both platform participation and parent-summary sharing
- default Docker runtime is now slimmed down for Flutter/backend handoff instead of always shipping the acquisition/ML stack
- first mobile endpoints now exist for:
  - `/mobile/me`
  - `/mobile/support-contacts`
  - `/mobile/content/feed`
  - `/mobile/content/{content_item_id}`
  - `/mobile/student/weekly-summary/latest`
  - `/mobile/student/checkin-templates`
  - `/mobile/student/checkin-templates/{template_id}`
  - `/mobile/student/checkins`
  - `/mobile/student/modules`
  - `/mobile/student/modules/{module_id}/progress`
  - `/mobile/student/help-requests`
  - `/mobile/parent/students`
  - `/mobile/parent/students/{student_profile_id}/weekly-summary/latest`
  - `/mobile/teacher/classes`
  - `/mobile/teacher/classes/{class_id}/students`
  - `/mobile/teacher/classes/{class_id}/cohort-summary/latest`
  - `/mobile/teacher/pastoral-flags`
  - `/mobile/chat/sessions`
  - `/mobile/chat/sessions/{session_id}/messages`
  - `/mobile/counselor/queue`
  - `/mobile/counselor/dashboard/latest`
  - `/mobile/counselor/cases/{case_id}`
  - `/mobile/counselor/cases/{case_id}/notes`

Current counselor demo coverage now includes:

- one open help request
- one unassigned signal
- one assigned escalation case with assignment, events, and notes

Detailed route notes live in:

- [MOBILE_API_SURFACES.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/MOBILE_API_SURFACES.md)
- [BACKEND_HANDOFF_FOR_FLUTTER.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/BACKEND_HANDOFF_FOR_FLUTTER.md)
- [ACCOUNT_ONBOARDING_SYSTEM.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/ACCOUNT_ONBOARDING_SYSTEM.md)
- [UI_BACKEND_INTEGRATION_PLAN.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/UI_BACKEND_INTEGRATION_PLAN.md)

Hosting cost and scale notes live in:

- [HOSTING_COST_AND_SCALE.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/HOSTING_COST_AND_SCALE.md)

Environment and secrets contract:

- [ENVIRONMENT_AND_SECRETS.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/ENVIRONMENT_AND_SECRETS.md)

## 9. What I Recommend Right Now

Best practical next step:

- keep local Docker for development
- prepare the repo for hosted deployment now
- treat `Supabase + Render` as the default target pilot stack
- optionally use `Cloudflare R2` for raw corpus storage if cost minimization matters

## 10. Current Delivery State

The Flutter side is no longer just planned. The repo now contains:

- a real Flutter monorepo under [Baha_Mobile/README.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Mobile/README.md)
- shared packages for:
  - API client
  - session/onboarding routing
  - shared models
  - design system
  - content rendering
- a verified student startup slice wired to the real backend

What is already proven:

- onboarding-state and mobile-actor contracts are consumable from Flutter
- the seeded student identity `supabase-student-demo` resolves to `ready`
- the student weekly summary and check-in contracts are consumable from Flutter
- a real student check-in submission round-trip succeeds against the backend
- the learn/modules contracts are consumable from Flutter
- the student modules response now exposes `content_item_id`, removing brittle title-based content mapping
- the learning contracts now support theme-focused student lanes instead of one generic feed
- the content feed now supports `theme`, `topic`, and `subtopic` filters
- the student modules endpoint now supports `theme` filtering
- the student learning seeds now cover:
  - Sleep
  - Digital Wellness
  - Peer Pressure
  - Exam Stress
- the support contacts and student help-request contracts are consumable from Flutter
- the Buddy/chat session and message contracts are consumable from Flutter
- the guardian linked-student, summary, and summary-consent contracts are consumable from Flutter
- the parent content feed and content detail contracts are consumable from Flutter
- the student Android debug build succeeds locally

Best next product-development step from here:

1. keep testing against the same local backend contract
2. deepen the student learning lanes, especially Digital Wellness and Sleep
3. then implement the teacher app first real slice
4. then implement the counselor app first real slice
- defer real external cloud credentials and provisioning until the remaining backend work is complete

Content-system reference:

- [STUDENT_LEARNING_CONTENT_STRATEGY.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/STUDENT_LEARNING_CONTENT_STRATEGY.md)

That gives the Flutter app a clean client-server architecture immediately, without forcing the mobile code to be rewritten later.
