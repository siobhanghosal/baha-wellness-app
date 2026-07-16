# BAHA Account Onboarding System

## 1. Canonical Identity Model

BAHA runtime identity is centered on:

- `users`
- `user_roles`
- `student_profiles`
- `guardians`
- `teacher_profiles`

Hosted auth is an external identity layer, not a second product-profile system.

Current mapping:

- bearer-token `sub` maps to `users.external_auth_id`
- if no direct match exists, the backend can link a token to exactly one existing BAHA user by email

Local development fallback for onboarding-only routes:

- `X-BAHA-External-Auth-Id`
- `X-BAHA-Auth-Email` (optional)
- `X-BAHA-Dev-Password`

For seeded local diagnostics, read-only or admin-style testing can also use:

- `X-BAHA-User-Id`

If multiple BAHA users share the same email, automatic linking is rejected.

## 2. What This Onboarding Slice Implements

The backend now supports:

- `POST /auth/bootstrap`
- `GET /auth/onboarding-state`
- `GET /auth/me`
- `POST /auth/guardian/link-student`
- `GET /auth/guardian/consent/platform-participation/{student_profile_id}`
- `POST /auth/guardian/consent/platform-participation`
- `GET /auth/guardian/consent/parent-summary-sharing/{student_profile_id}`
- `POST /auth/guardian/consent/parent-summary-sharing`
- `GET /auth/approval-requests`
- `POST /auth/approval-requests/{request_id}/decision`

This is a backend-first onboarding workflow for:

- student
- guardian
- teacher
- counselor
- administrator

Public `baha_admin` signup remains intentionally unsupported.

## 3. Approval Model

Approval requests are stored in:

- `approval_requests`

Approval is required for:

- teacher
- counselor
- administrator

Reviewer permissions:

- `baha_admin` can review all approval requests
- `administrator` can review teacher requests for their own school

Approval effects:

- approved accounts move to `users.status = 'active'`
- rejected or revoked requests keep the account out of active mobile access

## 4. Student Consent Model

Minor student participation is enforced through:

- `student_profiles.legal_consent_band`
- `consent_records` with `consent_type = 'platform_participation'`
- `users.status`

Current behavior:

- adult students can become active immediately after bootstrap
- minor students bootstrap into `users.status = 'pending'`
- every student keeps a persistent `student_code`
- students can generate a short-lived six-digit guardian-link verification code on demand
- verification codes currently expire after 30 minutes
- under-18 students who are still waiting for parent linkage receive both `student_code` and `guardian_link_verification_code` in onboarding state so the unified app can show them on the waiting screen
- a guardian with active consent authority can grant platform participation
- once granted, the backend activates the student account

This gives server-side gating even before the Flutter client exists.

## 4.1 Parent Summary Consent Model

Parent-safe weekly summary sharing is enforced through:

- `student_profiles.metadata.parent_summary_sharing_enabled`
- `consent_records` with `consent_type = 'parent_summary_sharing'`
- `student_guardian_links.consent_authority`
- `privacy_tier_settings`
- safeguarding overrides where applicable

Current behavior:

- the student must first enable parent-summary sharing from student settings
- a guardian with active consent authority can read the current parent-summary consent state
- that guardian can grant, decline, or withdraw summary sharing for a linked student
- if the student has not enabled sharing yet, the parent weekly-summary endpoint returns a clear blocked message instead of exposing data
- the parent weekly-summary endpoint continues to enforce consent plus privacy-tier checks server-side
- active safeguarding overrides can still expose the safeguarding-only summary layer even if the normal student sharing toggle is off

This means Flutter can manage parent-summary sharing through explicit auth endpoints instead of relying on manual seed data.

## 5. Guardian Linking

Guardians can link students through:

- `POST /auth/guardian/link-student`

Lookup supports:

- `student_profile_id`
- `student_code`

Current guardian-link rule:

- any student can initiate guardian linking by sharing their student code plus a short-lived verification code
- the guardian must provide the student code plus the student’s six-digit verification code
- under-18 students still require guardian platform-participation approval before the student account is fully active
- adult students can link a guardian for summary-sharing purposes without a platform-access approval step

The active relationship is stored in:

- `student_guardian_links`

Student self-service linking utilities now available:

- `GET /mobile/student/linking-state`
- `POST /mobile/student/linking-code`
- `POST /mobile/student/parent-summary-sharing`
- `DELETE /mobile/student/guardians/{guardian_id}`

These power the unified app settings flow for:

- showing the student ID
- generating or refreshing a six-digit pairing code
- deciding whether parents can view summary charts
- intentionally removing a linked parent or guardian after confirmation

Guardian self-service link management now also includes:

- `DELETE /mobile/parent/students/{student_profile_id}/link`

This lets a parent or guardian remove their own link from the parent side without touching the student account itself.

## 6. Onboarding State Contract

`GET /auth/onboarding-state` and `GET /auth/me` now return:

- whether a BAHA user exists for the identity
- identity match mode
- current account status
- assigned roles
- profile IDs
- student code and guardian-link verification code where relevant
- approval status
- consent status
- guardian-link status
- next step for the client flow

This is the backend contract the Flutter developer should use to decide whether to show:

- bootstrap/profile completion
- guardian linking
- guardian consent pending
- approval pending
- ready/active app access
- parent-summary sharing blocked by student preference

For the current development-auth mobile flow, the client also uses
`GET /auth/onboarding-state` as a preflight check before opening a session so it
can distinguish:

- valid sign-in
- missing account
- reused sign-in ID during registration
- reused email during registration

## 7. What Is Still Deferred

This slice does not yet implement:

- direct in-app profile editing beyond bootstrap
- school invitation workflows
- richer admin provisioning flows
- multi-role self-service account expansion

Those remain later backend work items.
