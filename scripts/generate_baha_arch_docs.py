from pathlib import Path
from textwrap import dedent


ROOT = Path("/Users/solomonkaruppiah/Desktop/Baha_Data")
DOCS = ROOT / "docs"


def write(rel_path: str, content: str) -> None:
    path = ROOT / rel_path
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(dedent(content).strip() + "\n", encoding="utf-8")


product_overview = """
# BAHA Wellness Companion Architecture Repository

This repository transforms the BAHA Wellness Companion PRD into an implementation-oriented architecture pack for product, design, engineering, QA, data, and clinical governance teams.

## Repository Scope

- Four separate Flutter applications sharing one backend:
  - Student App
  - Parent App
  - Teacher App
  - BAHA Counselor/Admin App
- Shared platform services for:
  - authentication and role enforcement
  - consent and privacy-tier enforcement
  - content management and learning delivery
  - chatbot retrieval and response governance
  - monitoring, escalation, and case management
  - analytics, notifications, and auditability

## Reading Order

1. [00_Product_Overview.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/00_Product_Overview.md)
2. [01_Information_Architecture.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/01_Information_Architecture.md)
3. [02_Master_User_Journey.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/02_Master_User_Journey.md)
4. Role-specific app folders:
   - [03_Student_App/README.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/03_Student_App/README.md)
   - [04_Parent_App/README.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/04_Parent_App/README.md)
   - [05_Teacher_App/README.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/05_Teacher_App/README.md)
   - [06_BAHA_App/README.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/06_BAHA_App/README.md)
5. Shared platform:
   - [07_Backend/architecture.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/07_Backend/architecture.md)
   - [08_Database/schema.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/08_Database/schema.md)
   - [11_API/endpoints.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/11_API/endpoints.md)
   - [12_Flutter/routing.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/12_Flutter/routing.md)

## Product Boundaries

- Student experience is private by default and may not expose clinical diagnosis, risk scores, or surveillance patterns.
- Parent experience is summary-based and consent-gated.
- Teacher experience is anonymized at class level except where safeguarding protocols create explicit access.
- BAHA experience is the only surface with operational case management, threshold management, and content governance.
- High-risk escalation remains human-owned and human-reviewed at all times.

## Architecture Principles

- Privacy by default
- Support before crisis
- Separate stakeholder surfaces, shared backend contracts
- Android-first delivery, iOS after pilot hardening
- Rule-based monitoring, not AI diagnosis
- Content-grounded chatbot with BAHA review
- Modular Flutter clients and modular FastAPI services
- Auditable consent, content, escalation, and access history

## Deliverables Included

- information architecture
- user journeys
- navigation graphs
- screen inventories
- screen flows
- state diagrams
- edge cases
- backend architecture
- API contract proposals
- database model
- component hierarchy
- design system guidance
- Flutter module architecture
"""


overview_doc = """
# Product Overview

## Product Identity

- Product: BAHA Wellness Companion
- Model: adolescent-first digital wellness ecosystem
- Clinical partner: Bangalore Adolescent Health Academy (BAHA)
- Delivery target: Android-first Flutter multi-app suite
- Future target: iOS parity after Android pilot hardening

## Core Problem

The product exists to provide Indian adolescents with a private, trusted, repeat-usage support channel for self-awareness, safe learning, and human-routed support before problems escalate into adult-visible crises.

## Primary Role Surfaces

| Role | Surface | Primary Jobs | Explicit Limits |
|---|---|---|---|
| Student | Dedicated Student App | private check-ins, trends, BAHA Buddy, learning, games, help | no diagnosis, no surveillance, no public ranking |
| Parent/Guardian | Dedicated Parent App | consent, weekly summaries, conversation support, parent education | no raw check-in answers, no diary access, no live tracking |
| Teacher/Counselor | Dedicated Teacher App | class trends, pastoral input, referrals, safeguarding learning | no unrestricted individual data access |
| BAHA/Counselor/Admin | Dedicated BAHA App | support queue, case management, content review, threshold config, analytics | minimum-necessary access only |

## Student Age Segmentation

| Age Band | UX Goal | Interaction Character |
|---|---|---|
| 9-13 | comprehension and safety | simpler language, guided patterns, softer interactions |
| 14-16 | identity and reflection | richer reflection prompts, stronger self-discovery framing |
| 17-19 | autonomy and self-direction | denser insights, stronger consent and control messaging |

## Platform Goals

### Must Deliver

- weekly student check-ins tied to personal trends
- BAHA-grounded chatbot and Safe Questions library
- learning modules for students, parents, and teachers
- insight-generating games with time governance
- consent-gated parent summaries
- teacher pastoral signal capture
- BAHA support queue and case management
- analytics, audit, notification, and content workflows

### Must Not Become

- an AI diagnostic engine
- a passive surveillance tool
- an unowned crisis escalation system
- a public social product without moderation ownership
- a public app-store wellness product before governance hardening

## Release Structure

| Release | Scope |
|---|---|
| R1 | Android functional launch across all four apps and shared backend |
| R1.1 | pilot hardening, threshold calibration, performance and QA stabilization |
| R2 | iOS parity and broader rollout support |
| R3 | research extensions such as passive sensing, wearables, or AI risk modeling only after ethics approval |

## Shared Service Domains

- identity and authentication
- consent and privacy tier management
- wellness check-in capture and trend generation
- learning content catalog and delivery
- BAHA Safe Questions library and chatbot retrieval
- game telemetry and behavioral signal aggregation
- escalation workflow and support queue
- analytics and audit pipelines
- notification orchestration

## Key Governance Rules

- no student data collection before privacy acknowledgement and consent routing complete
- no parent access beyond approved privacy tiers
- no teacher access to raw student wellbeing data
- no high-risk threshold activation without named human responder
- no chatbot sensitive-domain response outside BAHA-approved corpus
- no automatic crisis management without human-in-the-loop review
"""


ia_doc = """
# Information Architecture

## IA Layers

1. Experience layer
   - Student App
   - Parent App
   - Teacher App
   - BAHA App
2. Domain-service layer
   - Identity
   - Consent
   - Check-ins
   - Trends
   - Content
   - Chatbot
   - Games
   - Notifications
   - Escalation
   - Analytics
   - Audit
3. Data layer
   - operational PostgreSQL
   - content asset storage
   - vector index
   - audit log store

## Master Navigation Tree

### Student App

- App Shell
  - Home
  - Check-In
  - Buddy
  - Learn
  - Games
  - Profile
    - badges
    - challenges
    - privacy settings
    - consent tiers
    - help and support

### Parent App

- App Shell
  - Home
  - Weekly Summary
  - Conversation Guides
  - Learn
  - Settings
    - consent status
    - privacy tiers
    - notifications
    - data rights

### Teacher App

- App Shell
  - Dashboard
  - Pastoral Input
  - Referrals
  - Learn
  - Settings

### BAHA App

- App Shell
  - Support Queue
  - Cases
  - Content
  - Thresholds
  - Analytics
  - Audit
  - Settings

## Permission Hierarchy

| Permission Area | Student | Parent | Teacher | BAHA |
|---|---|---|---|---|
| View raw check-in answers | yes, own only | no | no | yes, if clinically justified or case-open |
| View aggregate weekly trend | yes | yes, consent-gated | class level only | yes |
| Edit consent tiers | yes, subject to consent band | yes, in minor flow | no | override only via policy action |
| Use chatbot | yes | optional later | no | admin testing only |
| Submit pastoral flag | no | no | yes | yes |
| Open or manage case | no | no | limited referral view | yes |
| Publish learning content | no | no | no | yes |
| Configure thresholds | no | no | no | yes |

## Content Hierarchy

- Theme
  - sleep and physical activity
  - emotional wellbeing and mental health
  - digital and media use
  - substance awareness
  - life skills
  - nutrition
  - social wellbeing
- Audience
  - student early
  - student mid
  - student late
  - parent
  - teacher
- Format
  - card
  - story
  - video
  - audio
  - infographic
  - checklist
  - reflection
  - quiz

## Feature Dependency Graph

- onboarding depends on consent wording, age band model, and content tagging
- trend dashboard depends on weekly check-ins and analytics transformation
- parent summaries depend on consent tiers and aggregate trend generation
- teacher class trends depend on cohort anonymization logic
- chatbot depends on Safe Questions corpus, citations, escalation rules, and privacy disclosures
- games depend on age-banded content review and signal aggregation
- support queue depends on monitoring rules, acute safety protocol, and named human owners
- learning module depends on content CMS, tagging, and role routing

## Mermaid Mindmap

```mermaid
mindmap
  root((BAHA Wellness Companion))
    Student App
      Onboarding
      Weekly Check-In
      Trend Dashboard
      BAHA Buddy
      Safe Questions
      Learning
      Games
      Help Pathway
      Privacy Settings
    Parent App
      Consent
      Weekly Summary
      Conversation Guides
      Parent Learning
      Privacy Controls
    Teacher App
      Class Trends
      Pastoral Input
      Referrals
      Teacher Learning
    BAHA App
      Support Queue
      Case Management
      Content Review
      Threshold Config
      Pilot Analytics
      Audit Logs
    Shared Services
      Auth
      Consent
      Content
      Chatbot Retrieval
      Escalation
      Notifications
      Analytics
      Audit
    Governance
      DPDP
      ICMR
      BAHA Signoff
      Human In The Loop
```
"""


