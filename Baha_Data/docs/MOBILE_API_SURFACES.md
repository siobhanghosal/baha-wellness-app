# BAHA Mobile API Surfaces

## 1. Purpose

This document lists the first mobile-facing API surfaces now available in the backend.

These endpoints are the initial bridge for Flutter development. They are intentionally limited:

- enough to start wiring real screens
- not the final cloud provisioning state
- not the final object-storage integration state

## 2. Temporary Identity Model

For now, mobile endpoints accept one of these headers:

- `X-BAHA-User-Id`
- `X-BAHA-External-Auth-Id`

At least one is required for `/mobile/*` routes.

This is a development bridge only.

If bearer-token verification is configured through environment variables, the backend can also authenticate `Authorization: Bearer ...` requests.

Planned production direction:

- Flutter authenticates with Supabase Auth
- backend verifies request identity from the auth layer
- `users.external_auth_id` maps to the external identity provider user ID

## 3. Available Endpoints

### Identity

`GET /mobile/me`

Returns:

- BAHA user ID
- external auth ID if present
- display name
- roles
- primary role
- mapped app audience
- active student profile ID if present

### Student app

`GET /mobile/student/checkin-templates`

Returns active student check-in templates filtered by the actor's age cohort.

`GET /mobile/student/checkin-templates/{template_id}`

Returns one student check-in template including ordered question definitions so the client can render a live submission form.

`GET /mobile/student/modules`

Returns active approved student learning modules plus latest progress for the current student.

`POST /mobile/student/modules/{module_id}/progress`

Upserts progress for a student learning module.

Body:

```json
{
  "status": "in_progress",
  "completion_percent": 25,
  "current_section_ordinal": 1,
  "current_step_ordinal": 2
}
```

`GET /mobile/student/checkins`

Returns submitted check-in response sets for the student.

`GET /mobile/student/checkins/{response_set_id}`

Returns a submitted check-in plus question/answer detail.

`POST /mobile/student/checkins`

Submits a check-in response set.

`POST /mobile/student/help-requests`

Creates a direct student help request that can appear in counselor operations.

### Parent app

`GET /mobile/parent/students`

Returns active guardian-linked students.

`GET /mobile/parent/students/{student_profile_id}/weekly-summary/latest`

Returns the latest parent-safe weekly summary if:

- guardian linkage is active
- consent exists
- privacy tiers allow it
- or a safeguarding override is active

### Teacher app

`GET /mobile/teacher/classes`

Returns classes assigned to the teacher.

`GET /mobile/teacher/classes/{class_id}/students`

Returns active students in a teacher-assigned class so the pastoral flag flow can target the right student profile.

`GET /mobile/teacher/classes/{class_id}/cohort-summary/latest`

Returns the latest anonymized cohort summary for an assigned class.

`POST /mobile/teacher/pastoral-flags`

Creates a pastoral flag for counselor review and workflow follow-up.

### Shared chat surface

`GET /mobile/chat/sessions`

Returns recent chat sessions for the current actor and mapped app audience.

`POST /mobile/chat/sessions`

Creates a new chat session.

Body:

```json
{
  "session_type": "general_support",
  "summary_visibility_scope": "private"
}
```

`GET /mobile/chat/sessions/{session_id}/messages`

Returns persisted messages for a chat session.

`POST /mobile/chat/sessions/{session_id}/messages`

Stores a user message, generates a cited assistant response, stores both, and raises emergency monitoring items when required.

### Counselor / BAHA app

`GET /mobile/counselor/queue`

Returns:

- open escalation cases
- unresolved monitoring signals without a case
- open help requests

`GET /mobile/counselor/cases/{case_id}`

Returns case details, notes, events, and assignments.

`POST /mobile/counselor/cases/{case_id}/notes`

Adds a case note and records a case event.

## 4. Current Limitations

These endpoints do not yet provide:

- fully provisioned external auth credentials
- guardian-to-student context switching beyond the active link model
- teacher/student individual override views
- complete counselor assignment workflows
- final hosted object-storage wiring

Those are next-phase backend tasks.

## 5. Flutter Integration Notes

For local Android emulator use:

- `http://10.0.2.2:8000`

For physical devices on the same network use:

- `http://<your-lan-ip>:8000`

Do not call Postgres directly from Flutter.
