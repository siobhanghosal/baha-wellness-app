# BAHA App Flow Architecture

## 1. Purpose

This document defines the end-to-end application flow architecture for the BAHA mobile product.

It is the development blueprint for:

- one unified BAHA mobile app
- role-based student, parent/guardian, teacher, and counselor experiences inside that app

It should be read together with:

- [BAHA_Project_PRD_v2.md](/Users/sudharshan/Desktop/PES/RF Internship/BAHA_Project_PRD_v2.md)
- [UI_BACKEND_INTEGRATION_PLAN.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/UI_BACKEND_INTEGRATION_PLAN.md)
- [SCREEN_API_MATRIX.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/SCREEN_API_MATRIX.md)
- [STORY_WORLD_AND_GAMES_PLAN.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/STORY_WORLD_AND_GAMES_PLAN.md)
- [BACKEND_HANDOFF_FOR_FLUTTER.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/BACKEND_HANDOFF_FOR_FLUTTER.md)

The goal is to lock the app flow before building screens so implementation does not drift away from the PRD.

## 2. Core Product Rules

These rules are architectural, not optional:

- the product now ships as one role-switched app, not four separately installed apps
- the first screen asks who the app is for before sign-in or registration
- student presentation cohort and legal consent band are separate
- users aged 9-17 follow the minor flow
- users aged 18-19 follow the self-consent flow
- privacy and safeguarding logic is enforced server-side
- student onboarding baseline questions are captured during account creation, not when opening the daily check-in
- parent and teacher apps consume summaries and workflow data, not raw student data
- the counselor app is an operational workflow app, not a student-facing extension

## 3. Shared Runtime State Model

The unified app should use this high-level startup state machine:

1. splash
2. session restore
3. role selection if no session exists
4. auth identity check
5. onboarding-state fetch
6. route to blocked, onboarding, approval-pending, or active-app flow

Shared state buckets:

- device session state
- auth token or local dev identity bridge
- actor identity
- role entitlement
- onboarding status
- approval status
- consent status
- connectivity state

Shared blocked states:

- unauthenticated
- onboarding incomplete
- guardian consent required
- self-consent required
- approval pending
- account inactive
- offline unsupported for requested action

## 4. Student Experience Flow

### 4.1 Entry Flow

The student experience starts with:

1. splash
2. ask who the app is for if there is no session
3. restore session if available
4. call `GET /auth/onboarding-state`
5. branch by returned `next_step`

Expected routing branches:

- `bootstrap`
- `privacy_acknowledgement`
- `guardian_linking`
- `guardian_consent_pending`
- `self_consent_required`
- `approval_pending` only if future policy requires it
- `ready`

### 4.2 Student Onboarding Flow

The student onboarding sequence should be:

1. role selection
2. sign-in or registration choice
3. account basics
4. one-time wellbeing baseline during registration
5. age cohort and consent routing
6. privacy explanation
7. acknowledgment of privacy and override rules
8. consent branch
9. dashboard unlock

Minor branch:

1. student submits account + onboarding baseline
2. backend marks account pending if guardian consent is required
3. guardian consent route is initiated
4. student sees waiting state
5. unlock once consent is granted

Adult branch:

1. student submits account + onboarding baseline
2. self-consent acknowledgment is captured
3. account becomes active
4. dashboard unlocks immediately

### 4.3 Student Primary Navigation

Release-1 primary areas:

- Home
- Check-In
- Learn
- Buddy
- Profile

Recommended navigation logic:

- Home is the default landing screen
- Check-In is always reachable from Home
- Buddy and Help must be reachable from multiple entry points
- Profile contains privacy reminders, consent state, and app preferences

### 4.4 Student Home Flow

Home should show:

- latest weekly summary
- trend headline
- next recommended action
- recent check-in status
- quick entry to check-in
- quick entry to Buddy
- quick entry to support

Flow:

1. fetch `GET /mobile/me`
2. fetch `GET /mobile/student/weekly-summary/latest`
3. fetch recent check-ins if needed
4. render fallback state if summary is unavailable

### 4.5 Student Check-In Flow

Flow:

1. ensure the student onboarding baseline already exists
2. fetch `GET /mobile/student/checkin-templates`
3. open selected template detail
4. fetch `GET /mobile/student/checkin-templates/{template_id}`
5. render the universal six-factor daily pulse
6. adapt wording by age band and reveal only the follow-up questions whose `show_when` conditions are met
7. submit using `POST /mobile/student/checkins`
8. return to updated summary or confirmation screen

