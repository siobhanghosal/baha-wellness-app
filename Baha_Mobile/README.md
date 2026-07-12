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
- student app feature slice 4:
  - support contacts
  - help request submission
  - latest submitted support request confirmation
- student app feature slice 5:
  - Buddy session list
  - Buddy session creation
  - Buddy message history
  - Buddy message send and assistant reply
- student app corrective UI rewrite:
  - startup screens now follow the `Solomon_UI_Version1` visual language
  - ready shell now uses the reference dashboard, explore, Buddy, and profile structure
  - reference color system, motion, glass cards, confetti, and bottom navigation now exist in the real student app
  - prototype actions are now mapped either to real backend screens or to finished student utility screens instead of dead taps
  - check-in, learn, support, and live Buddy drill-down screens now use the same reference visual language
  - student metric insight screens, local wellness tools, notifications, calendar, and settings now exist inside the same reference visual system
  - deeper student flows now use retryable screen-specific error states instead of raw fallback failures
  - the Learn experience now organizes backend content into continue/recommended/recent/quick-guide sections with richer content-block rendering
  - the Explore learning cards are now meant to open focused theme lanes instead of one generic Learn list
- parent app feature slice 1:
  - guardian dev identity bootstrap
  - linked-student list
  - parent-safe weekly summary
  - parent resources feed and resource detail
  - guardian summary-sharing consent status and updates
  - platform participation consent action
  - support contacts in settings
- teacher and counselor placeholder shells

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
7. adaptive daily check-in rendering driven by backend question metadata plus a one-time local wellbeing profile
8. factor-specific trend derivation for:
   - sleep
   - energy
   - mood
   - stress
   - physical wellbeing
   - connectedness

Student feature slice 3 currently supports:

1. `GET /mobile/content/feed`
2. `GET /mobile/content/{content_item_id}`
3. `GET /mobile/student/modules`
4. `POST /mobile/student/modules/{module_id}/progress`

Student feature slice 4 currently supports:

1. `GET /mobile/support-contacts`
2. `POST /mobile/student/help-requests`

Student feature slice 5 currently supports:

1. `GET /mobile/chat/sessions`
2. `POST /mobile/chat/sessions`
3. `GET /mobile/chat/sessions/{session_id}/messages`
4. `POST /mobile/chat/sessions/{session_id}/messages`

Student corrective UI rewrite currently supports:

1. reference-style splash, auth entry, bootstrap, waiting, and error screens
2. reference-style student shell with:
   - Home
   - Explore
   - Buddy
   - Profile
3. theme toggle persistence
4. reference action cards mapped to working app routes where backend support already exists
5. reference-style detail treatment across:
   - check-in hub
   - check-in form
   - check-in submission detail
   - learn hub
   - module detail
   - content detail
   - support request flow
   - Buddy session list
   - Buddy live chat
6. one-time local wellbeing profile setup and editing from settings
7. tracked-factor charts derived from real submitted check-in detail with demo fallback when history is empty
6. finished student shell utility screens for:
   - weekly metric insights
   - emotion wheel
   - calm breathing
   - friendship scenario practice
   - notifications
   - calendar/planning
   - settings and privacy overview
7. richer Learn/content polish:
   - expanded seeded student course corpus
   - continue learning lane
   - recommended modules lane
   - recently opened lane
   - quick guides and prompts lane
   - richer backend block rendering for module/content detail
   - theme-focused Learn entry points for Sleep, Digital Wellness, Peer Pressure, and Exam Stress

Parent feature slice 1 currently supports:

1. splash and session restore
2. development identity capture using `X-BAHA-External-Auth-Id`
3. `GET /auth/onboarding-state`
4. `GET /mobile/me`
5. `GET /mobile/parent/students`
6. `GET /mobile/parent/students/{student_profile_id}/weekly-summary/latest`
7. `GET /mobile/content/feed`
8. `GET /mobile/content/{content_item_id}`
9. `GET /auth/guardian/consent/parent-summary-sharing/{student_profile_id}`
10. `POST /auth/guardian/consent/parent-summary-sharing`
11. `POST /auth/guardian/consent/platform-participation`
12. `GET /mobile/support-contacts`

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

Install parent app dependencies:

```bash
cd Baha_Mobile/apps/parent_app
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

Run parent app against local backend from Android emulator:

```bash
flutter run \
  --dart-define=BAHA_API_BASE_URL=http://10.0.2.2:8000 \
  --dart-define=BAHA_DEV_EXTERNAL_AUTH_ID=supabase-guardian-demo \
  --dart-define=BAHA_DEV_AUTH_EMAIL=guardian.demo@baha.local
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
  - `GET /mobile/support-contacts`
  - `POST /mobile/student/help-requests`
  - `GET /mobile/chat/sessions`
  - `POST /mobile/chat/sessions`
  - `GET /mobile/chat/sessions/{session_id}/messages`
  - `POST /mobile/chat/sessions/{session_id}/messages`
  - `GET /mobile/parent/students`
  - `GET /mobile/parent/students/{student_profile_id}/weekly-summary/latest`
  - `GET /auth/guardian/consent/parent-summary-sharing/{student_profile_id}`
  - `GET /mobile/content/feed`
  - `GET /mobile/content/{content_item_id}`
- student Android debug APK builds successfully at:
  - [app-debug.apk](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Mobile/apps/student_app/build/app/outputs/flutter-apk/app-debug.apk)

## Next Slice

Build next in this order:

1. teacher app first real slice
2. counselor app first real slice
3. polish or tighten any remaining student micro-interactions discovered during device testing
