# BAHA Unified App

## Purpose

This is the unified BAHA mobile app in the Flutter workspace.

It now combines:

- the real backend session and onboarding flow
- the real student backend slices for check-ins, learn, support, and Buddy
- the real guardian/parent onboarding and summary-management slice inside the same app
- a parent-facing shell with Home, Learn, Buddy, and Profile tabs inside the same unified app
- role-based routing from the first screen so student, guardian, teacher, and counselor experiences live in one shell
- the visual shell direction from `origin/Solomon_UI_Version1`

## Current UI State

The app startup and main shell have been rewritten to match the reference branch more closely:

- splash, auth entry, bootstrap, waiting, and error screens use the prototype visual language
- the ready shell now uses the reference dashboard, explore, Buddy, and profile structure
- the reference theme system, color palettes, glass panels, motion, confetti, and bottom bar are active in the real app
- deeper feature screens now also use the same visual language:
  - check-in hub, form, and submission detail
  - learn hub and content/module detail
  - support request flow
  - Buddy session list and live chat
- the Learn experience is now organized into a stronger course/content hub:
  - continue learning
  - recommended modules
  - recently opened
  - quick guides and prompts
  - theme-based browsing
- the Explore learning cards now open focused theme lanes instead of the same
  generic Learn feed:
  - Sleep Reset
  - Stress Reset / Handling Stress
  - Bullying and Boundaries
  - Healthy Gaming
  - Alcohol Safety
- content detail rendering now supports richer backend block types such as:
  - headings
  - bullet lists
  - checklists
  - callouts
  - reflection prompts
- student-only polish screens now replace the old generic placeholders:
  - weekly insight views for Mood, Sleep, Stress, and Energy
  - local mini-games/tools for Comet Sequence, Calm Breathing, and Focus Catch
  - a student notification center
  - a backend-informed calendar/planning screen
  - a real settings screen for privacy, theme, onboarding refresh, and identity switching
- theme behavior now propagates across deeper student routes instead of only the home shell
- selected age cohort and gender theme choices are now persisted locally between app launches
- darker bottom-navigation contrast and explore-card layout were adjusted for real device testing
- guardian role now lands in a dedicated parent-style shell instead of remaining on a single linking/consent page
- guardian shell theme state now uses the same live light/dark controller pattern as the student shell
- guardian Learn now includes parent-focused mini-modules across the same five topics:
  - Sleep support at home
  - Helping with stress
  - Bullying support
  - Healthy gaming boundaries
  - Alcohol safety conversations
- student learning lane practice screens now support capped user-added checklist points in addition to seeded options
- saved checklist items can now be reordered with drag and drop
- student module detail no longer asks the user to "start" a module after it is already open; the action layer is now completion-focused
- opening Buddy from the student side now goes straight into the live conversation instead of a separate landing layer

Remaining practical gap:

- this is now broadly navigable and visually consistent for device testing, but you should still use a real Android phone pass to catch spacing, overflow, and interaction polish issues that only show up on-device

## What Is Backend-Backed Now

- session restore and onboarding routing
- sign-in/register preflight validation over the current development identity bridge using sign-in ID plus password
- student bootstrap
- guardian link flow using student ID + verification code
- guardian consent flow for under-18 platform access and parent-summary sharing
- student settings flow for:
  - visible student ID
  - on-demand 6-digit pairing code generation
  - student-controlled parent summary sharing toggle
  - unpairing a linked parent/guardian after a confirmation step
- parent-safe weekly summary detail view with trends, watch areas, alerts, and support nudges only
- parent Home shell with linked-student overview, consent actions, and privacy-safe weekly narrative cards
- parent Learn starter lanes with local progress tracking
- parent Buddy sessions using the same backend chat runtime but with parent-guidance session defaults
- dashboard summary and recent check-ins
- check-in list, form, submit, and submission detail
- learning feed, module detail, content detail, and module progress writes
- expanded student demo course corpus with at least 3 modules per core topic across every student age cohort plus quick support cards
- support contacts and help-request submission
- Buddy session list, session creation, message history, and progressive live message streaming
- Buddy answer generation through the backend OpenAI runtime, with retrieval only used when grounded BAHA evidence is helpful
- calendar planning data from check-in templates and modules
- profile/settings identity and consent display from current actor and onboarding state

## What Is Intentionally Local For Now

- comet sequence memory game
- calm breathing routine
- focus catch coordination game
- notification center composition
- avatar, badges, celebratory visuals, and most gamified profile elements

