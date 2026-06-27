# BAHA Mobile Workspace

## Purpose

This directory now contains the real Flutter monorepo for the BAHA mobile suite.

It follows the PRD requirement that BAHA ships as four separate apps on a shared codebase:

- Student App
- Parent App
- Teacher App
- BAHA/Counselor App

Primary backend and flow references:

- [APP_FLOW_ARCHITECTURE.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/APP_FLOW_ARCHITECTURE.md)
- [SCREEN_API_MATRIX.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/SCREEN_API_MATRIX.md)
- [UI_BACKEND_INTEGRATION_PLAN.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/UI_BACKEND_INTEGRATION_PLAN.md)
- [BACKEND_HANDOFF_FOR_FLUTTER.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/BACKEND_HANDOFF_FOR_FLUTTER.md)

## Workspace Structure

```text
Baha_Mobile/
  apps/
    student_app/
    parent_app/
    teacher_app/
    counselor_app/
  packages/
    baha_design_system/
    baha_api_client/
    baha_auth_session/
    baha_shared_models/
    baha_content_renderer/
```

## Current Implementation Status

Implemented now:

- real Flutter app and package skeletons
- shared design system package
- shared API client package for onboarding and actor resolution
- shared session package for:
  - local dev identity persistence
  - onboarding-state fetch
  - bootstrap submission
  - ready versus blocked routing
- student app vertical slice 1
- student app feature slice 2:
  - dashboard summary
  - check-in template list
  - check-in form
  - check-in submission
  - submitted check-in detail
- student app feature slice 3:
  - learn feed
  - module detail
  - module progress writes against the real backend
- parent, teacher, and counselor placeholder shells

Student vertical slice 1 currently supports:

1. splash and session restore
2. development identity capture using `X-BAHA-External-Auth-Id`
3. `GET /auth/onboarding-state`
4. `POST /auth/bootstrap` for student bootstrap
5. `GET /mobile/me`
6. routing to:
   - identity required
   - bootstrap required
   - waiting / blocked
   - ready shell

Student feature slice 2 currently supports:

1. `GET /mobile/student/weekly-summary/latest`
2. `GET /mobile/student/checkin-templates`
3. `GET /mobile/student/checkin-templates/{template_id}`
4. `POST /mobile/student/checkins`
5. `GET /mobile/student/checkins`
6. `GET /mobile/student/checkins/{response_set_id}`

Student feature slice 3 currently supports:

1. `GET /mobile/content/feed`
2. `GET /mobile/content/{content_item_id}`
3. `GET /mobile/student/modules`
4. `POST /mobile/student/modules/{module_id}/progress`

## Package Responsibilities

- `baha_design_system`
  Shared theme, typography, surface styling, and foundational widgets.

- `baha_api_client`
  Typed network layer for the FastAPI backend.

- `baha_auth_session`
  Session restoration, development identity persistence, onboarding-state routing, and student bootstrap flow.

- `baha_shared_models`
  Shared DTOs for onboarding state, mobile actor identity, development identity, and bootstrap requests.

- `baha_content_renderer`
  Basic rendering helpers for backend-delivered content blocks.

## Run Commands

Install dependencies:

```bash
cd Baha_Mobile/apps/student_app
flutter pub get
```

Run student app against local backend from Android emulator:

```bash
flutter run \
  --dart-define=BAHA_API_BASE_URL=http://10.0.2.2:8000
```

Run student app against local backend from a physical Android device on the same network:

```bash
flutter run \
  --dart-define=BAHA_API_BASE_URL=http://<your-lan-ip>:8000
```

Optional demo identity hints:

```bash
flutter run \
  --dart-define=BAHA_API_BASE_URL=http://10.0.2.2:8000 \
  --dart-define=BAHA_DEV_EXTERNAL_AUTH_ID=supabase-student-demo \
  --dart-define=BAHA_DEV_AUTH_EMAIL=student.demo@baha.local
```

## Verified Baseline

Verified in this workspace:

- all packages and apps resolve dependencies
- all packages and apps pass analysis
- Dart unit tests pass
- Flutter widget tests pass
- local backend responds correctly for:
  - `GET /health`
  - `GET /auth/onboarding-state`
  - `GET /mobile/me`
  - `GET /mobile/student/weekly-summary/latest`
  - `GET /mobile/student/checkin-templates`
  - `POST /mobile/student/checkins`
  - `GET /mobile/student/checkins`
  - `GET /mobile/student/checkins/{response_set_id}`
- student Android debug APK builds successfully at:
  - [app-debug.apk](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Mobile/apps/student_app/build/app/outputs/flutter-apk/app-debug.apk)

## Next Slice

Build next in this order:

1. student help request flow
2. student Buddy session list and chat
3. only after the student core path feels stable, parent summary and consent slice
