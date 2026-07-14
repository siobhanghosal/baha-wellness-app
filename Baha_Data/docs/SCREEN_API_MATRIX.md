# BAHA Screen API Matrix

## 1. Purpose

This document maps implementation screens to backend contracts, required permissions, local-only state, and known gaps.

Status meanings:

- `Ready`: backend contract exists and is usable now
- `Partial`: backend exists but screen needs frontend assumptions or extra backend work
- `Missing`: backend contract still needs to be implemented

This matrix is scoped to Release 1 from the PRD.

## 2. Shared Infrastructure Screens

| Screen ID | Screen | App | Purpose | Backend Contract | Permission | Local State | Status | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| SH-001 | Splash | All | Visual entry and session restore handoff | None | Any | Timer, startup animation | Ready | Pure client shell |
| SH-002 | Session Restore | All | Recover previous auth state | Auth provider plus `GET /auth/onboarding-state` | Authenticated identity | Token cache, startup flags | Partial | Depends on real hosted auth later |
| SH-003 | Account Bootstrap | All | Create BAHA-side profile | `POST /auth/bootstrap` | Authenticated identity | Draft form state | Ready | Shared registration path inside the unified app |
| SH-004 | Onboarding Router | All | Route to correct next step | `GET /auth/onboarding-state` | Authenticated identity | Decision-state only | Ready | Primary gatekeeper screen |
| SH-005 | Active Actor Profile | All | Resolve current role and app audience | `GET /auth/me`, `GET /mobile/me` | Active account | Cached actor info | Ready | Use after bootstrap and when entering dashboard |
| SH-006 | Support Contacts | All | Show counselor and emergency contacts | `GET /mobile/support-contacts` | Active account | None beyond caching | Ready | Now available across apps |

## 3. Student App Screens

| Screen ID | Screen | Purpose | Backend Contract | Permission | Local State | Status | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| ST-001 | Role-First Entry | Trust framing, role choice, sign-in/register split | `GET /auth/onboarding-state` | Student identity | Selected role, entry-mode toggle | Ready | Unified app now asks who the experience is for before auth |
| ST-002 | Account Creation + Baseline | Capture account basics, age cohort, consent band, and one-time onboarding baseline | `POST /auth/bootstrap` | Student identity | Draft registration form, wellbeing baseline draft | Ready | Student baseline is now submitted during registration, not at check-in open |
| ST-003 | Privacy Explanation | Explain privacy and overrides | `GET /auth/onboarding-state`, later content read model | Student identity | Acknowledgement toggle | Partial | Explicit privacy copy can later move into content system |
| ST-004 | Guardian Consent Wait | Block until guardian consent | `GET /auth/onboarding-state` | Student identity | Polling / refresh state | Ready | Minor-flow only |
| ST-005 | Self-Consent Step | Complete 18+ self-consent | `POST /auth/bootstrap`, `GET /auth/onboarding-state` | Student identity | Draft confirmation state | Partial | Self-consent mutation can be richer later |
| ST-006 | Home Dashboard | Show latest weekly summary, trend cards, and profile-aware entry points | `GET /mobile/me`, `GET /mobile/student/weekly-summary/latest`, `GET /mobile/student/checkins`, `GET /mobile/student/checkins/{response_set_id}` | Active student | Theme mode, dashboard shell | Ready | `GET /mobile/me` now returns student metadata including persisted wellbeing baseline answers |
| ST-007 | Check-In List | Show adaptive daily template and past check-ins | `GET /mobile/student/checkin-templates`, `GET /mobile/student/checkins` | Active student | Filter state | Ready | Daily check-in is gated behind completed student onboarding baseline |
| ST-008 | Check-In Detail | Render dynamic check-in form with conditional follow-ups | `GET /mobile/student/checkin-templates/{template_id}` | Active student | In-progress answer draft | Ready | Backend supplies ordered questions and metadata; client applies age-aware wording and evaluates `show_when` logic |
| ST-009 | Check-In Submit | Persist adaptive answers and normalized scores | `POST /mobile/student/checkins` | Active student | Submission retry state | Ready | Student app submits selected options plus normalized scoring metadata |
| ST-010 | Trend Detail | Expanded factor-specific trend view | `GET /mobile/student/weekly-summary/latest`, `GET /mobile/student/checkins`, `GET /mobile/student/checkins/{response_set_id}` | Active student | Chart tab state | Ready | Trends now reflect sleep, energy, mood, stress, physical wellbeing, and connectedness |
| ST-011 | Learn Feed | Discovery cards and modules | `GET /mobile/content/feed`, `GET /mobile/student/modules` | Active student | Sort/filter state | Ready | Supports theme-focused lanes via `theme`; the student reference cards should now open filtered lanes instead of one generic feed |
| ST-012 | Module Detail | Show module body and progress | `GET /mobile/content/{content_item_id}`, `POST /mobile/student/modules/{module_id}/progress` | Active student | Step progress, optimistic UI | Ready | `GET /mobile/student/modules` now exposes `content_item_id` plus section/step progress metadata for more structure-aware progress UI |
| ST-013 | Buddy Session List | Resume or start chat | `GET /mobile/chat/sessions`, `POST /mobile/chat/sessions` | Active student | Selected session | Ready | Shared chat runtime already live |
| ST-014 | Buddy Chat | Persist question/response thread | `GET /mobile/chat/sessions/{session_id}/messages`, `POST /mobile/chat/sessions/{session_id}/messages` | Active student | Draft message, scroll state | Ready | Backend now uses retrieval-grounded local LLM generation when `Ollama` is available, with deterministic fallback and emergency handling server-side |
| ST-015 | Help Request | Ask for support | `GET /mobile/support-contacts`, `POST /mobile/student/help-requests` | Active student | Draft help form | Ready | Maps to counselor queue |
| ST-016 | Profile and Settings | Theme, privacy reminders, session actions, and wellbeing profile editing | `GET /mobile/me`, `GET /auth/onboarding-state`, `POST /auth/bootstrap` | Active student | Theme and app prefs | Ready | Settings now supports selectable color palettes and student baseline edits can be written back through bootstrap metadata refresh |
| ST-017 | Avatar Selection | Visual identity only | None initially | Active student | Selected avatar | Ready | Frontend-local for now |
| ST-018 | Games Hub | Entry to Comet Sequence, Calm Breathing, Focus Catch, and Story World | Local-only tools plus authenticated Story World endpoints | Active student | Animation state, local completion state | Partial | Two local cognitive mini-games and one paced breathing tool are client-side; Story World is backend-backed through the student auth model |
| ST-019 | Story World | Progressive narrative wellness game with typed turns and safe NPC guidance | `GET /mobile/student/games/story-world/state`, `GET /mobile/student/games/story-world/scenes/{location_id}`, `POST /mobile/student/games/story-world/turns` | Active student | Draft turn text, current world, local optimistic state | Implemented | Uses current BAHA identity and consent architecture, additive runtime tables, deterministic progression, and no OpenAI dependency |