journey_doc = """
# Master User Journey

## Cross-Role Journey Phases

1. Institutional readiness
   - BAHA assigns reviewers and safeguarding owners
   - school onboarding and permission are completed
   - content and thresholds are approved
2. Identity and consent
   - student enters age-band journey
   - legal consent band is resolved
   - parent consent or self-consent completes
3. Habit formation
   - weekly check-ins begin
   - trends start after enough data accrues
   - learning and games establish supportive repeat use
4. Insight and support
   - student uses BAHA Buddy and Safe Questions
   - parents receive aggregate summaries where allowed
   - teachers contribute pastoral context
5. Monitoring and intervention
   - rules surface signals into BAHA queue
   - human review decides action
   - student is informed during overrides
6. Continuous governance
   - thresholds recalibrated
   - content re-reviewed
   - pilot analytics exported

## Student Journeys by Age Band

### Early Adolescence (9-13)

- stronger guidance during onboarding
- higher comprehension focus in privacy explanation
- softer guardrails around time limits and reminders
- more structured reflection options than open text

### Mid Adolescence (14-16)

- greater emphasis on self-expression and emotional vocabulary
- deeper narrative games and peer-pressure scenarios
- stronger support-hand-off framing within chatbot

### Late Adolescence (17-19)

- more direct autonomy and privacy control messaging
- denser insight view
- more self-serve support requests and self-consent mechanics

## Parent Journey

- consent request received
- consent status confirmed
- privacy tiers negotiated
- weekly summaries reviewed
- conversation guide used
- alert state only when safeguarding rules require

## Teacher Journey

- completes training and onboarding
- views weekly class trends
- enters pastoral signal
- submits referral
- tracks referral and safeguarding status

## BAHA Journey

- configures content and thresholds
- monitors queue
- opens case
- performs review and action logging
- publishes analytics and maintains governance

## Shared Journey Risks

- expired consent blocks data processing
- low connectivity affects check-in sync and content fetch
- insufficient cohort size hides teacher analytics
- missing human owner blocks threshold activation
- expired content review date suppresses content publication

## Master Swimlane

```mermaid
flowchart LR
    A[Student onboarding starts] --> B{Consent band}
    B -->|9-17| C[Parent consent flow]
    B -->|18-19| D[Self-consent flow]
    C --> E[Student app activated]
    D --> E
    E --> F[Weekly check-in and home usage]
    F --> G[Trend generation]
    F --> H[Buddy and learning]
    H --> I[Games and challenges]
    G --> J[Parent summary if consented]
    F --> K[Teacher class aggregates]
    H --> L{Signal threshold crossed?}
    I --> L
    K --> L
    L -->|No| F
    L -->|Yes| M[BAHA queue case opened]
    M --> N[Human review and action]
    N --> O[Student informed if override]
```
"""


