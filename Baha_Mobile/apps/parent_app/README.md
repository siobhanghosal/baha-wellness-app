# BAHA Parent App

## Purpose

This app is the guardian-facing mobile client in the BAHA Flutter workspace.

The current implemented slice covers:

- development identity bootstrap
- session restore through the shared auth/session package
- linked-student selection
- parent-safe weekly summary retrieval
- parent resources feed and detail view
- guardian summary-sharing consent management
- platform participation consent action
- support contact visibility

## Run Locally

Install dependencies:

```bash
flutter pub get
```

Run from Android emulator against the local backend:

```bash
flutter run \
  --dart-define=BAHA_API_BASE_URL=http://10.0.2.2:8000 \
  --dart-define=BAHA_DEV_EXTERNAL_AUTH_ID=supabase-guardian-demo \
  --dart-define=BAHA_DEV_AUTH_EMAIL=guardian.demo@baha.local
```

Run from a physical Android device on the same Wi-Fi network:

```bash
flutter run \
  --dart-define=BAHA_API_BASE_URL=http://<your-lan-ip>:8000 \
  --dart-define=BAHA_DEV_EXTERNAL_AUTH_ID=supabase-guardian-demo \
  --dart-define=BAHA_DEV_AUTH_EMAIL=guardian.demo@baha.local
```

## Current Backend Dependencies

This app currently depends on these backend routes:

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

Implementation note:

- `POST /auth/guardian/consent/platform-participation` currently returns the linked student's onboarding snapshot from the backend, not the guardian's own session snapshot
- the parent app therefore treats that endpoint as an action-and-refresh workflow, not as a source of guardian runtime identity

## Current Limitations

- guardian bootstrap is not yet a full guided UI flow; the current slice assumes a seeded guardian demo identity
- notification history and richer privacy controls are still future slices
