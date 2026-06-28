# BAHA UI to Backend Integration Plan

## 1. Purpose

This document translates the `Solomon_UI_Version1` Flutter prototype into a backend-compatible implementation plan.

It is the bridge between:

- the PRD in [BAHA_Project_PRD_v2.md](/Users/sudharshan/Desktop/PES/RF Internship/BAHA_Project_PRD_v2.md)
- the current backend contract in [MOBILE_API_SURFACES.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/MOBILE_API_SURFACES.md)
- the current backend handoff note in [BACKEND_HANDOFF_FOR_FLUTTER.md](/Users/sudharshan/Desktop/PES/RF Internship/Baha_Data/docs/BACKEND_HANDOFF_FOR_FLUTTER.md)
- the visual reference implementation on the Git branch `origin/Solomon_UI_Version1`

The key decision is:

- keep the prototype visual language and interaction direction where it fits
- do not treat that branch as production-ready app logic
- rebuild app behavior around the PRD and backend contracts

## 2. Non-Negotiable Product Constraints From The PRD

These constraints come directly from the PRD and override prototype convenience:

- the product ships as four separate mobile apps: Student, Parent, Teacher, and BAHA/Counselor
- stakeholder apps are not role-switched views inside one shared app
- student presentation age cohort and legal consent band are separate concepts
- users aged 9-17 follow the minor consent flow
- users aged 18-19 follow the self-consent flow
- raw student check-in data remains private by default
- parent, teacher, and BAHA/Counselor views consume role-safe summaries and workflow data
- chatbot, escalation, and consent behavior must be enforced server-side

That means the current prototype can be reused as a design system and screen reference, but not as the final application architecture.

## 3. Current Compatibility Assessment

### 3.1 What already aligns well

- Student check-ins
- student learning modules
- student help requests
- student chat sessions and persisted messages
- parent linked-student view
- parent weekly summary
- teacher class list
- teacher class student list
- teacher cohort summary
- teacher pastoral flag creation
- counselor queue
- counselor case detail and notes

### 3.2 What exists visually but not functionally in the prototype

- real onboarding and consent gating
- real account approval flow
- counselor app surface
- role-safe published content feeds for parent, teacher, and BAHA
- pilot analytics and command-center metrics
- student trend summary endpoint for the dashboard

### 3.3 What stays frontend-local for now

These do not need backend ownership yet:

- theme mode persistence
- avatar selection visuals
- decorative confetti and transitions
- badge visuals and celebratory UI
- generic detail-page presentation scaffolding

## 4. Recommended Frontend Architecture

Use one shared Flutter workspace, but build it as four app targets:

- `student_app`
- `parent_app`
- `teacher_app`
- `counselor_app`

Shared packages should contain:

- design tokens
- reusable widgets
- typography, color, and motion primitives
- API client and DTO layer
- auth/session plumbing
- shared content rendering blocks

Do not share:

- navigation shells across all apps
- stakeholder-specific task flows
- student interaction language with parent, teacher, or counselor surfaces

The existing `Solomon_UI_Version1` branch is best treated as:

- a visual component library reference
- a screen-layout reference
- a copy and interaction-tone reference

It should not be treated as the final navigation, auth, or backend integration structure.

## 5. Screen Mapping By App

### 5.1 Student App

#### Current prototype surfaces

- splash
- fake login/signup/OTP
- onboarding
- avatar selection
- home dashboard
- discover grid
- BAHA Buddy
- profile
- generic detail pages

#### Backend-compatible implementation target

- splash: local only
- auth entry: replace fake login with backend-backed bootstrap and onboarding-state flow
- onboarding: use `/auth/bootstrap`, `/auth/onboarding-state`, and guardian consent steps where required
- home dashboard:
  - `GET /mobile/me`
  - `GET /mobile/student/weekly-summary/latest`
  - `GET /mobile/student/checkins`
- discover:
  - `GET /mobile/student/modules`
  - `GET /mobile/content/feed`