apps = {
    "03_Student_App": {
        "title": "Student App",
        "nav": ["Home", "Check-In", "Buddy", "Learn", "Games", "Profile"],
        "purpose": "Private self-awareness, learning, emotional literacy, and human-routed support.",
        "audience": "Students aged 9-19 with three presentation cohorts and two legal consent bands.",
        "critical_rules": [
            "No clinical diagnosis, risk score, or medical recommendation appears in the UI.",
            "Check-in, chatbot, and game data remain private by default.",
            "Consent overrides are explained to the student in real time.",
            "Games are advisory-limited to 30 minutes total daily play, with softer enforcement for under-13 users.",
        ],
        "journeys": [
            "onboarding and privacy understanding",
            "weekly check-in habit",
            "trend interpretation and reflection",
            "chatbot support and Safe Questions usage",
            "learning and challenge completion",
            "help and crisis handoff",
        ],
        "screens": [
            ("S-00", "Splash", "Bootstraps cached config, consent status, and auth session."),
            ("S-01", "Welcome", "Introduces BAHA promise and routes to profile setup."),
            ("S-02", "Age-Band Selection", "Captures presentation cohort without revealing full DOB in the primary UI."),
            ("S-03", "Legal Consent Routing", "Determines minor flow versus self-consent flow."),
            ("S-04", "Gender Optional", "Captures optional gender preference for content tailoring."),
            ("S-05", "Privacy Promise", "Explains what stays private, what may be summarized, and override rules."),
            ("S-06", "Parent Consent Pending", "Blocks data collection until guardian approval arrives."),
            ("S-07", "Self-Consent Confirmation", "Confirms 18-19 user consent and data rights."),
            ("S-08", "Consent Tier Setup", "Defines what parent sees in minor and self-consent flows."),
            ("S-09", "Notification Permission", "Configures reminders for weekly check-ins and content nudges."),
            ("S-10", "Home Dashboard", "Shows streaks, next actions, challenges, and support entry points."),
            ("S-11", "Weekly Check-In Prompt", "Schedules and launches the weekly flow."),
            ("S-12", "Check-In Questionnaire", "Captures mood, sleep, energy, stress, screen time, physical activity, lifestyle, and academic stress."),
            ("S-13", "Check-In Completion", "Confirms completion and directs to calming or learning suggestions."),
            ("S-14", "Trend Dashboard Empty", "Explains why more data is needed before insights appear."),
            ("S-15", "Trend Dashboard Active", "Displays supportive, non-diagnostic 4-week trend summaries."),
            ("S-16", "Trend Insight Detail", "Explains one trend relationship in plain language."),
            ("S-17", "Mood Vocabulary Expansion", "Introduces richer emotion words over time."),
            ("S-18", "Challenges Hub", "Lists opt-in habit challenges."),
            ("S-19", "Badge Wallet", "Shows private milestones and completion badges."),
            ("S-20", "Games Hub", "Routes to Emotion Explorer, Friendship Choices, and Calm Breathing."),
            ("S-21", "Emotion Explorer", "Scenario-based emotional literacy gameplay."),
            ("S-22", "Friendship Choices", "Narrative peer-pressure and social reasoning game."),
            ("S-23", "Calm Breathing", "Short guided regulation activities."),
            ("S-24", "Time Cap Prompt", "Advisory break prompt at game time threshold."),
            ("S-25", "Learning Home", "Role- and age-banded content entry."),
            ("S-26", "Module Detail", "Explains objectives, duration, and formats."),
            ("S-27", "Lesson View", "Card, audio, infographic, or video content presentation."),
            ("S-28", "Quiz and Reflection", "Formative assessment without punitive scoring."),
            ("S-29", "Safe Questions Library", "Curated BAHA-reviewed question list."),
            ("S-30", "Buddy Chat", "Main conversational interface with citations and escalation affordances."),
            ("S-31", "Buddy Citation Detail", "Shows source provenance and review date."),
            ("S-32", "Buddy Out-of-Scope", "Safe refusal and redirection state."),
            ("S-33", "Profile Summary", "Plain-language overview of remembered themes and preferences."),
            ("S-34", "Privacy Settings", "Controls reminders, data rights, and personalization opt-outs."),
            ("S-35", "Consent Tier Editor", "Revisits summary-sharing boundaries."),
            ("S-36", "Help Center", "Routes to BAHA support, hotline, and emergency guidance."),
            ("S-37", "Counselor Request", "Student-initiated support request."),
            ("S-38", "Consent Override Notification", "Real-time explanation of who is being involved and why."),
            ("S-39", "Offline State", "Supports cached check-ins, calming activities, and text/audio learning."),
        ],
        "states": [
            "first launch",
            "consent blocked",
            "awaiting parent approval",
            "empty trend history",
            "offline cached mode",
            "chatbot unavailable",
            "override in progress",
            "profile deletion requested",
        ],
        "edge_cases": [
            "student selects incorrect age band intentionally",
            "parent consent never arrives",
            "student submits duplicate weekly check-ins",
            "student repeatedly selects same emotion in game scenarios",
            "student triggers escalation and closes the app",
            "student opts out of profile building but keeps chatbot access",
        ],
    },
    "04_Parent_App": {
        "title": "Parent App",
        "nav": ["Home", "Weekly Summary", "Conversation Guides", "Learn", "Settings"],
        "purpose": "Consent management, summary interpretation, and conversation support without surveillance.",
        "audience": "Parents and guardians of enrolled students.",
        "critical_rules": [
            "No raw student check-in answers or diary content are exposed.",
            "Parent visibility is bounded by consent tiers and safeguarding overrides only.",
            "Weekly summary cadence is capped at once per week.",
            "Conversation guides frame support, not inspection.",
        ],
        "journeys": [
            "consent grant and verification",
            "privacy tier negotiation",
            "weekly summary review",
            "conversation guide usage",
            "parent learning completion",
            "escalation notification handling",
        ],
        "screens": [
            ("P-00", "Splash", "Loads consent status and linked student relationships."),
            ("P-01", "Parent Onboarding", "Introduces the role of the app and privacy model."),
            ("P-02", "Guardian Verification", "Records verifiable parental consent."),
            ("P-03", "Linked Student Summary", "Lists linked students and summary eligibility."),
            ("P-04", "Consent Status", "Shows active, pending, expired, or withdrawn states."),
            ("P-05", "Privacy Tier Review", "Displays and negotiates allowed summary tiers."),
            ("P-06", "Weekly Summary Home", "Shows the current week's aggregate summary."),
            ("P-07", "Sleep and Mood Trend Explanation", "Explains trend direction without raw entries."),
            ("P-08", "Conversation Guide Detail", "Theme-linked guidance for talking with the child."),
            ("P-09", "Parent Learning Home", "Shows modules on adolescent wellbeing and app usage."),
            ("P-10", "Parent Module Detail", "Displays objectives, duration, and completion state."),
            ("P-11", "Alert Notification Detail", "Explains safeguarding-driven contact or action."),
            ("P-12", "Notification Settings", "Controls summary reminders and operational alerts."),
            ("P-13", "Data Rights", "Supports view and deletion requests within policy boundaries."),
            ("P-14", "Offline Summary Placeholder", "Indicates summaries require sync while preserving cached policy guidance."),
        ],
        "states": [
            "consent pending",
            "consent active",
            "consent expired",
            "weekly summary not available",
            "summary available",
            "alert active",
            "student privacy tier changed",
        ],
        "edge_cases": [
            "parent and student disagree on privacy tier",
            "parent withdraws consent after activation",
            "parent expects raw diary visibility",
            "summary suppressed because no valid cohort data exists",
            "escalation alert arrives outside summary cadence",
        ],
    },
    "05_Teacher_App": {
        "title": "Teacher App",
        "nav": ["Dashboard", "Pastoral Input", "Referrals", "Learn", "Settings"],
        "purpose": "Cohort-level visibility and counselor-facing pastoral signals without exposing raw student data.",
        "audience": "Teachers and school counselors at pilot schools.",
        "critical_rules": [
            "Teacher dashboard is anonymized and cohort-threshold protected.",
            "Teacher access to individual data is only through explicit safeguarding pathways.",
            "Pastoral flags are soft signals, not automatic parent alerts.",
            "Teachers must complete training before sensitive features unlock.",
        ],
        "journeys": [
            "teacher onboarding and training completion",
            "class trends review",
            "pastoral note submission",
            "referral initiation and tracking",
            "teacher learning completion",
        ],
        "screens": [
            ("T-00", "Splash", "Loads staff authorization and school context."),
            ("T-01", "Teacher Onboarding", "Explains safeguards, role limits, and dashboard meaning."),
            ("T-02", "Training Status", "Gates sensitive features until required learning is complete."),
            ("T-03", "Class Trends Dashboard", "Weekly anonymized cohort trends by theme."),
            ("T-04", "Trend Filter", "Switches week, cohort, and theme views."),
            ("T-05", "Pastoral Input Form", "Structured categories and short free-text note."),
            ("T-06", "Pastoral Input Confirmation", "Confirms submission and retention handling."),
            ("T-07", "Referral Queue", "Teacher-originated referrals and statuses."),
            ("T-08", "Referral Detail", "Shows referral metadata and counselor actions allowed to teacher."),
            ("T-09", "Teacher Learning Home", "Safeguarding, dashboard interpretation, and conversation content."),
            ("T-10", "Teacher Module Detail", "Tracks completion and unlock rules."),
            ("T-11", "Restricted Student Case Notice", "Explains why direct access is blocked."),
            ("T-12", "Notification Center", "Operational alerts for training, referrals, and policy updates."),
            ("T-13", "Settings", "School context, notification settings, and policy documents."),
            ("T-14", "Offline Analytics Placeholder", "Explains trend data sync dependency."),
        ],
        "states": [
            "training required",
            "cohort threshold too small",
            "dashboard available",
            "pastoral flag drafted",
            "referral in review",
            "referral closed",
        ],
        "edge_cases": [
            "class size below anonymization minimum",
            "teacher submits duplicate pastoral flags",
            "teacher attempts to open student raw trend data",
            "teacher uses free text containing sensitive allegations",
            "teacher offline during scheduled weekly dashboard refresh",
        ],
    },
    "06_BAHA_App": {
        "title": "BAHA Counselor/Admin App",
        "nav": ["Support Queue", "Cases", "Content", "Thresholds", "Analytics", "Audit", "Settings"],
        "purpose": "Operational console for safeguarding, content governance, threshold management, and analytics.",
        "audience": "BAHA clinicians, counselors, content reviewers, and platform admins.",
        "critical_rules": [
            "Only minimum-necessary data is exposed at each workflow stage.",
            "Every escalation event is logged and human-owned.",
            "Threshold activation is blocked without named human coverage.",
            "Expired content review automatically suppresses publication.",
        ],
        "journeys": [
            "queue triage and case assignment",
            "acute safety handling",
            "content lifecycle governance",
            "threshold calibration",
            "pilot analytics review and export",
        ],
        "screens": [
            ("B-00", "Splash", "Loads role, permissions, and operational context."),
            ("B-01", "Support Queue", "Priority-sorted list of acute safety, monitoring, pastoral, and help cases."),
            ("B-02", "Queue Filters", "Filters by source, severity, school, age band, and status."),
            ("B-03", "Case Detail", "Shows signal origin, event timeline, linked context, and notes."),
            ("B-04", "Action Log Editor", "Adds decisions, follow-up attempts, and closure rationale."),
            ("B-05", "Case Assignment", "Assigns owner, SLA, and escalation path."),
            ("B-06", "Emergency Protocol View", "Guides acute safety steps and hotline surfacing."),
            ("B-07", "Content Library", "Lists drafts, reviewed, published, flagged, and archived items."),
            ("B-08", "Content Editor", "Supports metadata, audience tags, citations, and review date."),
            ("B-09", "Content Review Queue", "Clinical review and publish gating."),
            ("B-10", "Safe Questions Manager", "Maintains chatbot Q&A corpus and expiry states."),
            ("B-11", "Threshold Configuration", "Manages rule thresholds per school and age group."),
            ("B-12", "Threshold History", "Shows calibration changes and owner approvals."),
            ("B-13", "Pilot Analytics Dashboard", "Aggregate engagement, content, and escalation metrics."),
            ("B-14", "Analytics Export", "Creates pilot reporting extracts."),
            ("B-15", "Audit Log", "Shows access, consent, escalation, and content actions."),
            ("B-16", "User and Role Management", "Controls staff access and function scopes."),
            ("B-17", "Operational Settings", "Maintains hotline details, school contexts, and review SLAs."),
        ],
        "states": [
            "queue empty",
            "queue overloaded",
            "case assigned",
            "case awaiting follow-up",
            "case closed",
            "content flagged expired",
            "threshold draft",
            "threshold active",
        ],
        "edge_cases": [
            "no on-call counselor exists for a thresholded event",
            "multiple acute disclosures from the same student in one day",
            "content review date expires during active publication",
            "case closure attempted without action note",
            "analytics export requested during partial data sync",
        ],
    },
}


