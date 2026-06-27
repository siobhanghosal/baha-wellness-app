# BAHA Frontend Execution Checklist

This file compares the current Flutter UI prototype against the BAHA PRD and the app flow/screen matrix documents.

Status labels used here:

- `Done`: implemented in the current UI prototype and usable for demo flows
- `Partial`: present, but not yet final, dedicated, production-grade UI
- `Missing`: not yet built as required by the PRD

This checklist is based on the current workspace:

- [README.md](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/README.md)
- [app_router.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/navigation/app_router.dart)
- [auth_screens.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/screens/auth/auth_screens.dart)
- [student_shell.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/screens/student/student_shell.dart)
- [parent_shell.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/screens/parent/parent_shell.dart)
- [teacher_shell.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/screens/teacher/teacher_shell.dart)
- [admin_shell.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/screens/admin/admin_shell.dart)
- [detail_screen.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/ui_prototype_connected/lib/screens/shared/detail_screen.dart)

## Shared Frontend

| Area | Status | Reason if not done | Next owner action |
| --- | --- | --- | --- |
| One navigable Flutter prototype | Done |  | Keep as visual reference while splitting |
| Student, Parent, Teacher, BAHA role surfaces | Done |  | Preserve current visual language |
| Global light/dark mode | Done |  | Keep theme parity as new pages are added |
| Theme persistence | Done |  | Reuse existing theme controller |
| Responsive stabilization / overflow cleanup | Done |  | Recheck after each new page |
| Shared route system | Done |  | Replace prototype-only routes gradually |
| Shared detail-driven local mock flows | Done |  | Use as temporary bridge only |
| Four physically separate apps | Missing | Current build is still one prototype app with role selection, not four installable products | Split into `student_app`, `parent_app`, `teacher_app`, and `baha_app` targets |
| Separate app branding, package IDs, icons | Missing | App packaging has not been separated yet | Add four launch identities and install side-by-side support |
| Real startup state machine UI | Partial | Prototype has splash and auth entry, but not a true state-driven startup runtime | Build dedicated startup states: session restore, auth gate, onboarding gate, blocked states |
| Real blocked-state screens | Partial | Some blocked situations are simulated through generic local screens, not final dedicated pages | Create dedicated screens for consent pending, self-consent required, approval pending, inactive account, offline blocked |
| Loading / empty / retry / error states per screen | Missing | Current prototype mostly uses happy-path demo flows | Add state widgets to every major page before backend hookup |
| Accessibility audit pass | Missing | UI has not yet gone through a dedicated accessibility completion pass | Add semantic review, contrast pass, and keyboard/screen-reader QA |
| Tablet / foldable final layout pass | Partial | General responsiveness is better, but not all PRD-grade layouts are finalized for large screens | Add dedicated breakpoints and screen QA checklist |

## Auth And Onboarding

| Area | Status | Reason if not done | Next owner action |
| --- | --- | --- | --- |
| Login UI | Done |  | Replace fake actions later with live auth |
| Signup UI | Done |  | Split into role-specific final forms |
| Forgot password UI | Done |  | Replace fake flow with real recovery states later |
| OTP verification UI | Done |  | Convert to real verification flow later |
| Onboarding overview UI | Done |  | Keep copy aligned with PRD |
| Avatar selection UI | Done |  | Reuse for student-only flow |
| Real session restore flow | Missing | Prototype login does not restore a true session state | Build dedicated restore screen and logic shell |
| Real onboarding router | Partial | Navigation exists, but not as a backend-style state machine | Add a dedicated router screen driven by local state model |
| Role-specific final signup screens | Missing | Current auth forms are still mostly shared prototype forms | Build separate final forms for student, parent, teacher, counselor, school admin |
| Email verification flow | Missing | Current OTP is only local demo UI | Build dedicated verify-email states and success screens |
| Reset password success flow | Missing | Forgot-password is only a simple local branch | Add sent/success/failure variants |
| Logout confirmation / expired session UI | Missing | Session management is not yet modeled as final UX | Add dedicated session control screens |
| MFA / social login UI | Missing | Not part of the current offline prototype | Build later in auth completion phase |

## Student App