## 4. Parent App Screens

| Screen ID | Screen | Purpose | Backend Contract | Permission | Local State | Status | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| PA-001 | Parent Bootstrap | Create or restore parent account | `POST /auth/bootstrap`, `GET /auth/onboarding-state` | Parent identity | Draft form | Ready | Shared onboarding contract |
| PA-002 | Student Linking | Link parent to student | `POST /auth/guardian/link-student`, `GET /auth/onboarding-state` | Active guardian | Draft student ID, verification code, relationship | Ready | Live student-code plus verification-code flow |
| PA-003 | Parent Home | Show linked students and current summary | `GET /mobile/parent/students`, `GET /mobile/parent/students/{student_profile_id}/weekly-summary/latest` | Active guardian | Selected child context | Ready | Core parent dashboard path |
| PA-004 | Weekly Summary Detail | Show consent-gated conversation-safe summary | `GET /mobile/parent/students/{student_profile_id}/weekly-summary/latest` | Active guardian with consent | Expand/collapse UI | Ready | No raw student data |
| PA-005 | Summary Sharing Consent | Read and update parent summary sharing | `GET /auth/guardian/consent/parent-summary-sharing/{student_profile_id}`, `POST /auth/guardian/consent/parent-summary-sharing` | Active guardian | Confirmation UI | Ready | Already live |
| PA-006 | Platform Participation Consent | Activate minor student access when required | `GET /auth/guardian/consent/platform-participation/{student_profile_id}`, `POST /auth/guardian/consent/platform-participation` | Active guardian with consent authority | Confirmation UI | Ready | Important onboarding unblocker |
| PA-007 | Parent Resources Feed | Read parent-safe guides | `GET /mobile/content/feed?content_type=conversation_guide`, `GET /mobile/content/{content_item_id}` | Active guardian | Filter state | Ready | New content feed supports this directly |
| PA-008 | Parent Settings | Linked student management and privacy reminders | `GET /mobile/parent/students`, `GET /auth/onboarding-state`, `GET /mobile/support-contacts` | Active guardian | Local preference state | Partial | Rich privacy-tier editor still not fully modeled |
| PA-009 | Parent Notifications | Escalation-only alerts and reminders | Future notifications endpoint | Active guardian | Local read state | Missing | Not yet exposed server-side |

## 5. Teacher App Screens