def bullet_lines(items):
    return "\n".join(f"- {item}" for item in items)


def screen_table(items):
    rows = ["| ID | Screen | Purpose |", "|---|---|---|"]
    rows.extend(f"| {sid} | {name} | {purpose} |" for sid, name, purpose in items)
    return "\n".join(rows)


def app_readme(folder, data):
    return f"""
# {data["title"]}

## Purpose

{data["purpose"]}

## Audience

{data["audience"]}

## Primary Navigation

{bullet_lines(data["nav"])}

## Primary Journeys

{bullet_lines(data["journeys"])}

## Critical Governance Rules

{bullet_lines(data["critical_rules"])}

## Document Map

- [Navigation.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/{folder}/Navigation.md)
- [User_Journey.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/{folder}/User_Journey.md)
- [Screen_Inventory.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/{folder}/Screen_Inventory.md)
- [Screen_Flows.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/{folder}/Screen_Flows.md)
- [State_Diagrams.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/{folder}/State_Diagrams.md)
- [Edge_Cases.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/{folder}/Edge_Cases.md)
"""


def app_navigation(data):
    return f"""
# Navigation

## Top-Level Structure

{bullet_lines(data["nav"])}

## Navigation Rules

- first-run routing must honor authentication state and consent state before the app shell appears
- users may deep-link only into views allowed by their current permissions and data availability
- emergency or override notifications can interrupt the normal flow but must preserve a return path
- offline states may expose cached screens but never bypass policy gates

## Deep-Link and Routing Map

| Route Group | Purpose | Guard |
|---|---|---|
| onboarding | profile setup, consent, privacy promise | unauthenticated or incomplete setup only |
| home | main role dashboard | active session plus completed consent/training gate |
| content | learning modules, detail, progress | role and audience filtered |
| support | alerts, help, referrals, cases | role-specific permissions |
| settings | notification, privacy, data rights | authenticated role |

## Mermaid Reference

- [Mermaid/navigation.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/{current_folder}/Mermaid/navigation.mmd)
"""


def app_journey(data):
    return f"""
# User Journey

## Journey Phases

{bullet_lines(data["journeys"])}

## Happy Path

1. User opens app and passes role-specific gate checks.
2. App resolves onboarding, consent, training, or session status.
3. User lands on top-level dashboard or home screen.
4. User completes core weekly or operational task.
5. App records analytics and updates recommendations or queue state.
6. User exits with clear next action or passive reminder.

## Interrupted Pathways

- connectivity loss moves the app into cached-mode messaging where allowed
- expired consent or training routes back to the gating flow
- low-data or empty states explain why a screen has no insights yet
- escalation or alert events create high-priority interruption banners with logged timestamps

## Role-Specific Constraints

{bullet_lines(data["critical_rules"])}
"""


def app_screen_inventory(data):
    return f"""
# Screen Inventory

## Exhaustive Screen List

{screen_table(data["screens"])}

## Shared Global Screen States

{bullet_lines(data["states"])}
"""


def app_screen_flows(data):
    flows = [
        "Onboarding and access control",
        "Primary dashboard and core action entry",
        "Learning content and completion",
        "Notification interrupt and return path",
        "Settings, policy, and data-rights paths",
    ]
    if "Student" in data["title"]:
        flows.extend(
            [
                "Weekly check-in and trend generation",
                "Chatbot support and out-of-scope redirection",
                "Game governance and time-cap handling",
                "Emergency and consent override flow",
            ]
        )
    elif "Parent" in data["title"]:
        flows.extend(
            [
                "Consent verification and privacy tier review",
                "Weekly summary and conversation guide flow",
                "Escalation alert handling",
            ]
        )
    elif "Teacher" in data["title"]:
        flows.extend(
            [
                "Training gate and class dashboard access",
                "Pastoral flag and referral flow",
            ]
        )
    else:
        flows.extend(
            [
                "Support queue triage and case action flow",
                "Content review and publishing flow",
                "Threshold calibration and activation flow",
            ]
        )
    return f"""
# Screen Flows

## Flow Inventory

{bullet_lines(flows)}

## Flow Composition Rules

- every flow must define entry condition, role guard, happy path, empty state, loading state, offline behavior, and error recovery
- every flow touching privacy, consent, or escalation must produce an audit event
- user-visible copy must avoid diagnosis language on student-facing surfaces

## Mermaid Files

- [Mermaid/onboarding.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/{current_folder}/Mermaid/onboarding.mmd)
- [Mermaid/dashboard.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/{current_folder}/Mermaid/dashboard.mmd)
- [Mermaid/chatbot.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/{current_folder}/Mermaid/chatbot.mmd)
- [Mermaid/learning.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/{current_folder}/Mermaid/learning.mmd)
- [Mermaid/games.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/{current_folder}/Mermaid/games.mmd)
- [Mermaid/notifications.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/{current_folder}/Mermaid/notifications.mmd)
- [Mermaid/profile.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/{current_folder}/Mermaid/profile.mmd)
- [Mermaid/settings.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/{current_folder}/Mermaid/settings.mmd)
- [Mermaid/emergency.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/{current_folder}/Mermaid/emergency.mmd)
"""