| Area | Status | Reason if not done | Next owner action |
| --- | --- | --- | --- |
| Student dashboard shell | Done |  | Keep as the visual base |
| Home / Check-In / Learn / Buddy / Profile nav | Done |  | Preserve navigation model |
| Student age-theme switching | Done |  | Keep existing age-based visual language |
| 13-16 male light/dark differentiation | Done |  | Keep both variants visually distinct |
| Games Hub entry point | Done |  | Convert to dedicated final pages later |
| Local check-in flow | Partial | Works locally, but still runs inside shared mock-detail behavior | Build dedicated check-in list, detail, review, submit success, and retry screens |
| Local learn/module flow | Partial | Demoable, but not yet dedicated final pages | Build dedicated feed, module detail, and progress screens |
| Local Buddy flow | Partial | Chat works locally, but not as a final dedicated chat product surface | Build dedicated session list, thread view, and escalation-aware UI states |
| Local SOS/help flow | Partial | Support actions are demoable, but not final dedicated pages | Build dedicated help request form, confirmation, and support contacts screens |
| Local privacy/profile flow | Partial | Present through dashboard/profile and generic pages, not final settings architecture | Build dedicated profile, privacy, consent status, and settings pages |
| Welcome screen | Missing | Onboarding exists as a general flow, but not as a final dedicated welcome experience | Build dedicated welcome / trust-framing student entry screen |
| Age cohort setup screen | Missing | Simulated through onboarding copy, not a final dedicated form page | Build dedicated age cohort screen |
| Consent-band routing screen | Missing | Simulated through onboarding copy and local steps | Build dedicated minor vs self-consent routing UI |
| Gender input / skip screen | Missing | Theme selection exists indirectly, but not as final onboarding UX | Build dedicated gender input or skip screen |
| Privacy explanation screen | Missing | Simulated inside generic onboarding flow | Build dedicated privacy explanation page |
| Privacy acknowledgement screen | Missing | Simulated, not a final formal screen | Build dedicated acknowledgement screen |
| Guardian linking screen | Missing | Student-side guardian flow is only represented conceptually | Build dedicated linking request state |
| Guardian consent wait screen | Missing | Modeled in copy only | Build dedicated waiting-state page |
| Self-consent screen | Missing | Modeled in copy only | Build dedicated self-consent page |
| Trend history screen | Missing | Current trend is a lightweight local insight, not a final history surface | Build dedicated historical trend page |
| Dedicated Games Hub screen | Missing | Entry point exists, but activity UX is still shared/local | Build a dedicated hub plus activity pages |
| Dedicated Calm Breathing screen | Missing | Currently mocked through shared flow engine | Build final standalone calming activity screen |
| Dedicated Emotion Wheel screen | Missing | Currently mocked through shared flow engine | Build final standalone emotion-labeling screen |
| Dedicated Friendship Choices screen | Missing | Currently mocked through shared flow engine | Build final standalone scenario page |
| Student notifications center | Missing | Generic notifications exist, but not a dedicated student notification product surface | Build student-specific notification center |

## Parent App

| Area | Status | Reason if not done | Next owner action |
| --- | --- | --- | --- |
| Parent dashboard shell | Done |  | Keep as the visual base |
| Parent home / summary / resources / settings nav | Done |  | Preserve structure |
| Linked-student overview | Partial | Visible in the prototype, but not yet a final dedicated screen set | Build dedicated linked-child dashboard and child-switcher flow |
| Summary sharing consent flow | Partial | Demoable locally, but still not a dedicated final screen architecture | Build final dedicated consent screen with locked / granted / revoked variants |
| Platform participation consent flow | Partial | Reachable locally, but not yet a dedicated final parent workflow | Build final dedicated participation-consent screen |
| Parent resources flow | Partial | Reachable locally, but not yet a dedicated list/detail final experience | Build final resources list and resource detail pages |
| Parent notifications flow | Partial | Reachable locally as a mock page, not yet a final parent alert surface | Build dedicated escalation-only notifications center |
| Parent bootstrap screen | Missing | Current auth is still shared prototype auth | Build a parent-specific bootstrap screen |
| Student linking wizard | Missing | Entry exists, but not a dedicated multi-step parent linking flow | Build link child wizard with relationship confirmation |
| Consent authority explanation page | Missing | Not yet separated as final UX | Build dedicated explanation screen |
| No-linked-child empty state | Missing | Parent shell assumes a linked child demo state | Build locked dashboard state when no child is linked |
| Weekly summary detail page | Missing | Summary exists at a prototype level, but not as a final dedicated detail screen | Build dedicated summary detail page |
| Privacy-tier settings page | Missing | Current settings are too light for PRD expectations | Build a parent privacy and visibility settings page |
| Parent account/profile page | Missing | No final dedicated parent profile surface yet | Build profile and account management screen |

## Teacher App

