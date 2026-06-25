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
- one approved student learning module
- one parent content object
- one teacher content object
- support contacts
- one crisis routing rule
- one student weekly summary
- one parent weekly summary
- one teacher cohort summary
- one pilot dashboard snapshot

If you need a clean local reset after migration changes:

```bash
docker compose down -v
docker compose up -d --build postgres
```

## 7. Available Mobile Routes

The implemented mobile-facing routes are:

### Shared

- `GET /mobile/me`
- `GET /mobile/chat/sessions`
- `POST /mobile/chat/sessions`
- `GET /mobile/chat/sessions/{session_id}/messages`
- `POST /mobile/chat/sessions/{session_id}/messages`

### Student

- `GET /mobile/student/checkin-templates`
- `GET /mobile/student/checkin-templates/{template_id}`
- `GET /mobile/student/checkins`
- `GET /mobile/student/checkins/{response_set_id}`
- `POST /mobile/student/checkins`
- `GET /mobile/student/modules`
- `POST /mobile/student/modules/{module_id}/progress`
- `POST /mobile/student/help-requests`

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
- `GET /mobile/counselor/cases/{case_id}`
- `POST /mobile/counselor/cases/{case_id}/notes`

## 8. Important Backend Behaviors

These behaviors are already enforced server-side:

- parent summary access checks guardian linkage
- parent summary access checks consent state
- guardians can explicitly read and update parent-summary sharing consent through auth endpoints
- parent summary access checks privacy-tier configuration
- teacher app gets anonymized cohort summaries, not raw student wellness records
- emergency chat language creates a monitoring signal and an escalation case
- counselor queue reads from help requests, signals, and escalation cases
- counselor queue and case detail are school-scoped for non-BAHA-admin counselor access
- counselor notes are blocked for resolved, closed, or cancelled cases

## 9. Remaining Backend Caveats

The backend is usable for client development, but some areas are still transitional:

- bearer-token auth path is implemented but not provisioned with real cloud credentials yet
- demo seed data is limited and not a full pilot dataset
- some admin and content operations still live outside the mobile contract
- the default lightweight API runtime returns `503` for heavy acquisition workflows unless the full runtime is used
- object storage integration is defined by config contract but not yet fully wired to a cloud bucket
- onboarding is now users-based and server-enforced, but richer admin workflows are still deferred

## 10. Last Verified Local Baseline

This backend was last verified locally with:

- `docker compose down -v`
- `docker compose up -d --build postgres api`

Verified behavior in that clean local state:

- migrations applied cleanly through `021_auth_onboarding_and_approvals.sql`
- `GET /health` returned `ok`
- `GET /health/ready` returned `ready`
- counselor demo queue returned one case, one unassigned signal, and one help request
- counselor case detail returned notes, events, and assignments for `CASE-DEMO-001`
- counselor note creation succeeded on the seeded demo case
- heavy acquisition workflows returned explicit `503` responses in the lightweight runtime instead of crashing the API

## 11. What The Flutter Developer Can Build Immediately

The Flutter developer can already build:

- account bootstrap and gating flow using `/auth/onboarding-state` and `/auth/bootstrap`
- active-account identity bootstrap using `/auth/me` or `/mobile/me`
- student module list and progress flow
- student check-in list, template-detail, and submission flow
- chat session list and chat UI with persisted messages
- parent linked-student summary screens
- teacher class list, class-student, and cohort summary screens
- counselor queue and case detail views

## 12. Core References

- [MOBILE_API_SURFACES.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/MOBILE_API_SURFACES.md)
- [FLUTTER_BACKEND_DELIVERY_PLAN.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/FLUTTER_BACKEND_DELIVERY_PLAN.md)
- [ENVIRONMENT_AND_SECRETS.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/ENVIRONMENT_AND_SECRETS.md)
- [ACCOUNT_ONBOARDING_SYSTEM.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/ACCOUNT_ONBOARDING_SYSTEM.md)