def app_state_diagrams(data):
    return f"""
# State Diagrams

## Core States

{bullet_lines(data["states"])}

## State Modeling Rules

- gating states resolve before feature states
- empty and loading states are explicit states, not visual afterthoughts
- offline behavior is separate from generic error state where cached functionality exists
- escalation and override states must preserve previous context and auditability

## Recommended State Clusters

- app session state
- role entitlement state
- content availability state
- notification handling state
- support or escalation state
"""


def app_edge_cases(data):
    return f"""
# Edge Cases

## Role-Specific Edge Cases

{bullet_lines(data["edge_cases"])}

## Shared Edge Cases

- app opened after policy wording version changes
- network reconnect after offline data capture
- partial sync where dashboard and notifications update at different times
- duplicate submissions caused by retry or unstable connection
- localization or readability mismatch for age-banded student content

## Error Handling Rules

- show cause, impact, and next action plainly
- never shame the student for missed or repeated actions
- never expose sensitive hidden data in debug or error states
- keep failed sync items idempotent and retryable
"""


def mermaid_navigation(data):
    nodes = " --> ".join([f'["{n}"]' for n in data["nav"]])
    return f"""flowchart LR
    A["Launch"] --> B["Access Guard"]
    B --> C["{data["nav"][0]}"]
    C --> {nodes}
"""


def mermaid_onboarding(data):
    if "Student" in data["title"]:
        return """flowchart TD
    A["Welcome"] --> B["Age Band"]
    B --> C["Consent Band Routing"]
    C -->|"9-17"| D["Parent Consent Pending"]
    C -->|"18-19"| E["Self-Consent"]
    D --> F["Privacy Promise"]
    E --> F
    F --> G["Consent Tier Setup"]
    G --> H["Notification Permission"]
    H --> I["Home"]
"""
    if "Parent" in data["title"]:
        return """flowchart TD
    A["Welcome"] --> B["Guardian Verification"]
    B --> C["Linked Student Review"]
    C --> D["Consent Status"]
    D --> E["Privacy Tier Review"]
    E --> F["Weekly Summary Home"]
"""
    if "Teacher" in data["title"]:
        return """flowchart TD
    A["Welcome"] --> B["Role Verification"]
    B --> C["Training Gate"]
    C --> D["Class Dashboard"]
"""
    return """flowchart TD
    A["Staff Login"] --> B["Role Check"]
    B --> C["Operational Context"]
    C --> D["Support Queue"]
"""


def mermaid_dashboard(data):
    title = data["nav"][0]
    return f"""stateDiagram-v2
    [*] --> Loading
    Loading --> Empty: no data
    Loading --> Active: data ready
    Loading --> Offline: sync unavailable
    Empty --> Active: minimum data reached
    Active --> Detail
    Detail --> Active
    Offline --> Active: reconnect
    Active --> [*]
"""


def mermaid_chatbot(data):
    if "Student" not in data["title"]:
        return """flowchart TD
    A["Message or Alert Trigger"] --> B["Policy Check"]
    B --> C["Allowed Response"]
    C --> D["Audit Event"]
"""
    return """sequenceDiagram
    participant S as Student
    participant UI as Student App
    participant CB as BAHA Buddy
    participant R as Retrieval Service
    participant Q as BAHA Queue
    S->>UI: Ask question
    UI->>CB: send prompt with consent and profile context
    CB->>R: retrieve approved answer set
    R-->>CB: cited results
    CB-->>UI: grounded response or safe refusal
    alt escalation signal crosses threshold
      CB->>Q: create support case
      UI-->>S: explain support handoff and hotline
    end
"""


def mermaid_learning(data):
    return """flowchart TD
    A["Learning Home"] --> B["Role and Audience Filter"]
    B --> C["Module Detail"]
    C --> D["Lesson Consumption"]
    D --> E["Quiz or Reflection"]
    E --> F["Progress Update"]
    F --> G["Recommendation Refresh"]
"""


def mermaid_games(data):
    if "Student" not in data["title"]:
        return """flowchart TD
    A["Feature Not Applicable"] --> B["Reserved for future role extensions"]
"""
    return """flowchart TD
    A["Games Hub"] --> B["Emotion Explorer"]
    A --> C["Friendship Choices"]
    A --> D["Calm Breathing"]
    B --> E["Signal Aggregation"]
    C --> E
    D --> E
    E --> F["Time Governance Check"]
    F --> G["Progress and Badge Update"]
"""


def mermaid_notifications(data):
    return """flowchart TD
    A["Scheduler or Event Source"] --> B["Notification Policy Check"]
    B --> C["Role and Consent Filter"]
    C --> D["Push or In-App Banner"]
    D --> E["Open Target Screen"]
    E --> F["Audit Log"]
"""


def mermaid_profile(data):
    return """flowchart TD
    A["Profile Home"] --> B["Identity and Preferences"]
    B --> C["Privacy and Consent Controls"]
    C --> D["Data Rights"]
    D --> E["Export or Delete Request"]
"""


def mermaid_settings(data):
    return """flowchart TD
    A["Settings"] --> B["Notifications"]
    A --> C["Privacy"]
    A --> D["Language and Accessibility"]
    A --> E["Policy Documents"]
    A --> F["Support"]
"""


def mermaid_emergency(data):
    if "Student" in data["title"]:
        return """flowchart TD
    A["Acute Safety Disclosure"] --> B["Supportive Acknowledgement"]
    B --> C["Hotline Surface"]
    C --> D["Case Created in BAHA Queue"]
    D --> E["Consent Override Notice"]
    E --> F["Student Returns to App with Support Banner"]
"""
    if "Parent" in data["title"]:
        return """flowchart TD
    A["Safeguarding Notification"] --> B["BAHA-reviewed explanation"]
    B --> C["Conversation Guidance"]
    C --> D["Follow-up instructions"]
"""
    if "Teacher" in data["title"]:
        return """flowchart TD
    A["High Priority Referral Update"] --> B["Teacher notified of next action"]
    B --> C["Counselor-owned follow-up"]
"""
    return """flowchart TD
    A["Acute Signal"] --> B["Priority Queue Case"]
    B --> C["Owner Assignment"]
    C --> D["Hotline and emergency pathway"]
    D --> E["Action logging and closure controls"]
"""


backend_arch = """
# Backend Architecture

## Shared Service Topology

The backend is a modular FastAPI platform with shared services exposed to four separate Flutter clients. Modules are independently testable and deployable behind one API gateway or service mesh.

## Service Domains

| Domain | Responsibilities |
|---|---|
| Identity Service | authentication, session issuance, password reset, guardian linking, staff entitlements |
| Consent Service | consent records, assent records, privacy tiers, version history, withdrawal processing |
| Student Wellbeing Service | check-ins, trends, challenge state, badge state, profile summary |
| Learning Service | content catalog, filtering, progress, quizzes, review states |
| Chatbot Service | Safe Questions retrieval, cited response assembly, out-of-scope handling, profile memory hooks |
| Game Service | scenario delivery, telemetry capture, time governance, aggregate signal generation |
| Notification Service | reminder scheduling, alert delivery, rate limits, policy gating |
| Escalation Service | monitoring rules, case creation, queue prioritization, action logging |
| Analytics Service | event capture, aggregates, dashboard projections, exports |
| Audit Service | tamper-evident event log for consent, content, access, and escalation |

## Deployment Model

- Android pilot clients authenticate against one shared backend
- backend is stateless at the API layer
- PostgreSQL stores operational records
- object storage stores content assets and reports
- vector retrieval index supports grounded chatbot answers
- scheduled workers perform reminders, review-date scans, analytics refreshes, and threshold aggregation

## Non-Functional Decisions

- no third-party child-data analytics SDKs
- no passive sensing collectors in initial launch
- no open-ended LLM generation for sensitive content
- no threshold activation without a named on-call owner
"""