- check-in detail and submission:
  - `GET /mobile/student/checkin-templates`
  - `GET /mobile/student/checkin-templates/{template_id}`
  - `POST /mobile/student/checkins`
- BAHA Buddy:
  - `GET /mobile/chat/sessions`
  - `POST /mobile/chat/sessions`
  - `GET /mobile/chat/sessions/{session_id}/messages`
  - `POST /mobile/chat/sessions/{session_id}/messages`
- help pathway:
  - `POST /mobile/student/help-requests`
  - `GET /mobile/support-contacts`
- profile/settings:
  - `GET /mobile/me`
  - onboarding-state driven privacy and consent status

#### Remaining frontend-local behavior

- avatar selection
- animated wellness tiles and celebratory motion
- local wellness tools:
  - emotion wheel
  - calm breathing
  - friendship scenario practice
- notification center composition
- badge and level visuals
- theme switching

#### Implemented so far in the real Flutter workspace

- student startup screens are now rebuilt in the `Solomon_UI_Version1` visual language instead of the earlier plain backend harness
- the student ready shell now uses the reference dashboard, explore grid, Buddy surface, and profile shell
- prototype taps are now routed either into real backend screens or into finished student-specific utility screens, rather than dead buttons
- the main student backend flows now also use the same reference visual treatment:
  - check-ins
  - learning detail
  - support request flow
  - live Buddy chat
- the Learn hub is now moving from a flat list into a product-style content experience:
  - continue-learning lane
  - recommended modules lane
  - recently opened lane
  - quick guides and prompts
  - theme-based browsing
- the student reference Learn cards should now be treated as theme entries, not
  generic links:
  - Sleep Reset -> `theme=Sleep`
  - Digital Wellness -> `theme=Digital Wellness`
  - Peer Pressure -> `theme=Peer Pressure`
  - Exam Stress -> `theme=Exam Stress`
- student module and content detail rendering now supports richer block-driven presentation from the backend:
  - headings
  - bullet lists
  - checklists
  - callouts
  - reflection prompts
- module progress is now moving away from arbitrary percentages toward
  section-aware progress metadata from the backend
- the remaining student reference surfaces that do not yet have backend ownership now still behave like complete app features:
  - weekly insight drill-down screens for dashboard metrics
  - a student notification center
  - a backend-informed calendar/planning view
  - a real settings screen wired to onboarding state, theme mode, and identity switching
  - finished local wellness tool screens for emotion naming, breathing reset, and friendship scenarios
- deep student feature pages now have retryable, screen-specific error states rather than raw fallback errors
- theme mode now propagates across pushed student routes instead of stopping at the home shell
- student-selected age/gender presentation preferences are now stored locally for repeat app launches

#### Current integration gap

- the student app now broadly tracks the reference branch across startup, shell, and core working flows
- remaining gap is mostly polish-level rather than architecture-level: device-specific spacing, motion tuning, and any still-unimplemented prototype-only behaviors such as richer avatar and badge systems

#### Remaining backend gaps after this slice

- game runtime endpoints
- richer student profile editing
- finer-grained trend history beyond latest summary
- dedicated module sections/steps read endpoint if the app later needs backend-authored section navigation instead of content-block-driven flow

Content strategy note:

- the deeper rationale for how the raw corpus should become engaging student
  learning material is documented in
  [STUDENT_LEARNING_CONTENT_STRATEGY.md](./STUDENT_LEARNING_CONTENT_STRATEGY.md)

### 5.2 Parent App

#### Current prototype surfaces

- home
- reports
- resources
- settings

#### Backend-compatible implementation target

- home:
  - `GET /mobile/parent/students`
  - `GET /mobile/parent/students/{student_profile_id}/weekly-summary/latest`
- consent controls:
  - `GET /auth/guardian/consent/parent-summary-sharing/{student_profile_id}`
  - `POST /auth/guardian/consent/parent-summary-sharing`
  - `POST /auth/guardian/consent/platform-participation`
