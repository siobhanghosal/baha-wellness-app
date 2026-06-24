# BAHA Backend Handoff For Flutter

## 1. Purpose

This document is the practical handoff note for the Flutter developer.

It explains:

- what backend environment exists now
- which mobile endpoints are available
- how identity works in local development versus hosted deployment
- what demo data is already seeded
- what assumptions the client app can safely make

## 2. Current Backend Shape

The backend is:

- FastAPI
- PostgreSQL with `pgvector`
- local Docker for development
- designed for hosted deployment later using:
  - Supabase for PostgreSQL and auth
  - Render for API hosting
  - optional Cloudflare R2 for raw corpus storage

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
- parent summary access checks privacy-tier configuration
- teacher app gets anonymized cohort summaries, not raw student wellness records
- emergency chat language creates a monitoring signal and an escalation case
- counselor queue reads from help requests, signals, and escalation cases

## 9. Remaining Backend Caveats

The backend is usable for client development, but some areas are still transitional:

- bearer-token auth path is implemented but not provisioned with real cloud credentials yet
- demo seed data is limited and not a full pilot dataset
- some admin and content operations still live outside the mobile contract
- object storage integration is defined by config contract but not yet fully wired to a cloud bucket

## 10. What The Flutter Developer Can Build Immediately

The Flutter developer can already build:

- identity bootstrap using `/mobile/me`
- student module list and progress flow
- student check-in list and submission flow
- chat session list and chat UI with persisted messages
- parent linked-student summary screens
- teacher class list and cohort summary screens
- counselor queue and case detail views

## 11. Core References

- [MOBILE_API_SURFACES.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/MOBILE_API_SURFACES.md)
- [FLUTTER_BACKEND_DELIVERY_PLAN.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/FLUTTER_BACKEND_DELIVERY_PLAN.md)
- [ENVIRONMENT_AND_SECRETS.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/ENVIRONMENT_AND_SECRETS.md)