backend_api_flows = """
# API Flows

## Core Request Families

1. Identity and session
2. Consent and privacy tiers
3. Check-ins and trends
4. Learning content and progress
5. Chatbot and Safe Questions
6. Games and telemetry
7. Notifications
8. Escalation and case management
9. Analytics and exports

## Shared Flow Pattern

1. client sends authenticated request
2. API gateway resolves role and deployment context
3. consent and privacy policy checks run when data is sensitive
4. domain service executes command or query
5. audit event is appended for sensitive mutations
6. response is filtered to role-safe payload

## Cross-Service Dependencies

- chatbot may read profile memory but may not expose raw records cross-role
- parent summary depends on trend aggregates and consent tiers
- teacher dashboard depends on weekly cohort rollups and anonymization thresholds
- BAHA queue depends on check-in, chatbot, game, and pastoral signal ingests
"""


backend_auth = """
# Authentication

## Identity Types

- student
- parent or guardian
- teacher
- school counselor
- BAHA clinician
- BAHA admin
- content reviewer

## Auth Requirements

- secure credentials and TLS-only transit
- guardian linkage for minor consent flows
- role-based claims embedded in token/session
- school context for teacher and school counselor roles
- BAHA operational scopes for staff roles

## Authorization Strategy

- coarse role gate at route level
- fine-grained resource policy within services
- privacy-tier filtering at projection layer
- case data exposure only when case access conditions are met
"""


backend_consent = """
# Consent Architecture

## Consent Artifacts

- student assent record
- parent or guardian consent record
- self-consent record for ages 18-19
- school permission record
- privacy tier agreement record
- chatbot profile-building opt-out state

## Consent Lifecycle

1. policy version published
2. student completes age-band and legal-band routing
3. parent consent or self-consent collected
4. privacy tier state recorded
5. consent version changes trigger re-acknowledgement
6. withdrawal request propagates within 24 hours

## Enforcement Rules

- no student feature processing before required consent is active
- parent view is derived from privacy tier projection, not raw data exposure
- acute safety override bypasses privacy tier only for defined categories and is logged
"""


backend_escalation = """
# Escalation Architecture

## Signal Sources

- repeated low mood and high stress check-ins
- repeated poor sleep patterns
- help requests
- chatbot acute safety disclosures
- game-derived repeated high-risk patterns
- teacher pastoral flags

## Escalation Levels

| Level | Trigger Type | Routing |
|---|---|---|
| L1 | monitoring signal | BAHA queue review |
| L2 | counselor follow-up needed | assigned owner and action log |
| L3 | acute safety disclosure | priority queue, hotline surfaced, override notification |

## Operational Rules

- no automatic parent alert before counselor review except where the approved acute protocol explicitly requires it
- every open case requires an owner
- repeated same-day acute events aggregate into one working case with sub-events
- closed cases remain retained per legal policy
"""


backend_vector = """
# Vector Search and Grounded Chatbot Retrieval

## Objective

Support BAHA Buddy with citations and reviewable answers while preventing open-ended clinical generation.

## Content Units

- Safe Questions Q&A pairs
- BAHA learning modules
- approved supportive scripts
- escalation policy copy

## Retrieval Pipeline

1. user prompt classified by topic and safety sensitivity
2. allowed corpus subset selected by role, age band, and review status
3. lexical and vector retrieval runs
4. ranked passages converted into cited answer candidates
5. safety layer blocks non-approved or expired content
6. response assembler returns answer, citation, and help-seeking affordance

## Guardrails

- expired review date excludes content
- sensitive topics must return citation
- unsupported topics return safe refusal plus route to library or human help
"""


backend_analytics = """
# Analytics Architecture

## Event Streams

- onboarding events
- consent changes
- check-in completion events
- trend generation events
- learning completion events
- chatbot query and outcome events
- game session and aggregate signal events
- notification sent/opened events
- case lifecycle events

## Dashboard Families

- student private trend analytics
- parent aggregate summary generation
- teacher class trends
- BAHA pilot analytics

## Privacy Controls

- no third-party behavior profiling
- student private analytics never leave student scope except through approved summary tiers or case workflow
- teacher dashboards require minimum cohort size
- BAHA analytics are aggregate unless a formal case is opened
"""


db_schema = """
# Database Schema

## Core Entity Groups

### Identity and Access

- users
- roles
- schools
- user_role_assignments
- guardian_links
- staff_scope_assignments

### Consent and Policy

- consent_documents
- consent_records
- assent_records
- privacy_tier_records
- override_events

### Student Wellbeing

- student_profiles
- check_in_sessions
- check_in_responses
- trend_snapshots
- mood_vocabulary_progress
- challenge_instances
- badge_awards

### Learning and Content

- content_items
- content_revisions
- content_tags
- module_progress
- quiz_attempts
- safe_question_items

### Chatbot and Games

- chatbot_sessions
- chatbot_messages
- chatbot_profile_summaries
- game_sessions
- game_signal_snapshots

### Escalation and Operations

- pastoral_flags
- support_cases
- case_events
- case_assignments
- notification_events
- audit_events

## Retention-Sensitive Tables

- check_in_responses
- chatbot_messages
- support_cases
- case_events
- consent_records
- audit_events

## Partitioning Guidance

- partition high-volume events by month or quarter
- include school and cohort keys for analytics rollups
- separate content metadata from asset storage
"""


db_er = """erDiagram
    USERS ||--o{ USER_ROLE_ASSIGNMENTS : has
    ROLES ||--o{ USER_ROLE_ASSIGNMENTS : grants
    SCHOOLS ||--o{ USERS : enrolls
    USERS ||--o{ CONSENT_RECORDS : signs
    USERS ||--o{ ASSENT_RECORDS : signs
    USERS ||--o{ STUDENT_PROFILES : owns
    STUDENT_PROFILES ||--o{ CHECK_IN_SESSIONS : submits
    CHECK_IN_SESSIONS ||--o{ CHECK_IN_RESPONSES : contains
    STUDENT_PROFILES ||--o{ TREND_SNAPSHOTS : generates
    STUDENT_PROFILES ||--o{ MODULE_PROGRESS : tracks
    CONTENT_ITEMS ||--o{ CONTENT_REVISIONS : versions
    CONTENT_ITEMS ||--o{ CONTENT_TAGS : tagged
    STUDENT_PROFILES ||--o{ CHATBOT_SESSIONS : starts
    CHATBOT_SESSIONS ||--o{ CHATBOT_MESSAGES : contains
    STUDENT_PROFILES ||--o{ GAME_SESSIONS : plays
    GAME_SESSIONS ||--o{ GAME_SIGNAL_SNAPSHOTS : produces
    STUDENT_PROFILES ||--o{ SUPPORT_CASES : relates_to
    SUPPORT_CASES ||--o{ CASE_EVENTS : logs
    USERS ||--o{ CASE_ASSIGNMENTS : owns
    USERS ||--o{ PASTORAL_FLAGS : submits
    USERS ||--o{ AUDIT_EVENTS : triggers
"""


component_doc = """
# Component Library

## Shared Cross-App Components

- app shell
- top app bar and section header
- bottom navigation or tab rail
- cards
- chips and filters
- CTA buttons
- list rows
- status banners
- empty-state blocks
- loading skeletons
- policy and disclosure panels

## Student-Specific Components

- age-band selector
- check-in input cards
- trend charts and insight tiles
- badge cards
- challenge cards
- game scenario panels
- buddy message bubbles with citations
- crisis handoff banner

## Parent-Specific Components

- summary cards
- conversation guide accordion
- consent status banners
- privacy tier comparison cards

## Teacher-Specific Components

- cohort trend panels
- pastoral note form
- referral cards
- training completion tiles

## BAHA-Specific Components

- priority queue table
- case timeline
- action log composer
- review workflow panel
- threshold rule editor
- analytics cards and export drawer
- audit log table
"""