These local pieces are intentional. They preserve the reference UI and give the student app a finished interaction flow while the corresponding backend/game systems are still out of scope for the current slice.

## Run Locally On Android

Install dependencies:

```bash
flutter pub get
```

Run against the local backend from Android emulator:

```bash
flutter run \
  --dart-define=BAHA_API_BASE_URL=http://10.0.2.2:8000 \
  --dart-define=BAHA_DEV_EXTERNAL_AUTH_ID=supabase-student-demo \
  --dart-define=BAHA_DEV_PASSWORD=BahaDemo123!
```

Run against the local backend from a physical Android device using `adb reverse`:

```bash
adb reverse tcp:8000 tcp:8000
flutter run \
  --dart-define=BAHA_API_BASE_URL=http://127.0.0.1:8000 \
  --dart-define=BAHA_DEV_EXTERNAL_AUTH_ID=supabase-student-demo \
  --dart-define=BAHA_DEV_PASSWORD=BahaDemo123!
```

## Current Backend Dependencies

This app currently depends on:

- `GET /auth/onboarding-state`
- `POST /auth/bootstrap`
- `GET /mobile/me`
- `GET /mobile/student/weekly-summary/latest`
- `GET /mobile/student/linking-state`
- `POST /mobile/student/linking-code`
- `POST /mobile/student/parent-summary-sharing`
- `DELETE /mobile/student/guardians/{guardian_id}`
- `GET /mobile/student/checkin-templates`
- `GET /mobile/student/checkins`
- `GET /mobile/student/checkins/{response_set_id}`
- `POST /mobile/student/checkins`
- `GET /mobile/content/feed`
- `GET /mobile/content/{content_item_id}`
- `GET /mobile/student/modules`
- `POST /mobile/student/modules/{module_id}/progress`
- `GET /mobile/support-contacts`
- `POST /mobile/student/help-requests`
- `GET /mobile/chat/sessions`
- `POST /mobile/chat/sessions`
- `GET /mobile/chat/sessions/{session_id}/messages`
- `POST /mobile/chat/sessions/{session_id}/messages`
- `POST /mobile/chat/sessions/{session_id}/messages/stream`

## Current Quality Notes

- the unified app is meant to run against the local backend by default during development
- the Buddy screen now sends messages through the streaming route so the reply bubble can fill progressively instead of waiting for one blocking response
- Buddy conversation and grounded advice both come from the backend OpenAI runtime; retrieval remains backend-local
- when using a physical Android phone over USB, the app depends on `adb reverse tcp:8000 tcp:8000`
- if the USB cable is removed, backend-backed screens will stop working unless the phone is pointed to a LAN-accessible or hosted backend
- if Buddy chat suddenly returns `404` on the stream route after a code update, rebuild/restart the backend container because the old API process is still serving the previous route set
- deeper student screens now have retryable error states instead of raw exception pages, but they still need real-device QA for spacing and navigation polish
- a newly registered student account may not have a generated weekly summary row yet; the app now falls back to a first-use placeholder dashboard instead of failing the home screen
- empty student dashboards no longer render demo factor graphs; they now stay empty until real check-ins exist
- sign-in and registration now validate reused sign-in IDs, incorrect passwords, and missing accounts before opening a session
- the backend now falls back to the live daily pulse template for older student cohorts too, so fresh `15_18` and `18_plus` accounts can open daily check-ins immediately
- under-18 student waiting screens now expose the student ID and guardian verification code needed for the guardian-link flow
- parent summaries intentionally do not show raw check-in answers; they only show high-level weekly patterns, alerts, and suggested support nudges
- parent learning content now mirrors the same five core topics as the student side with parent-focused phrasing, prompts, and home-support guidance
- parent Buddy now opens `parent_guidance` sessions and the backend prompt is audience-shaped for guardian support
- seeded multi-scenario student demo accounts are documented in:
  - [Baha_Data/docs/STUDENT_DEMO_SCENARIOS.md](/Users/sudharshan/Desktop/PES/RF%20Internship/Baha_Data/docs/STUDENT_DEMO_SCENARIOS.md)
- the local demo backend now includes a richer student Learn corpus seeded through `023_student_content_polish_seed.sql`
- additional theme-specific student learning seeds now exist in `024_student_theme_learning_seed.sql`
- the best reference for how the raw corpus should become student learning material is:
  - [Baha_Data/docs/STUDENT_LEARNING_CONTENT_STRATEGY.md](/Users/sudharshan/Desktop/PES/RF%20Internship/Baha_Data/docs/STUDENT_LEARNING_CONTENT_STRATEGY.md)
