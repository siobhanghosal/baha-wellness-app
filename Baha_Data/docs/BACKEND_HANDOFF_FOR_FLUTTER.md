# BAHA Backend Handoff For Flutter

## 1. Purpose

This document is the practical handoff note for the Flutter developer.

It explains:

- what backend environment exists now
- which mobile endpoints are available
- which auth/onboarding endpoints are available
- how identity works in local development versus hosted deployment
- what demo data is already seeded
- what assumptions the client app can safely make

## 2. Current Backend Shape

The backend is:

- FastAPI
- PostgreSQL with `pgvector`
- local Docker for development
- a lightweight default API runtime for Flutter handoff
- designed for hosted deployment later using:
  - Supabase for PostgreSQL and auth
  - Render for API hosting
  - optional Cloudflare R2 for raw corpus storage

Default local/runtime profile now means:

- the default `Dockerfile` and `docker compose` flow install only the mobile/API runtime dependencies
- `EMBEDDING_BACKEND=hash` is the default local setting
- acquisition-heavy admin workflows are intentionally outside that default runtime
- `Dockerfile.full` exists for acquisition or full retrieval work

## 3. Local Development Targets

When the backend runs locally:

- API base URL from Android emulator: `http://10.0.2.2:8000`
- API base URL from physical device on same network: `http://<your-lan-ip>:8000`
- local Postgres host port: `5433`

Important:

- Flutter should never connect directly to Postgres
- all app features should go through backend APIs

## 4. Identity Modes

### 4.1 Local development mode

Until hosted auth is provisioned, `/mobile/*` endpoints accept:

- `X-BAHA-User-Id`
- `X-BAHA-External-Auth-Id`

At least one development identity header is required unless bearer token verification is configured.

### 4.2 Hosted auth mode

The backend now supports bearer-token verification when these environment variables are configured:

- `AUTH_JWKS_URL`
- `AUTH_ISSUER`
- `AUTH_AUDIENCE`

Alternative secret-based verification can use:

- `AUTH_JWT_SECRET`

Planned production identity mapping:

- Supabase Auth user ID maps to `users.external_auth_id`
- BAHA runtime identity remains centered on `users`, `user_roles`, `student_profiles`, `guardians`, and `teacher_profiles`

Hosted identity bridge behavior:

- first the backend tries to resolve the bearer token `sub` against `users.external_auth_id`
- if no direct match exists, the backend can link the token to exactly one existing active BAHA user by matching the token email
- if duplicate active BAHA emails exist, automatic linking is rejected until the data is cleaned up

Bootstrap and onboarding endpoints now available:

- `POST /auth/bootstrap`
- `GET /auth/onboarding-state`
- `GET /auth/me`
- `POST /auth/guardian/link-student`
- `POST /auth/guardian/consent/platform-participation`
- `GET /auth/guardian/consent/parent-summary-sharing/{student_profile_id}`
- `POST /auth/guardian/consent/parent-summary-sharing`
- `GET /auth/approval-requests`
- `POST /auth/approval-requests/{request_id}/decision`

For local development, `POST /auth/bootstrap` and `GET /auth/onboarding-state` can also use:

- `X-BAHA-External-Auth-Id`
- `X-BAHA-Auth-Email` (optional)

when bearer-token verification is not configured and dev identity headers remain enabled.

## 5. Seeded Demo Identities

The backend includes demo seed data through SQL migrations.

Demo external auth IDs:

- `supabase-student-demo`
- `supabase-guardian-demo`
- `supabase-teacher-demo`
- `supabase-counselor-demo`
- `supabase-admin-demo`

Demo user emails:

- `student.demo@baha.local`
- `guardian.demo@baha.local`
- `teacher.demo@baha.local`
- `counselor.demo@baha.local`
- `admin.demo@baha.local`

## 6. Seeded Demo Domain Data

The seeded demo environment includes:

- one pilot school
- one demo class
- one student
- one linked guardian
- one teacher
- one counselor
- one open help request
- one unassigned monitoring signal
- one assigned escalation case with one assignment, one event trail, and one note
- privacy settings
- consent records
- student check-in template and questions
- multiple approved student learning modules, cards, checklists, and prompts
- one parent content object
- one teacher content object
- support contacts
- one crisis routing rule
- one student weekly summary
- one parent weekly summary
- one teacher cohort summary
- one pilot dashboard snapshot
- one school-scoped pilot dashboard snapshot
- two pending approval requests for BAHA approval-flow testing

If you need a clean local reset after migration changes:

```bash
docker compose down -v
docker compose up -d --build postgres
```

## 7. Available Mobile Routes

The implemented mobile-facing routes are:

### Shared

- `GET /mobile/me`
- `GET /mobile/support-contacts`
- `GET /mobile/content/feed`
- `GET /mobile/content/{content_item_id}`
- `GET /mobile/chat/sessions`
- `POST /mobile/chat/sessions`
- `GET /mobile/chat/sessions/{session_id}/messages`
- `POST /mobile/chat/sessions/{session_id}/messages`

Buddy runtime note:

- the Flutter chat contract does not change as long as Buddy stays behind the same backend endpoint
- retrieval remains local to BAHA storage and pgvector
- the current final answer-generation step is OpenAI-backed

### Student

- `GET /mobile/student/weekly-summary/latest`
- `GET /mobile/student/checkin-templates`
- `GET /mobile/student/checkin-templates/{template_id}`
- `GET /mobile/student/checkins`
- `GET /mobile/student/checkins/{response_set_id}`
- `POST /mobile/student/checkins`
- `GET /mobile/student/modules`
- `POST /mobile/student/modules/{module_id}/progress`
- `POST /mobile/student/help-requests`

Current student learning specifics:

- `GET /mobile/content/feed` now supports filtering by:
  - `theme`
  - `topic`
  - `subtopic`
- `GET /mobile/student/modules` now supports filtering by:
  - `theme`
- student module summaries now expose:
  - `content_item_id`
  - `current_section_ordinal`
  - `current_step_ordinal`
  - `total_sections`
  - `total_steps`

### Parent

- `GET /mobile/parent/students`
- `GET /mobile/parent/students/{student_profile_id}/weekly-summary/latest`

### Teacher

- `GET /mobile/teacher/classes`
- `GET /mobile/teacher/classes/{class_id}/students`
- `GET /mobile/teacher/classes/{class_id}/cohort-summary/latest`
- `POST /mobile/teacher/pastoral-flags`

### Counselor / BAHA

- `GET /mobile/counselor/queue`
- `GET /mobile/counselor/dashboard/latest`
- `GET /mobile/counselor/cases/{case_id}`
- `POST /mobile/counselor/cases/{case_id}/notes`

## 8. Important Backend Behaviors

These behaviors are already enforced server-side:

- parent summary access checks guardian linkage
- parent summary access checks consent state
- guardians can explicitly read and update parent-summary sharing consent through auth endpoints
- guardian platform-participation consent currently returns the linked student's onboarding snapshot, so clients should treat it as an action endpoint rather than a guardian-session refresh contract
- parent summary access checks privacy-tier configuration
- published role-safe content is served through app-facing content read models instead of direct table access
- support contacts are served through app-facing read models instead of hardcoded client copy
- student weekly summary is available as a direct mobile read model for the student dashboard
- teacher app gets anonymized cohort summaries, not raw student wellness records
- emergency chat language creates a monitoring signal and an escalation case
- counselor queue reads from help requests, signals, and escalation cases
- counselor queue and case detail are school-scoped for non-BAHA-admin counselor access
- counselor dashboard prefers school metrics when available and falls back to the latest global metric
- counselor notes are blocked for resolved, closed, or cancelled cases

## 9. Remaining Backend Caveats

The backend is usable for client development, but some areas are still transitional:

- bearer-token auth path is implemented but not provisioned with real cloud credentials yet
- demo seed data is limited and not a full pilot dataset
- some admin and content operations still live outside the mobile contract
- the default lightweight API runtime returns `503` for heavy acquisition workflows unless the full runtime is used
- object storage integration is defined by config contract but not yet fully wired to a cloud bucket
- onboarding is now users-based and server-enforced, but richer admin workflows are still deferred
- content review and threshold-configuration mutations are still not exposed as mobile workflows

## 10. Last Verified Local Baseline

This backend was last verified locally with:

- `docker compose down -v`
- `docker compose up -d --build postgres api`

Verified behavior in that clean local state:

## 11. Current Mobile Workspace Status

The Flutter workspace now exists under:

- [Baha_Mobile/README.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Mobile/README.md)

Implemented mobile status right now:

- the monorepo has four real Flutter apps plus shared packages
- the student app already implements the startup, check-in, learn, support, and Buddy/chat slices against this backend
- the student app uses:
  - development identity capture
  - `GET /auth/onboarding-state`
  - `POST /auth/bootstrap`
  - `GET /mobile/me`
- the student app also implements:
  - `GET /mobile/content/feed`
  - `GET /mobile/content/{content_item_id}`
  - theme-focused Learn routing for:
    - Sleep
    - Digital Wellness
    - Peer Pressure
    - Exam Stress
  - richer block-rendered student learning content
  - structure-aware module progress display

Current content strategy reference:

- [STUDENT_LEARNING_CONTENT_STRATEGY.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/STUDENT_LEARNING_CONTENT_STRATEGY.md)
  - `GET /mobile/student/modules`
  - `POST /mobile/student/modules/{module_id}/progress`
  - `GET /mobile/support-contacts`
  - `POST /mobile/student/help-requests`
  - `GET /mobile/chat/sessions`
  - `POST /mobile/chat/sessions`
  - `GET /mobile/chat/sessions/{session_id}/messages`
  - `POST /mobile/chat/sessions/{session_id}/messages`
- the parent app now implements the first real guardian slice:
  - development identity capture
  - `GET /auth/onboarding-state`
  - `GET /mobile/me`
  - `GET /mobile/parent/students`
  - `GET /mobile/parent/students/{student_profile_id}/weekly-summary/latest`
  - `GET /mobile/content/feed`
  - `GET /mobile/content/{content_item_id}`
  - `GET /auth/guardian/consent/parent-summary-sharing/{student_profile_id}`
  - `POST /auth/guardian/consent/parent-summary-sharing`
  - `POST /auth/guardian/consent/platform-participation`
  - `GET /mobile/support-contacts`
- teacher and counselor apps are still scaffolded shells awaiting their first real slices
  - `GET /mobile/student/modules`
  - `POST /mobile/student/modules/{module_id}/progress`
- the student app now also implements the support slice on the real backend:
  - `GET /mobile/support-contacts`
  - `POST /mobile/student/help-requests`
- the student app now also implements the Buddy/chat slice on the real backend:
  - `GET /mobile/chat/sessions`
  - `POST /mobile/chat/sessions`
  - `GET /mobile/chat/sessions/{session_id}/messages`
  - `POST /mobile/chat/sessions/{session_id}/messages`

Latest verified mobile/backend handshake:

- `GET /health` returned `{"status":"ok"}`
- `GET /auth/onboarding-state` with `X-BAHA-External-Auth-Id: supabase-student-demo` returned `next_step: ready`
- `GET /mobile/me` with `X-BAHA-External-Auth-Id: supabase-student-demo` returned the seeded student actor
- `GET /mobile/student/weekly-summary/latest` returned the seeded student weekly summary
- `GET /mobile/student/checkin-templates` returned the seeded weekly student template after the backend query fix
- `POST /mobile/student/checkins` successfully stored a real seeded demo response set
- `GET /mobile/student/checkins/{response_set_id}` successfully returned stored answers
- `GET /mobile/content/feed` returned the seeded student learning content feed
- `GET /mobile/student/modules` returned the expanded seeded student module set with direct `content_item_id` linkage
- `GET /mobile/content/{content_item_id}` returned the richer seeded module detail body with structured blocks
- `POST /mobile/student/modules/{module_id}/progress` successfully updated the seeded student module progress
- `GET /mobile/support-contacts` returned the seeded student-visible support contacts
- `POST /mobile/student/help-requests` successfully created a new help request visible in the counselor queue
- `GET /mobile/chat/sessions` returned the student session list after the chat query fix
- `POST /mobile/chat/sessions` successfully created a new student Buddy session
- `GET /mobile/chat/sessions/{session_id}/messages` returned persisted chat history
- `POST /mobile/chat/sessions/{session_id}/messages` successfully stored a user message and assistant reply

Latest verified Android app build:

- student app debug APK built successfully at:
  - [app-debug.apk](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Mobile/apps/student_app/build/app/outputs/flutter-apk/app-debug.apk)

Recent backend fix applied during Flutter integration:

- `GET /mobile/student/modules` had been failing with PostgreSQL ambiguous-parameter handling around `age_cohort` and `student_profile_id`
- the student modules read model now explicitly casts those parameters in the repository query
- the student modules response now includes `content_item_id` so Flutter can open module content directly through `/mobile/content/{content_item_id}`
- the repaired code lives in [mobile_repository.py](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/src/baha_rag/db/mobile_repository.py)

- migrations applied cleanly through `023_student_content_polish_seed.sql`
- `GET /health` returned `ok`
- `GET /health/ready` returned `ready`
- `GET /mobile/student/weekly-summary/latest` returned the seeded student dashboard summary
- `GET /mobile/content/feed?content_type=conversation_guide` returned the seeded parent guide
- `GET /mobile/support-contacts` returned the seeded emergency and counselor contacts
- counselor demo queue returned one case, one unassigned signal, and one help request
- counselor dashboard returned the seeded school-scoped pilot metric snapshot
- counselor case detail returned notes, events, and assignments for `CASE-DEMO-001`
- counselor note creation succeeded on the seeded demo case
- `GET /auth/approval-requests?status=pending` returned the seeded teacher and counselor approval requests
- heavy acquisition workflows returned explicit `503` responses in the lightweight runtime instead of crashing the API

## 11. What The Flutter Developer Can Build Immediately

The Flutter developer can already build:

- account bootstrap and gating flow using `/auth/onboarding-state` and `/auth/bootstrap`
- active-account identity bootstrap using `/auth/me` or `/mobile/me`
- student dashboard summary using `/mobile/student/weekly-summary/latest`
- student module list and progress flow
- student check-in list, template-detail, and submission flow
- chat session list and chat UI with persisted messages
- parent linked-student summary screens
- shared support and content screens using `/mobile/support-contacts` and `/mobile/content/feed`
- teacher class list, class-student, and cohort summary screens
- counselor queue, dashboard, and case detail views

## 12. What Is Still Left To Build

In practical order, the next implementation work is:

- parent app real screens on top of the existing backend contract
- teacher app real screens on top of the existing backend contract
- counselor app real screens on top of the existing backend contract
- hosted auth credential wiring and non-dev identity flow
- final hosted deployment handoff once the remaining core app slices are stable

## 13. Core References

- [MOBILE_API_SURFACES.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/MOBILE_API_SURFACES.md)
- [FLUTTER_BACKEND_DELIVERY_PLAN.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/FLUTTER_BACKEND_DELIVERY_PLAN.md)
- [ENVIRONMENT_AND_SECRETS.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/ENVIRONMENT_AND_SECRETS.md)
- [ACCOUNT_ONBOARDING_SYSTEM.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/ACCOUNT_ONBOARDING_SYSTEM.md)
- [UI_BACKEND_INTEGRATION_PLAN.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/UI_BACKEND_INTEGRATION_PLAN.md)
