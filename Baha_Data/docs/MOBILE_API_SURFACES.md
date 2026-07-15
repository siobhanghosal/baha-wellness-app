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

### Auth / onboarding

`POST /auth/bootstrap`

Creates or updates the BAHA-side account record for a bearer-token identity using the canonical `users`-based schema.

In local development, this route can also use:

- `X-BAHA-External-Auth-Id`
- `X-BAHA-Auth-Email` (optional)

`GET /auth/onboarding-state`

Returns the current BAHA account/bootstrap status for the bearer-token identity, including approval, consent, and next-step guidance.

`GET /auth/me`

Returns the authenticated BAHA account state for an already-linked active user.

`POST /auth/guardian/link-student`

Creates or updates a guardian-to-student relationship using `student_profile_id` or `student_code`.
For the live under-18 flow, the guardian must also provide the six-digit verification code shown in the student waiting screen.

`GET /auth/guardian/consent/platform-participation/{student_profile_id}`

Returns the current guardian-managed platform participation consent state for a linked student, or `pending` when no consent has been recorded yet.

`POST /auth/guardian/consent/platform-participation`

Records guardian platform-participation consent for a linked minor student and activates the student account when granted.

`GET /auth/guardian/consent/parent-summary-sharing/{student_profile_id}`

Returns the latest parent-summary sharing consent record for a linked student, or a `pending` state if no consent has been recorded yet.

`POST /auth/guardian/consent/parent-summary-sharing`

Records guardian consent for parent-safe weekly summary sharing for a linked student.

`GET /auth/approval-requests`

Lists approval requests visible to the current reviewer role.

`POST /auth/approval-requests/{request_id}/decision`

Approves, rejects, or revokes a pending approval request.

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
- `school_id` and `school_name` when scoped
- `user_metadata`
- `student_metadata`

Current frontend use:

- the unified app uses this response to decide which role experience to open after shared login
- the student flow reads `student_metadata.wellbeing_profile` so daily check-in gating and personalization do not rely on device-only storage

### Shared app content and support

`GET /mobile/support-contacts`

Returns active support contacts visible to the current app audience, ordered with school-specific contacts first when the actor is school-scoped.

`GET /mobile/content/feed`

Returns published, role-safe content items for the current app audience.

Supported query parameters:

- `content_type`
- `limit`

Counselor and BAHA admin roles can also inspect other audiences through:

- `audience_app`
- `age_cohort`

`GET /mobile/content/{content_item_id}`

Returns the published content detail payload for one content item, including the stored content body and review metadata.

### Student app

`GET /mobile/student/weekly-summary/latest`

Returns the latest private student weekly summary for the authenticated student, which is the read model intended to back the personal trend dashboard.

`GET /mobile/student/checkin-templates`

Returns active student check-in templates filtered by the actor's age cohort.

`GET /mobile/student/checkin-templates/{template_id}`

Returns one student check-in template including ordered question definitions so the client can render a live submission form.

Important current usage note:

- the student app now uses template `metadata` and question `metadata` to drive conditional follow-up behavior such as `show_when`, `show_when_any`, and profile-gated options

`GET /mobile/student/modules`

Returns active approved student learning modules plus latest progress for the current student.

Important response field:

- `content_item_id` is included so the mobile client can open `GET /mobile/content/{content_item_id}` without title-based matching

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

Important current usage note:

- the student app now sends `selected_options`, `numeric_value`, and `normalized_value`
- `normalized_value` currently carries the choice label, factor dimension, normalized burden score, and whether the answer belongs to the six-factor daily core

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

If a dedicated `parent_weekly_summaries` row does not exist yet, the backend derives a parent-safe summary from the latest student weekly summary instead of returning raw entries.

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

`POST /mobile/chat/sessions/{session_id}/messages/stream`

Streams Buddy chat events for the mobile client while still persisting the final assistant message at the end.

Stream behavior:

- first emits an `ack` event with the persisted user message
- then emits zero or more `delta` events as assistant text arrives from OpenAI
- finally emits a `complete` event with the persisted assistant message and retrieval metadata
- emits an `error` event if generation fails after the stream has started

### Counselor / BAHA app

`GET /mobile/counselor/queue`

Returns:

- open escalation cases
- unresolved monitoring signals without a case
- open help requests

Current access behavior:

- `baha_admin` can view the full queue
- counselors and administrators are limited to cases, signals, and help requests from their own school scope

`GET /mobile/counselor/cases/{case_id}`

Returns case details, notes, events, and assignments.

Current access behavior:

- `baha_admin` can view any case
- counselors and administrators can only view school-scoped cases

`POST /mobile/counselor/cases/{case_id}/notes`

Adds a case note and records a case event.

Current validation:

- the case must already be visible to the actor
- notes cannot be added to `resolved`, `closed`, or `cancelled` cases

`GET /mobile/counselor/dashboard/latest`

Returns the latest BAHA pilot dashboard metric snapshot.

Current access behavior:

- school-scoped counselors first try to read the latest school metric
- if no school metric exists, the endpoint falls back to the latest global metric
- `baha_admin` can read the latest global metric directly

## 4. Current Limitations

These endpoints do not yet provide:

- fully provisioned external auth credentials
- guardian-to-student context switching beyond the active link model
- teacher/student individual override views
- complete counselor assignment workflows
- content review queue mutation workflows
- threshold-configuration workflows
- final hosted object-storage wiring
- consent history/audit views beyond the latest guardian-managed state

Those are next-phase backend tasks.

## 5. Flutter Integration Notes

For local Android emulator use:

- `http://10.0.2.2:8000`

For physical devices on the same network use:

- `http://<your-lan-ip>:8000`

Do not call Postgres directly from Flutter.