Required states:

- first-time check-in
- onboarding-baseline-missing gate only for legacy student accounts
- adaptive daily check-in
- partial progress local state
- submission success
- submission retry on network failure

### 4.6 Student Learn Flow

Flow:

1. fetch `GET /mobile/content/feed` for student cards and lightweight discovery content
2. fetch `GET /mobile/student/modules`
3. open module detail from content or module list
4. fetch `GET /mobile/content/{content_item_id}` if needed
5. update progress with `POST /mobile/student/modules/{module_id}/progress`

### 4.7 Student Buddy Flow

Flow:

1. fetch `GET /mobile/chat/sessions`
2. create session if none exists
3. fetch `GET /mobile/chat/sessions/{session_id}/messages`
4. send live chat messages through `POST /mobile/chat/sessions/{session_id}/messages/stream`
5. show `ack`, `delta`, and `complete` events in the same Buddy thread so the assistant reply appears progressively
6. backend uses conversational OpenAI for general support messages and retrieval-grounded OpenAI for advice-style wellbeing questions
7. if retrieval is weak, backend falls back to conversational OpenAI instead of a cold refusal
8. if emergency language is detected, backend creates the signal and escalation case

Frontend rule:

- do not implement client-side crisis logic beyond UI messaging and connectivity handling
- do not implement client-side chatbot logic or direct LLM calls

### 4.8 Student Games Flow

Release-1 student games should be treated as two different categories:

- lightweight local wellness tools
- backend-aware progressive games

Initial game set:

- Comet Sequence
- Calm Breathing
- Focus Catch
- Story World

Flow for local tools:

1. open tool from Home or Explore
2. run the interaction locally
3. optionally store local-only completion state now
4. later persist signals and completion through the game runtime

Current local-tool intent:

- `Comet Sequence`
  short-term memory and visual attention through repeat-the-pattern play
- `Calm Breathing`
  paced reset routine with timed inhale/hold/exhale guidance
- `Focus Catch`
  visual tracking and hand-eye coordination through a moving tap target

Flow for Story World:

1. open Story World from the student game/discovery area
2. backend resolves the authenticated `student_profile_id`
3. fetch or create the current Story World state
4. open the current location, scene, and progress
5. submit a free-text turn
6. backend stores the turn and returns the next safe grounded scene
7. backend records any non-diagnostic gameplay signals server-side

Architecture rules:

- Story World must use the current student auth model
- Story World must not use a detached player-key identity
- Story World must not depend on external OpenAI APIs
- age-band differences should be implemented through content packs and presentation variants
- gameplay signals are for insight/support workflows only and must never be shown as child-facing scores

### 4.9 Student Help Flow

Flow:

1. open help entry point from Home or Buddy
2. fetch `GET /mobile/support-contacts`
3. create request using `POST /mobile/student/help-requests`
4. show confirmation and support options

### 4.10 Student Offline Rules

Offline-allowed:

- cached dashboard shell
- cached static content already fetched
- local draft answers before submission

Offline-blocked:

- Buddy messaging
- help request submission
- escalation-aware contact updates
- fresh weekly summary fetch

## 5. Parent App Flow

### 5.1 Entry Flow

The Parent App follows the same shared startup sequence:

1. splash
2. restore session
3. `GET /auth/onboarding-state`
4. route to bootstrap, linking, consent work, approval wait, or dashboard

### 5.2 Parent Onboarding Flow

Flow:

1. parent identity bootstrap
2. linked student discovery or student code + verification-code linking
3. relationship confirmation
4. consent authority state
5. privacy and summary-sharing setup
6. dashboard entry

### 5.3 Parent Primary Navigation

Release-1 primary areas:

- Home
- Student Summary
- Resources
- Settings

### 5.4 Parent Home Flow

Flow:

1. fetch `GET /mobile/parent/students`
2. render link / approval / summary status for each linked student
3. fetch `GET /mobile/parent/students/{student_profile_id}/weekly-summary/latest`
4. render consent-gated summary with weekly trends, watch areas, and alerts only

### 5.5 Parent Consent Flow

Consent work should be reachable both during onboarding and later in settings.

Flow:

1. read current platform-participation and summary-sharing states
2. update summary-sharing consent if required
3. update platform participation consent if minor onboarding is blocked
4. reflect outcome in parent summary visibility

