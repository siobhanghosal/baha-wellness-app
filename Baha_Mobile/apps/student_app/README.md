# BAHA Student App

## Purpose

This is the student-facing mobile app in the BAHA Flutter workspace.

It now combines:

- the real backend session and onboarding flow
- the real student backend slices for check-ins, learn, support, and Buddy
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
- the four Explore learning cards are now expected to open focused theme lanes
  instead of the same generic Learn feed:
  - Sleep Reset
  - Digital Wellness
  - Peer Pressure
  - Exam Stress
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

Remaining practical gap:

- this is now broadly navigable and visually consistent for device testing, but you should still use a real Android phone pass to catch spacing, overflow, and interaction polish issues that only show up on-device

## What Is Backend-Backed Now

- session restore and onboarding routing
- student bootstrap
- dashboard summary and recent check-ins
- check-in list, form, submit, and submission detail
- learning feed, module detail, content detail, and module progress writes
- expanded student demo course corpus with multiple modules, quick guides, and reflection content
- support contacts and help-request submission
- Buddy session list, session creation, message history, and live message send
- Buddy answer generation through the backend retrieval layer, with local-LLM support available when the backend is configured with `Ollama`
- calendar planning data from check-in templates and modules
- profile/settings identity and consent display from current actor and onboarding state

## What Is Intentionally Local For Now

- comet sequence memory game
- calm breathing routine
- focus catch coordination game
- notification center composition
- avatar, badges, celebratory visuals, and most gamified profile elements

These local pieces are intentional. They preserve the reference UI and give the student app a finished interaction flow while the corresponding backend/game systems are still out of scope for the current slice.

Important game note:

- `Story World` is now rebuilt into this app against the current student auth flow, not the teammate branch's detached game identity or OpenAI-dependent backend
- the governing implementation/documentation for that slice lives in:
  - [Baha_Data/docs/STORY_WORLD_AND_GAMES_PLAN.md](/Users/sudharshan/Desktop/PES/RF%20Internship/Baha_Data/docs/STORY_WORLD_AND_GAMES_PLAN.md)

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
  --dart-define=BAHA_DEV_AUTH_EMAIL=student.demo@baha.local
```

Run against the local backend from a physical Android device using `adb reverse`:

```bash
adb reverse tcp:8000 tcp:8000
flutter run \
  --dart-define=BAHA_API_BASE_URL=http://127.0.0.1:8000 \
  --dart-define=BAHA_DEV_EXTERNAL_AUTH_ID=supabase-student-demo \
  --dart-define=BAHA_DEV_AUTH_EMAIL=student.demo@baha.local
```

## Current Backend Dependencies

This app currently depends on:

- `GET /auth/onboarding-state`
- `POST /auth/bootstrap`
- `GET /mobile/me`
- `GET /mobile/student/weekly-summary/latest`
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

## Current Quality Notes

- the student app is meant to run against the local backend by default during development
- the Buddy screen uses the same existing UI, but real local-LLM responses require the backend host machine to have `Ollama` running with `qwen3:4b` pulled
- when the backend is running via `docker compose`, the API container now reaches host `Ollama` through `http://host.docker.internal:11434`
- when using a physical Android phone over USB, the app depends on `adb reverse tcp:8000 tcp:8000`
- if the USB cable is removed, backend-backed screens will stop working unless the phone is pointed to a LAN-accessible or hosted backend
- deeper student screens now have retryable error states instead of raw exception pages, but they still need real-device QA for spacing and navigation polish
- the local demo backend now includes a richer student Learn corpus seeded through `023_student_content_polish_seed.sql`
- additional theme-specific student learning seeds now exist in `024_student_theme_learning_seed.sql`
- the best reference for how the raw corpus should become student learning material is:
  - [Baha_Data/docs/STUDENT_LEARNING_CONTENT_STRATEGY.md](/Users/sudharshan/Desktop/PES/RF%20Internship/Baha_Data/docs/STUDENT_LEARNING_CONTENT_STRATEGY.md)