- resources:
  - `GET /mobile/content/feed`
  - `GET /mobile/content/{content_item_id}`
- support/help references:
  - `GET /mobile/support-contacts`

#### Implemented so far in the real Flutter workspace

- development identity bootstrap
- guardian linked-student picker
- parent-safe weekly summary view
- parent resource list and detail view
- summary-sharing consent read and update flow
- platform participation consent action
- settings view with support contacts

Implementation note:

- the current backend response for guardian platform-participation consent is a linked-student onboarding snapshot, so the app should use this as an action-and-refresh flow, not as a guardian identity refresh

#### Notes

- the prototype “reports” tab should be backed by parent-safe summaries and conversation guides, not raw check-ins
- the parent app must never surface raw student responses

#### Remaining backend gaps after this slice

- explicit parent notification history
- richer privacy-tier configuration UI contract

### 5.3 Teacher App

#### Current prototype surfaces

- classes
- students
- tasks
- reports

#### Backend-compatible implementation target

- classes:
  - `GET /mobile/teacher/classes`
- students:
  - `GET /mobile/teacher/classes/{class_id}/students`
  - `POST /mobile/teacher/pastoral-flags`
- reports:
  - `GET /mobile/teacher/classes/{class_id}/cohort-summary/latest`
- resources/tasks:
  - `GET /mobile/content/feed`
  - `GET /mobile/content/{content_item_id}`
  - `GET /mobile/support-contacts`

#### Notes

- the UI should not imply unrestricted individual student wellness visibility
- student detail views in the teacher app must remain pastoral and workflow-oriented, not diagnostic

#### Remaining backend gaps after this slice

- referral workflow status objects
- teacher notification history

### 5.4 BAHA/Counselor App

#### Prototype gap

The current prototype uses an `admin` shell instead of a true BAHA/Counselor app. The PRD requires a distinct BAHA/Counselor operational app.

#### Backend-compatible implementation target

- support queue:
  - `GET /mobile/counselor/queue`
- case detail:
  - `GET /mobile/counselor/cases/{case_id}`
  - `POST /mobile/counselor/cases/{case_id}/notes`
- account approvals:
  - `GET /auth/approval-requests`
  - `POST /auth/approval-requests/{request_id}/decision`
- content tab:
  - `GET /mobile/content/feed`
  - `GET /mobile/content/{content_item_id}`
- analytics/command center:
  - `GET /mobile/counselor/dashboard/latest`
- crisis and support directory:
  - `GET /mobile/support-contacts`

#### Notes

- the BAHA/Counselor app should visually preserve the darker operational style from the prototype admin shell
- the app should be renamed in implementation and documentation from `admin` to `counselor` or `baha`

#### Remaining backend gaps after this slice

- content review queue workflows
- threshold configuration workflows
- case assignment mutation flows

## 6. Immediate Backend Work Required For UI Parity

The next backend slices should move in this order:

1. expose student weekly summary to mobile
2. expose role-safe published content feeds and content detail
3. expose support contacts to mobile
4. expose BAHA pilot dashboard metrics to the counselor app
5. improve demo seed coverage for approval and review-oriented UI

This order supports the most prototype screens while staying consistent with the PRD.

## 7. Immediate Frontend Work Required

When Flutter development starts, the frontend developer should:

1. keep the current visual direction from `Solomon_UI_Version1`
2. split the product into four apps or four app targets immediately
3. replace fake auth with onboarding-state-driven routing
4. map each app shell to real API contracts
5. keep decorative or presentation-only state local until product requirements demand persistence

## 8. Definition Of "Compatible Enough" For Frontend Handoff

The backend is ready for meaningful Flutter integration when:

- each stakeholder app has a real identity and onboarding path
- each main dashboard has at least one real backend read model
- student check-in and chat flows are live
- parent consent and summary flows are live
- teacher class and flagging flows are live
- counselor queue and case review flows are live
- the role-safe content feed and support contacts are available

The work in this repository should aim for that standard rather than trying to make the prototype branch itself production-ready.