| Screen ID | Screen | Purpose | Backend Contract | Permission | Local State | Status | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| TE-001 | Teacher Bootstrap | Create or restore teacher account | `POST /auth/bootstrap`, `GET /auth/onboarding-state` | Teacher identity | Draft form | Ready | Shared onboarding contract |
| TE-002 | Approval Pending | Hold app access until approved | `GET /auth/onboarding-state` | Teacher identity | Refresh state | Ready | Required flow |
| TE-003 | Class List | Show teacher assignments | `GET /mobile/teacher/classes` | Active teacher | Selected class | Ready | Maps directly to prototype classes tab |
| TE-004 | Class Summary | Show cohort metrics | `GET /mobile/teacher/classes/{class_id}/cohort-summary/latest` | Active teacher assigned to class | Chart state | Ready | Anonymized by design |
| TE-005 | Class Students | Show targetable students for pastoral actions | `GET /mobile/teacher/classes/{class_id}/students` | Active teacher assigned to class | Search/filter state | Ready | Not a raw wellness view |
| TE-006 | Pastoral Flag Form | Submit teacher observation | `POST /mobile/teacher/pastoral-flags` | Active teacher | Draft flag form | Ready | Must preserve non-diagnostic language |
| TE-007 | Teacher Resources Feed | Show teacher learning/support content | `GET /mobile/content/feed?audience_app=teacher`, `GET /mobile/content/{content_item_id}?audience_app=teacher` | Active teacher | Filter state | Ready | New content feed supports teacher track |
| TE-008 | Referral Workflow | View and manage referral status | Future referral endpoints | Active teacher | Workflow step state | Missing | PRD requires it, backend not yet exposed |
| TE-009 | Teacher Notifications | Show operational reminders | Future notifications endpoint | Active teacher | Local read state | Missing | Later slice |

## 6. BAHA/Counselor App Screens

| Screen ID | Screen | Purpose | Backend Contract | Permission | Local State | Status | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| CO-001 | Counselor Bootstrap | Create or restore counselor account | `POST /auth/bootstrap`, `GET /auth/onboarding-state` | Counselor identity | Draft form | Ready | Shared onboarding contract |
| CO-002 | Approval Pending | Hold app access until approved | `GET /auth/onboarding-state` | Counselor identity | Refresh state | Ready | Required flow |
| CO-003 | Operations Dashboard | Show latest pilot metrics | `GET /mobile/counselor/dashboard/latest` | Counselor, administrator, or BAHA admin | Date-range UI later | Ready | New endpoint now supports this |
| CO-004 | Support Queue | Show open cases, signals, and help requests | `GET /mobile/counselor/queue` | Counselor, administrator, or BAHA admin | Filter/tab state | Ready | Existing queue contract |
| CO-005 | Case Detail | Show case overview, notes, events, assignments | `GET /mobile/counselor/cases/{case_id}` | Counselor scoped to school or BAHA admin | Selected tab | Ready | Existing detail contract |
| CO-006 | Add Case Note | Append case note | `POST /mobile/counselor/cases/{case_id}/notes` | Counselor scoped to visible case or BAHA admin | Draft note | Ready | Closed cases are blocked server-side |
| CO-007 | Approval Queue | Review teacher and counselor activation requests | `GET /auth/approval-requests` | Administrator or BAHA admin | Filter state | Ready | Seeded pending approvals now exist |
| CO-008 | Approval Decision | Approve or reject activation | `POST /auth/approval-requests/{request_id}/decision` | Administrator or BAHA admin | Decision confirmation | Ready | Must refresh queue after action |
| CO-009 | Content Feed | Read operational and role-safe content | `GET /mobile/content/feed?audience_app=counselor`, `GET /mobile/content/{content_item_id}?audience_app=counselor` | Counselor, administrator, or BAHA admin | Filter state | Partial | Read-only now; operational review mutations still missing |
| CO-010 | Content Review Workflow | Review and publish content | Future content review endpoints | Counselor, administrator, or BAHA admin | Review decision draft | Missing | Required by PRD but not yet exposed |
| CO-011 | Threshold Configuration | Manage monitoring thresholds | Future threshold endpoints | BAHA admin or authorized counselor | Form draft | Missing | Required by PRD but not yet exposed |
| CO-012 | Expert Routing and Crisis Contacts | Show support and crisis routing info | `GET /mobile/support-contacts` | Counselor, administrator, or BAHA admin | None | Ready | Basic routing references available |

## 7. Release-1 Frontend Build Priority

Build the UI in this order:

1. `SH-003` to `SH-005`
2. `ST-006` to `ST-015`
3. `PA-003` to `PA-008`
4. `TE-003` to `TE-007`
5. `CO-003` to `CO-008`

Do not start with:

- games
- referral workflow polish
- content review mutations
- notification center

Those are later slices and should not block the initial implementation path.

Important current update:

- local student wellness tools now exist and are acceptable for demo use
- `Story World` is now the first meaningful backend-backed game slice in the student app