### 5.6 Parent Resource Flow

Flow:

1. fetch `GET /mobile/content/feed` for parent-safe guides
2. open detail with `GET /mobile/content/{content_item_id}`
3. keep content rendering lightweight and role-safe

### 5.7 Parent Settings Flow

Settings should contain:

- linked students
- consent status
- privacy reminders
- support contacts
- session controls

## 6. Teacher App Flow

### 6.1 Entry Flow

The Teacher App startup branches should include:

- bootstrap
- approval pending
- active dashboard

Unlike the student flow, teacher activation requires BAHA-approved workflow support.

### 6.2 Teacher Primary Navigation

Release-1 primary areas:

- Classes
- Students
- Reports
- Resources

### 6.3 Class Flow

Flow:

1. fetch `GET /mobile/teacher/classes`
2. select class
3. fetch `GET /mobile/teacher/classes/{class_id}/students`
4. fetch `GET /mobile/teacher/classes/{class_id}/cohort-summary/latest`

### 6.4 Pastoral Input Flow

Flow:

1. select class
2. select student from assigned class
3. open pastoral flag form
4. submit via `POST /mobile/teacher/pastoral-flags`
5. show confirmation, not risk labeling

### 6.5 Teacher Resource Flow

Flow:

1. fetch `GET /mobile/content/feed` for teacher-safe content
2. open detail with `GET /mobile/content/{content_item_id}`
3. optionally route to support contacts

### 6.6 Teacher Guardrails

The Teacher App must not:

- show raw student check-in answers
- show unrestricted student mental-health detail
- imply diagnostic authority

## 7. BAHA/Counselor App Flow

### 7.1 Entry Flow

The BAHA/Counselor App startup branches are:

- bootstrap
- approval pending
- active operations dashboard

### 7.2 Primary Navigation

Release-1 primary areas:

- Queue
- Cases
- Content
- Analytics
- Approvals

### 7.3 Support Queue Flow

Flow:

1. fetch `GET /mobile/counselor/queue`
2. separate views for:
   - open cases
   - unassigned signals
   - open help requests
3. open selected case detail

### 7.4 Case Detail Flow

Flow:

1. fetch `GET /mobile/counselor/cases/{case_id}`
2. render case overview, events, notes, assignments
3. add note with `POST /mobile/counselor/cases/{case_id}/notes`

### 7.5 Analytics Flow

Flow:

1. fetch `GET /mobile/counselor/dashboard/latest`
2. render school metrics if school-scoped data exists
3. fallback to global metrics otherwise

### 7.6 Approval Flow

Flow:

1. fetch `GET /auth/approval-requests`
2. inspect pending teacher and counselor approvals
3. decide using `POST /auth/approval-requests/{request_id}/decision`

### 7.7 Content Flow

Release-1 content flow is read-only in the app client.

Flow:

1. fetch `GET /mobile/content/feed`
2. open detail with `GET /mobile/content/{content_item_id}`

Later operational mutations:

- review queue actions
- publish changes
- threshold configuration

## 8. Cross-App Event Architecture

Important cross-app interactions:

- student check-in affects student summary
- student help request appears in counselor queue
- emergency Buddy message creates signal and case
- teacher pastoral flag enriches counselor workflow
- guardian consent changes parent summary visibility
- BAHA approval changes teacher or counselor app access

These flows must be server-driven and eventually observable through UI refresh or notification behavior.

## 9. Error, Empty, and Waiting States

These states should be intentionally designed in all apps:

- no network
- no seeded data yet
- consent pending
- approval pending
- no linked student
- no active class assignments
- empty support queue
- no weekly summary available yet

Critical rule:

- empty data must not look like broken data

## 10. Implementation Sequence From This Architecture

The development order should now be:

1. lock this flow architecture
2. lock the [SCREEN_API_MATRIX.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/SCREEN_API_MATRIX.md)
3. scaffold the four-app workspace
4. build vertical slice 1:
   - auth
   - onboarding
   - role routing
5. build vertical slice 2:
   - student dashboard
   - student check-in
   - student Buddy
6. build vertical slice 3:
   - parent summary
   - parent consent
7. build vertical slice 4:
   - teacher classes
   - pastoral input
8. build vertical slice 5:
   - counselor queue
   - case detail
   - approvals

This order minimizes rework and keeps the PRD constraints intact.