| Area | Status | Reason if not done | Next owner action |
| --- | --- | --- | --- |
| Teacher dashboard shell | Done |  | Keep as the visual base |
| Classes / Students / Tasks / Reports nav | Done |  | Preserve structure |
| Class context UI | Partial | Teacher class access is visible, but not fully separated into dedicated final pages | Build dedicated class list and class summary pages |
| Pastoral flag flow | Partial | Locally demoable, but not yet a dedicated formal form workflow | Build a final pastoral flag form and confirmation page |
| Teacher resources flow | Partial | Reachable locally, but not yet a dedicated final feed/detail flow | Build dedicated teacher resources list and detail pages |
| Referral workflow mock | Partial | Available locally, but still a placeholder flow | Build final referral workflow screens with stage-specific UX |
| Teacher notifications mock | Partial | Reachable locally, but not yet a true teacher notification center | Build dedicated teacher notifications screens |
| Teacher bootstrap screen | Missing | Current auth is shared prototype auth | Build teacher-specific bootstrap screen |
| Approval pending screen | Missing | Simulated through generic onboarding, not final dedicated UI | Build teacher approval pending screen |
| Access blocked / inactive screen | Missing | Not yet designed as a dedicated teacher screen | Build blocked-state screen variants |
| Class summary final screen | Missing | Class summary is still handled through shared mock flow | Build final summary page |
| Class students final screen | Missing | Current student signal flow is not yet a final dedicated student list page | Build final class students page |
| Student pastoral context page | Missing | Teacher can draft a flag, but not inspect a dedicated workflow-safe student page | Build a dedicated pastoral context screen |
| Teacher settings/profile page | Missing | Generic settings are not enough for PRD completion | Build final teacher account/settings screen |
| No assigned classes empty state | Missing | Not yet modeled as final UX | Build explicit empty state |

## BAHA / Counselor App

| Area | Status | Reason if not done | Next owner action |
| --- | --- | --- | --- |
| BAHA dashboard shell | Done |  | Keep as the visual base |
| Command / Approvals / Content / System nav | Done |  | Preserve structure |
| Support queue mock | Partial | Reachable locally, but not yet a final dedicated operations queue product surface | Build final support queue page with tabs, filters, and states |
| Case detail mock | Partial | Reachable locally, but still driven by shared mock flow | Build dedicated case detail page |
| Add note mock | Partial | Available locally, but not yet separated into a final case-note UX | Build final add-note UI within case detail |
| Approval workflow mock | Partial | Reachable and usable locally, but not yet a dedicated final review system | Build final approval queue and decision pages |
| Content review mock | Partial | Reachable locally, but not yet a final moderation/review product surface | Build dedicated review queue and publish/reject flow |
| Threshold configuration mock | Partial | Reachable locally, but not yet a final admin settings page | Build dedicated threshold management screen |
| Crisis contacts / expert routing mock | Partial | Reachable locally, but not yet a final dedicated reference page | Build dedicated crisis routing screen |
| Counselor bootstrap screen | Missing | Current auth is shared prototype auth | Build counselor/BAHA-specific bootstrap screen |
| Counselor approval pending screen | Missing | Simulated conceptually, not as final dedicated UI | Build dedicated approval pending screen |
| Queue filter/tab system | Missing | Queue exists as a simple local mock, not final operations UX | Build final multi-state queue navigation |
| Case assignment/status section | Missing | Not yet modeled as final case-management UI | Build assignment and case-status views |
| Global vs school scope context UI | Missing | PRD expects operational scope clarity, which is not yet shown as final UI | Build scope context indicator and switching rules |
| System admin settings screens | Missing | Current system tab is still lightweight | Build enterprise operational settings surfaces |
| Operations analytics pages | Missing | Dashboard exists visually, but not as final analytics pages | Build school/global analytics screens |

## Why Many Items Are Still Not Done

These are the main reasons gaps still exist:

1. The current workspace was intentionally built as an offline-first prototype.
   - That made it possible to finish the visual system quickly without locking into unstable backend assumptions.

2. Many PRD flows are currently represented through one reusable local mock-flow page.
   - This keeps the app clickable and demoable.
   - It does not yet satisfy the PRD requirement for fully dedicated production screens.

3. The project is still one prototype app instead of four packaged apps.
   - That is the biggest architectural frontend gap left.

4. State-driven UX is still incomplete.
   - Happy-path interactions exist.
   - Full blocked/loading/empty/error/retry handling still needs a final pass.

5. Auth and onboarding are still prototype-grade.
   - The surfaces are there.
   - The final role-specific UX is not yet built.

## Exact Frontend Finish Order

Use this order to avoid rework:

1. Split the prototype into four real Flutter apps
2. Build shared startup-state and blocked-state screens
3. Finish Student App as dedicated final screens
4. Finish Parent App as dedicated final screens
5. Finish Teacher App as dedicated final screens
6. Finish BAHA / Counselor App as dedicated final screens
7. Replace core mock-detail screens with dedicated screens one by one
8. Add loading / empty / retry / error states everywhere
9. Add final packaging, branding, and install separation
10. Do final accessibility, responsiveness, and polish QA

## Current Recommendation

If work resumes immediately, the best next owner action is:

1. Finish Student App first
2. Then Parent App
3. Then Teacher App
4. Then BAHA / Counselor App
5. Then do the app split and packaging pass