component_hierarchy = """flowchart TD
    A["App Shell"] --> B["Navigation"]
    A --> C["Page Template"]
    C --> D["Section Header"]
    C --> E["Status Banner"]
    C --> F["Card Grid"]
    F --> G["Action Card"]
    F --> H["Insight Card"]
    F --> I["Content Card"]
    C --> J["Forms"]
    J --> K["Consent Controls"]
    J --> L["Check-In Inputs"]
    J --> M["Pastoral Input"]
    C --> N["Operational Tables"]
    N --> O["Queue Row"]
    N --> P["Audit Row"]
"""


design_tokens = """
# Design Tokens

## Token Families

- color
- typography
- spacing
- radius
- elevation
- motion
- iconography
- component state tokens

## Behavioral Rules

- student-facing tokens should optimize safety, warmth, and readability
- counselor/admin tokens may increase density but must preserve clarity
- semantic tokens, not raw hex values, should drive implementation
"""


typography_doc = """
# Typography

## System Approach

- one readable sans-serif family across all apps
- size and density vary by role surface
- student early cohort uses larger default type and simpler hierarchy
- BAHA operational views use denser tabular and metadata styles

## Recommended Scale

| Token | Usage |
|---|---|
| display | onboarding and hero copy |
| heading-lg | major screens and section intros |
| heading-md | cards and module titles |
| body-lg | student primary reading text |
| body-md | standard app content |
| body-sm | helper text and metadata |
| label | chips, buttons, and tabs |
| mono-sm | audit and operational identifiers |
"""


spacing_doc = """
# Spacing

## Spacing Scale

- 4
- 8
- 12
- 16
- 20
- 24
- 32
- 40
- 48
- 64

## Usage Rules

- student surfaces should favor larger breathing space than operational admin tables
- spacing must support thumb-friendly Android layouts
- consistent outer gutters across role surfaces
"""


colours_doc = """
# Colours

## Semantic Palette Direction

- trust primary
- calm secondary
- warm neutral backgrounds
- success confirmation
- advisory warning
- urgent safeguarding alert

## Role of Color

- student UI uses calm, non-alarmist tones
- parent UI uses clarity over intensity
- teacher UI emphasizes neutrality and anonymized cohort insight
- BAHA UI uses clearer severity coding with restrained operational red use
"""


motion_doc = """
# Motion

## Motion Principles

- never gamify distress
- use gentle transitions for habit and reflection
- reserve stronger motion for success confirmation and urgent support banners
- keep counselor operational tables motion-light and efficiency-focused

## Motion Types

- page entrance
- card reveal
- check-in progression
- breathing guide pulses
- alert banner entrance
- success and completion acknowledgement
"""


api_endpoints = """
# Proposed API Endpoints

## Identity

| Method | Path | Purpose |
|---|---|---|
| POST | /auth/login | authenticate user |
| POST | /auth/logout | revoke session |
| POST | /auth/refresh | refresh session |
| GET | /me | fetch role and entitlement context |

## Consent

| Method | Path | Purpose |
|---|---|---|
| GET | /consent/current | fetch active consent state |
| POST | /consent/parent | create guardian consent record |
| POST | /consent/self | create self-consent record |
| POST | /consent/tiers | save privacy tier agreement |
| POST | /consent/withdraw | request consent withdrawal |

## Student Wellbeing

| Method | Path | Purpose |
|---|---|---|
| GET | /student/home | fetch home aggregates and next actions |
| POST | /student/check-ins | submit weekly or optional daily check-in |
| GET | /student/trends | fetch private trend dashboard |
| GET | /student/profile-summary | fetch plain-language memory summary |
| POST | /student/help-request | create support request |

## Learning

| Method | Path | Purpose |
|---|---|---|
| GET | /learning/modules | list role-filtered modules |
| GET | /learning/modules/{id} | fetch module detail |
| POST | /learning/modules/{id}/progress | save progress |
| POST | /learning/modules/{id}/quiz | submit formative quiz or reflection |

## Chatbot

| Method | Path | Purpose |
|---|---|---|
| POST | /chatbot/messages | send prompt and receive grounded response |
| GET | /chatbot/safe-questions | list Safe Questions |
| POST | /chatbot/profile-opt-out | toggle memory/profile building |

## Games

| Method | Path | Purpose |
|---|---|---|
| GET | /games/catalog | list available games |
| POST | /games/sessions | start or resume game session |
| POST | /games/sessions/{id}/events | append telemetry or milestones |
| POST | /games/time-cap/ack | acknowledge advisory limit |

## Parent

| Method | Path | Purpose |
|---|---|---|
| GET | /parent/summary | fetch current weekly summary |
| GET | /parent/conversation-guides | list guides by theme |

## Teacher

| Method | Path | Purpose |
|---|---|---|
| GET | /teacher/class-trends | fetch anonymized weekly dashboard |
| POST | /teacher/pastoral-flags | submit pastoral signal |
| POST | /teacher/referrals | create referral |

## BAHA

| Method | Path | Purpose |
|---|---|---|
| GET | /baha/queue | fetch operational support queue |
| GET | /baha/cases/{id} | fetch case detail |
| POST | /baha/cases/{id}/events | append action log event |
| GET | /baha/content | fetch content library |
| POST | /baha/content | create or update content |
| POST | /baha/thresholds | save threshold configuration |
| GET | /baha/analytics | fetch aggregate dashboard |
| GET | /baha/audit | fetch audit records |
"""


api_seq = """sequenceDiagram
    participant C as Client App
    participant API as FastAPI
    participant POL as Policy Layer
    participant DOM as Domain Service
    participant DB as PostgreSQL
    participant AUD as Audit Log
    C->>API: request
    API->>POL: role and consent check
    POL-->>API: decision
    API->>DOM: execute
    DOM->>DB: read or write
    DB-->>DOM: result
    DOM->>AUD: append sensitive event
    DOM-->>API: filtered payload
    API-->>C: response
"""


flutter_routing = """
# Flutter Routing

## Client Strategy

- one shared Flutter monorepo or package workspace
- separate app entrypoints for Student, Parent, Teacher, and BAHA
- shared core packages for auth, design tokens, networking, and policy-aware models

## Route Layers

1. bootstrap routes
2. gating routes
3. shell routes
4. feature routes
5. interrupt routes for alerts and emergency states

## Student Route Example

- /launch
- /welcome
- /age-band
- /consent
- /home
- /check-in
- /buddy
- /learn
- /games
- /profile
- /help

## Guards

- auth guard
- consent guard
- training guard
- role guard
- feature availability guard
- connectivity-aware content guard
"""


flutter_nav_graph = """flowchart TD
    A["Launch"] --> B["Bootstrap"]
    B --> C{"Role"}
    C --> D["Student App Shell"]
    C --> E["Parent App Shell"]
    C --> F["Teacher App Shell"]
    C --> G["BAHA App Shell"]
    D --> H["Student Features"]
    E --> I["Parent Features"]
    F --> J["Teacher Features"]
    G --> K["BAHA Features"]
"""


flutter_providers = """
# Providers

## Recommended Provider Families

- session provider
- user context provider
- consent state provider
- check-in draft provider
- trend dashboard provider
- learning catalog provider
- chatbot conversation provider
- game session provider
- notification center provider
- case queue provider
- audit filter provider

## Provider Rules

- keep domain state separate from presentational widget state
- isolate offline cache hydration from UI widgets
- make consent and role context globally readable but mutation-controlled
"""


flutter_repositories = """
# Repositories

## Repository Modules

- AuthRepository
- ConsentRepository
- StudentWellbeingRepository
- LearningRepository
- ChatbotRepository
- GameRepository
- ParentRepository
- TeacherRepository
- BahaOpsRepository
- NotificationRepository
- AnalyticsRepository

## Rules

- repositories expose domain-safe methods rather than raw transport details
- projection filtering for privacy-sensitive payloads should happen server-side, not only client-side
- offline-capable repositories own merge and retry logic
"""


flutter_services = """
# Services

## Client Services

- secure storage service
- API client and token refresh service
- notification registration service
- local cache service
- analytics event emitter
- accessibility and localization service
- offline sync orchestrator

## Cross-Cutting Requirements

- never store secrets in plaintext
- never expose raw sensitive student data in logs
- keep retry behavior idempotent for check-ins, pastoral flags, and case actions
"""


backend_mermaids = {
    "07_Backend/Mermaid/backend.mmd": """flowchart LR
    A["Flutter Apps"] --> B["API Gateway"]
    B --> C["Identity Service"]
    B --> D["Consent Service"]
    B --> E["Student Wellbeing Service"]
    B --> F["Learning Service"]
    B --> G["Chatbot Service"]
    B --> H["Game Service"]
    B --> I["Escalation Service"]
    B --> J["Analytics Service"]
    B --> K["Audit Service"]
    C --> L["PostgreSQL"]
    D --> L
    E --> L
    F --> L
    G --> M["Vector Index"]
    G --> N["Content Store"]
    I --> L
    J --> L
    K --> L
""",
    "07_Backend/Mermaid/authentication.mmd": """sequenceDiagram
    participant U as User
    participant A as App
    participant API as Auth API
    participant DB as Identity Store
    U->>A: submit credentials
    A->>API: login request
    API->>DB: validate identity and role
    DB-->>API: role, scopes, school context
    API-->>A: access and refresh tokens
""",
    "07_Backend/Mermaid/api_sequence.mmd": api_seq,
    "07_Backend/Mermaid/consent_flow.mmd": """flowchart TD
    A["Student identity resolved"] --> B{"Consent band"}
    B -->|"Minor"| C["Guardian consent required"]
    B -->|"18-19"| D["Self-consent required"]
    C --> E["Privacy tier agreement"]
    D --> E
    E --> F["Consent active"]
    F --> G["Policy version watch"]
    G --> H["Re-acknowledge if policy changes"]
""",
    "07_Backend/Mermaid/escalation_flow.mmd": """flowchart TD
    A["Signal source"] --> B["Rule evaluation"]
    B --> C{"Threshold crossed"}
    C -->|"No"| D["Store for analytics only"]
    C -->|"Yes"| E["Create support case"]
    E --> F["Assign owner"]
    F --> G{"Acute safety"}
    G -->|"Yes"| H["Hotline and override notice"]
    G -->|"No"| I["Review queue"]
""",
    "07_Backend/Mermaid/chatbot_pipeline.mmd": """flowchart TD
    A["Prompt"] --> B["Topic and safety classification"]
    B --> C["Audience and review-status filter"]
    C --> D["Lexical and vector retrieval"]
    D --> E["Citation assembly"]
    E --> F{"Approved answer found"}
    F -->|"Yes"| G["Grounded response"]
    F -->|"No"| H["Safe refusal and redirect"]
""",
    "07_Backend/Mermaid/analytics_pipeline.mmd": """flowchart TD
    A["Client events"] --> B["Ingestion"]
    B --> C["Validation and privacy filters"]
    C --> D["Operational store"]
    D --> E["Daily rollups"]
    E --> F["Parent summaries"]
    E --> G["Teacher dashboards"]
    E --> H["BAHA pilot analytics"]
""",
}


file_map = {
    "docs/README.md": product_overview,
    "docs/00_Product_Overview.md": overview_doc,
    "docs/01_Information_Architecture.md": ia_doc,
    "docs/02_Master_User_Journey.md": journey_doc,
    "docs/07_Backend/architecture.md": backend_arch,
    "docs/07_Backend/api_flows.md": backend_api_flows,
    "docs/07_Backend/authentication.md": backend_auth,
    "docs/07_Backend/consent.md": backend_consent,
    "docs/07_Backend/escalation.md": backend_escalation,
    "docs/07_Backend/vector_search.md": backend_vector,
    "docs/07_Backend/analytics.md": backend_analytics,
    "docs/08_Database/schema.md": db_schema,
    "docs/08_Database/er_diagram.mmd": db_er,
    "docs/09_Component_Library/components.md": component_doc,
    "docs/09_Component_Library/hierarchy.mmd": component_hierarchy,
    "docs/10_Design_System/tokens.md": design_tokens,
    "docs/10_Design_System/typography.md": typography_doc,
    "docs/10_Design_System/spacing.md": spacing_doc,
    "docs/10_Design_System/colours.md": colours_doc,
    "docs/10_Design_System/motion.md": motion_doc,
    "docs/11_API/endpoints.md": api_endpoints,
    "docs/11_API/sequence_diagrams.mmd": api_seq,
    "docs/12_Flutter/routing.md": flutter_routing,
    "docs/12_Flutter/navigation_graph.mmd": flutter_nav_graph,
    "docs/12_Flutter/providers.md": flutter_providers,
    "docs/12_Flutter/repositories.md": flutter_repositories,
    "docs/12_Flutter/services.md": flutter_services,
}


for path, content in backend_mermaids.items():
    file_map[f"docs/{path}"] = content


for current_folder, data in apps.items():
    file_map[f"docs/{current_folder}/README.md"] = app_readme(current_folder, data)
    file_map[f"docs/{current_folder}/Navigation.md"] = app_navigation(data)
    file_map[f"docs/{current_folder}/User_Journey.md"] = app_journey(data)
    file_map[f"docs/{current_folder}/Screen_Inventory.md"] = app_screen_inventory(data)
    file_map[f"docs/{current_folder}/Screen_Flows.md"] = app_screen_flows(data)
    file_map[f"docs/{current_folder}/State_Diagrams.md"] = app_state_diagrams(data)
    file_map[f"docs/{current_folder}/Edge_Cases.md"] = app_edge_cases(data)
    file_map[f"docs/{current_folder}/Mermaid/navigation.mmd"] = mermaid_navigation(data)
    file_map[f"docs/{current_folder}/Mermaid/onboarding.mmd"] = mermaid_onboarding(data)
    file_map[f"docs/{current_folder}/Mermaid/dashboard.mmd"] = mermaid_dashboard(data)
    file_map[f"docs/{current_folder}/Mermaid/chatbot.mmd"] = mermaid_chatbot(data)
    file_map[f"docs/{current_folder}/Mermaid/learning.mmd"] = mermaid_learning(data)
    file_map[f"docs/{current_folder}/Mermaid/games.mmd"] = mermaid_games(data)
    file_map[f"docs/{current_folder}/Mermaid/notifications.mmd"] = mermaid_notifications(data)
    file_map[f"docs/{current_folder}/Mermaid/profile.mmd"] = mermaid_profile(data)
    file_map[f"docs/{current_folder}/Mermaid/settings.mmd"] = mermaid_settings(data)
    file_map[f"docs/{current_folder}/Mermaid/emergency.mmd"] = mermaid_emergency(data)


for rel_path, content in file_map.items():
    write(rel_path, content)

print(f"Wrote {len(file_map)} files.")
