# BAHA Wellness Companion — Product Requirements Document
## Adolescent-First Digital Wellness Platform
### BAHA Partnership Edition — Functional Launch PRD and Delivery Roadmap

**Version:** 2.1  
**Status:** Pre-Stakeholder Draft — Requires BAHA Clinical Sign-Off, Consent/Ethics Route, Legal/Data Review, Deployment Ownership, and Mobile Delivery Sign-Off Before Any Live Pilot  
**Primary Deployment Target:** Android-first Flutter mobile app suite  
**Secondary Deployment Target:** iOS app suite after Android pilot stabilization  
**Application Model:** Separate mobile apps for Students, Parents/Guardians, Teachers, and BAHA/Counselors on a shared backend and content platform  
**Clinical Partner:** Bangalore Adolescent Health Academy (BAHA), a sub-speciality chapter of the Indian Academy of Pediatrics  
**Prepared By:** Siobhan Kumar Ghosal, Sudharshan Srinivasan, Solomon Karuppiah  
**Mentors:** Prof. Ruby Dinakar, Prof. Deepa S

**Implementation Note (July 15, 2026):** The live demo prototype now uses one unified Flutter app with role-based student, parent/guardian, teacher, and counselor experiences inside a single mobile shell. References below to separate apps reflect the earlier product structuring model and should be interpreted as separate role surfaces within that unified app unless and until this PRD is fully revised.

---

# 1. Executive Summary

The BAHA Wellness Companion is an adolescent-first, privacy-first digital wellness platform developed in partnership with BAHA. It provides a trusted digital channel for students aged 9–19 to check in on their wellbeing, understand personal patterns, learn from BAHA-reviewed health content, engage with a safe companion chatbot, play insight-generating wellness games, and access support pathways — all without the platform becoming a surveillance tool, a diagnostic system, or a premature AI risk engine.

The platform is structured as a four-role ecosystem delivered as separate mobile applications: a student app as the primary experience, supported by dedicated parent, teacher, and BAHA/counselor apps. BAHA's clinical infrastructure — including its expert network and crisis response capacity — governs all escalation, content review, and safeguarding decisions. The initial launch target is a functioning Android app suite backed by shared operational, analytics, content, and safety services; iOS follows after Android stabilizes.

Rather than positioning itself as a clinical diagnostic tool, the BAHA Wellness Companion is a **self-awareness and support companion** whose strongest contributions are:

- private, low-friction weekly check-ins tied to a personalized trend view
- a BAHA-approved Safe Questions library and companion chatbot (BAHA Buddy) for safe, non-diagnostic Q&A
- insight-generating wellness games with strict time limits and behavioral data that can surface engagement and emotional patterns
- a structured learning module for students, parents, and teachers built on BAHA's existing educational material
- rule-based escalation workflows reviewed by BAHA clinicians, with no automated crisis management
- a privacy model that keeps raw student responses private by default and shares only consented, role-appropriate summaries
- separate stakeholder apps and age-appropriate student UX layers so each role experiences the product through its own task, language, and interaction model

---

# 2. Product Vision

The larger vision for the BAHA Wellness Companion is to shift adolescent health support from **episodic, adult-initiated, reactive intervention** toward a **continuous, student-initiated, self-aware support habit** that young people return to voluntarily because it feels personal, private, and useful — not clinical or obligatory.

Current delivery of adolescent health education is episodic: school talks, handouts, adult-led sessions, and passive materials. The product layer missing from this ecosystem is a trusted digital channel that adolescents use regularly for self-awareness and support before concerns escalate to adults.

Most digital health tools for adolescents fail for one of two reasons: they feel like surveillance and are therefore used dishonestly, or they lack clinical credibility and are therefore dismissed by institutions. The BAHA Wellness Companion addresses this by placing BAHA's clinical authority at the content and escalation layer, while keeping the primary student experience private, engaging, and self-directed. Trust is further reinforced by separating stakeholder experiences into distinct apps rather than role-switched views inside one shared interface, and by allowing the student experience to vary by age cohort without changing the underlying safeguards model.

The guiding principle is: **Support before crisis. Awareness before intervention. Self-knowledge before diagnosis.**

---

# 3. Problem Statement

> How can a BAHA-backed digital wellness platform become a trusted, private, and regularly used support channel for Indian adolescents — one that improves self-awareness and routes support before concerns become visible to adults — without becoming surveillance, premature diagnosis, or an unowned escalation system?

Specific problem dimensions:

- Mental health concerns among adolescents frequently go unnoticed until they become severe enough for parents or teachers to observe.
- Existing interventions are episodic and adult-centric: school talks, handouts, and reactive counselor visits.
- Adolescents do not have a private, trusted digital space to check in, ask sensitive questions, or understand their own patterns.
- BAHA has strong clinically grounded content but no recurring digital delivery channel that students return to voluntarily.
- Academic stress, sleep disruption, digital overuse, and peer pressure around substances are common concerns with no structured self-monitoring pathway.
- Life skill development and self-awareness — foundational for long-term wellbeing — are addressed only sporadically.
- Existing tools either overclaim AI diagnostic capability or lack clinical credibility to be trusted by healthcare partners.

---

# 4. Goals

## 4.1 Primary Goals

- Build a functioning Android-first Flutter mobile app suite consisting of separate Student, Parent, Teacher, and BAHA/Counselor apps, backed by shared platform services.
- Build a working, adolescent-first wellness platform with private check-ins, personalized insights, BAHA micro-content, safe Q&A, a companion chatbot (BAHA Buddy), insight-generating games, and a multi-role learning module.
- Ensure the platform remains privacy-first: check-in data private by default, no passive surveillance, no automatic diagnosis.
- Implement rule-based monitoring and escalation reviewed and approved by BAHA clinicians before any live pilot.
- Build a consent and safeguarding model that works for Indian minors under the DPDP Act 2023 and ICMR guidelines.
- Deliver a functioning launch candidate with working stakeholder apps, shared backend services, content operations, consent management, and pilot-ready deployment for Android.

## 4.2 Secondary Goals

- Enable teachers to provide pastoral input that enriches the student wellbeing picture without compromising student privacy.
- Provide parents with aggregate, consent-gated summaries that support conversation rather than surveillance.
- Use insight-generating games to derive behavioral signals — attention, emotional regulation, decision-making — that can surface patterns without intrusive data collection.
- Build a learning module that serves students, parents, and teachers with BAHA-reviewed health content and tracks completion.
- Support BAHA clinicians with a case management and escalation queue that reduces manual coordination overhead.

## 4.3 Non-Goals

The current project does **not** aim to:

- build an AI-based clinical mental-health risk classifier or suicide-risk prediction engine
- replace human counselors, clinical assessment, or therapeutic treatment
- passively track phone usage, location, contacts, keyboard behavior, or social media content
- integrate wearables or physiological sensors in the initial launch
- implement a general-purpose open-ended AI therapy chatbot
- build a substance-risk scoring or automated substance-escalation module in the initial launch
- guarantee clinical outcome improvement during the initial launch pilot
- release publicly through Google Play or the Apple App Store before operational hardening and policy review are complete

---

# 5. Scope

## 5.1 In Scope — Initial Launch

- Student App: privacy onboarding, weekly check-ins (mood, sleep, energy, stress, lifestyle, academic stress), personal trend dashboard, BAHA micro-content, rule-based nudges, Safe Questions Library, BAHA Buddy chatbot scoped to BAHA-approved content, help pathway, gamification mechanics, and insight-generating games.
- Parent App: consent-gated weekly aggregate summaries, conversation guides, privacy controls, and parent learning journey access.
- Teacher App: anonymized class trends, pastoral input mechanism, referral pathway management, and teacher learning journey access.
- BAHA/Counselor App: support queue, case management, escalation tracking, content review and approval, pilot analytics, and configuration of monitoring thresholds.
- Shared Platform Services: authentication, consent records, privacy-tier enforcement, role-based access control, notifications, audit logs, analytics pipeline, and shared backend APIs.
- Shared Content and Knowledge Services: BAHA content management, Safe Questions Library, Q&A corpus operations, learning module delivery, and evidence-backed chatbot retrieval pipeline.
- Shared Safety and Governance Services: rule-based escalation workflows, acute safety pathway, consent override handling, 24/7 crisis routing, and safeguarding review operations.
- Product Readiness Assets: needs assessment instruments, four-theme BAHA content map, privacy/consent/safeguarding model, and pilot plan for 2–3 Bangalore schools with deployment owner, consent route, and escalation owner identified.

## 5.2 Out of Scope — Initial Launch

- AI mental-health risk prediction, suicide-risk classification, or substance-risk scoring.
- Passive phone/location/social media tracking.
- Wearable or physiological sensor integration.
- Open-ended generative therapy chatbot (chatbot is BAHA-content-scoped).
- Automated crisis management without a named human owner.
- Public app-store release.
- Long-term clinical outcome measurement.
- iOS release before Android pilot stabilization.

---

# 6. Delivery Structure

This PRD is organized in releases so the platform can be built incrementally without reducing the initial launch feature scope.

- **Release 1 — Android Functional Launch:** Separate Student, Parent, Teacher, and BAHA/Counselor Flutter apps; shared backend services; BAHA Buddy; learning module; games; consent workflows; escalation operations; pilot deployment readiness.
- **Release 1.1 — Android Pilot Hardening:** Performance tuning, analytics calibration, threshold review, operational stabilization, QA hardening, and public-store readiness assessment.
- **Release 2 — iOS Expansion and Scale-Up:** iOS versions of the stakeholder apps, broader rollout support, multilingual expansion, and cross-platform parity improvements.
- **Release 3 — Research Extension:** Optional passive sensing, wearables, AI risk modeling — only after BAHA ethics approval and validated Indian dataset collection.

---

# 7. User Roles and Stakeholders

The platform has four primary stakeholder groups. The NGO is a delivery and access partner, not a platform stakeholder in the product sense. BAHA's expert network and 24/7 crisis response capacity are part of BAHA's clinical infrastructure, not separate external parties.

## 7.1 Students (Primary Users)

**Who they are:** Adolescents aged 9–19, divided into early (9–13), mid (14–16), and late (17–19) age bands. Gender and age-group-specific content is served per profile.

**Application Surface:** Dedicated Student App with age-band-adjusted UX, tone, and content presentation.

**What they get:** Private check-ins, personal trend insights, BAHA micro-content, rule-based nudges, gamification mechanics, insight-generating games, BAHA Buddy companion chatbot, Safe Questions Library, community interest features (opt-in), and help/escalation pathways.

**What they do not get:** Public rankings, raw data visible to parents or teachers, AI diagnosis, passive surveillance.

**Responsibilities:** Complete onboarding with age-banded profile; provide assent (alongside parental consent); use the platform voluntarily.

**Key interactions:** Student App → BAHA Buddy → Games → Learning Module → Help Pathway → Escalation Workflow (when needed).

## 7.2 Parents/Guardians

**Who they are:** Parents or guardians of adolescent students enrolled in the platform.

**Application Surface:** Dedicated Parent App focused on summaries, consent controls, conversation support, and awareness content.

**What they get:** Weekly aggregate wellness summaries (consent-gated), conversation guides, educational resources from the learning module (parent track), privacy control settings, and alert notifications only under the approved escalation protocol.

**What they do not get:** Raw check-in responses, personal diary entries, sensitive answers, or real-time location/activity data.

**Responsibilities:** Provide verifiable parental consent before any student data is collected; configure privacy tier settings in collaboration with the student where appropriate; engage with conversation guides when prompted.

**Key interactions:** Parent App → Weekly Summary → Conversation Guides → Learning Module (parent track) → Alert Notification (escalation events only).

## 7.3 Teachers/School Counselors

**Who they are:** Teachers and school counselors at pilot schools.

**Application Surface:** Dedicated Teacher App focused on class trends, pastoral inputs, referrals, and teacher learning resources.

**What they get:** Anonymized class-level wellness trends, pastoral flagging tools, referral pathway management, wellbeing resources, teacher learning track (learning module), and individual student case access only under the approved consent/safeguarding protocol.

**What they do not get:** Raw student check-in data, individual mood/substance entries, or unrestricted student profile access.

**Responsibilities:** Participate in needs assessment; complete BAHA-specified training before any safeguarding alerts are activated; provide pastoral input; manage referrals within the approved workflow.

**Key interactions:** Teacher App → Class Trends Dashboard → Pastoral Flag → Referral Pathway → Learning Module (teacher track) → Escalation Workflow (when needed).

## 7.4 BAHA / Counselors (Clinical and Administrative Layer)

**Who they are:** BAHA clinicians, assigned school counselors operating under BAHA protocol, BAHA content administrators, and BAHA's expert network (psychologists, life-skills coaches, nutritionists, physical activity specialists). The 24/7 crisis response capacity is part of this group.

**Application Surface:** Dedicated BAHA/Counselor App focused on case management, escalation handling, content review, analytics, and system configuration.

**What they get:** Full support queue and case management view, escalation tracking, content review and approval workflow, pilot analytics dashboard, configuration of monitoring thresholds, access to BAHA expert network routing, and 24/7 crisis hotline ownership.

**What they do not get:** More data than necessary for the assigned function; raw data without clinical justification.

**Responsibilities:** Review and approve all nudge wording, escalation thresholds, and content before any live pilot; nominate a named safeguarding owner for each escalation category; ensure 24/7 crisis response coverage; sign off on consent override categories; manage content lifecycle in the learning module.

**Key interactions:** BAHA/Counselor App → Support Queue → Case Management → Escalation Workflow → Content Review → Analytics Dashboard → Expert Network Routing → Crisis Hotline.

## 7.5 Application and Age-Segmentation Model

- The product is delivered as four separate mobile apps sharing a common backend, content layer, analytics pipeline, and safeguarding infrastructure.
- Student UX segmentation and legal consent segmentation are separate concerns. Student-facing UX may vary by age cohort for language, interaction density, visuals, and content framing.
- Legal consent routing is determined by a separate consent band model: users aged 9–17 follow the minor flow with parent or guardian consent; users aged 18–19 follow the self-consent flow.
- Parent, Teacher, and BAHA/Counselor apps are not alternate views of the Student App and should not reuse student navigation patterns.
- Cross-app consistency should exist at the privacy, safety, and data model layers, not at the visual or interaction layer.

---

# 8. Functional Requirements

Each requirement follows this structure: **ID | Name | Description | User Story | Priority | Acceptance Criteria | Dependencies | Edge Cases | Notes.**

Priority levels: **P0** (must-have, blocks initial launch), **P1** (high value, expected in the initial launch), **P2** (important, lower-polish or later-wave launch item), **P3** (future enhancement after launch stabilization).

Application ownership for the functional requirements is interpreted as follows:

- **Student App:** FR-OB, FR-CI, FR-GA, FR-CB, FR-GM, student-facing FR-LM, and the student entry points to help and escalation.
- **Parent App:** FR-PT-001, parent-facing FR-LM, parent privacy settings, and parent consent interactions.
- **Teacher App:** FR-PT-002, FR-AN-003, teacher-facing FR-LM, and referral pathway interactions.
- **BAHA/Counselor App:** FR-ES, FR-AN-004, FR-LM-007, case management, content review, support queue, and threshold configuration.
- **Shared Platform Services:** authentication, notifications, auditability, consent enforcement, data retention, analytics pipelines, chatbot retrieval services, and content delivery services.

---

## 8.1 Onboarding and Profile

---

### FR-OB-001 — Age-Banded Profile Setup

**Description:** During onboarding, students are assigned both a presentation age cohort and a legal consent band. The presentation cohort drives student UX, content framing, and language. The legal consent band determines whether the user follows the minor consent flow or the self-consent flow. Gender input is also collected. The platform uses these values to serve age-appropriate and gender-appropriate content throughout the experience.

**User Story:** As a student, I want to set up my profile once so that everything I see in the app is relevant to my age group and appropriate for me.

**Priority:** P0

**Acceptance Criteria:**
- Student can be routed into both a presentation age cohort and a legal consent band during onboarding.
- Presentation cohort can be selected without exposing full date of birth in the student-facing UI; legal consent routing may use the minimum age information required by the approved consent process.
- All content, nudges, chatbot prompts, and game content are filtered by the student's age band from first use.
- Profile is stored locally and/or server-side under the approved data storage model.
- Profile can be updated if the student changes age band over time.

**Dependencies:** Content tagging by age band (FR-LM-002). BAHA content review completed.

**Edge Cases:** Student selects the wrong age band intentionally. Resolution: allow profile edit; do not gate or verify. Student skips gender input. Resolution: serve default (non-gendered) content.

**Notes:** Age band selection should use plain-language descriptions, not just numeric ranges, to ensure comprehension across literacy levels.

---

### FR-OB-002 — Privacy and Consent Onboarding Screen

**Description:** Before any data is collected, the student must see and acknowledge a plain-language privacy screen explaining what stays private, what may be summarised, when safety overrides apply, and their data rights. Parent or guardian consent must be obtained for minors before onboarding is completed; users aged 18–19 must complete the self-consent flow.

**User Story:** As a student, I want to clearly understand what is private, what my parents can see, and when the app might involve an adult, before I share anything.

**Priority:** P0

**Acceptance Criteria:**
- Privacy screen is displayed before any check-in or chatbot interaction is allowed.
- Screen includes: what stays private, what may be summarised, safety override conditions, data rights (view/delete).
- Student must actively acknowledge the screen (not just dismiss it) to proceed.
- Parental or guardian consent confirmation is required before onboarding is marked complete for users aged 9–17.
- Self-consent confirmation is required before onboarding is marked complete for users aged 18–19.
- Screen language passes readability testing with the target age band.

**Dependencies:** BAHA and legal review of privacy wording. Consent route approval (FR-PR-001).

**Edge Cases:** Student under 13 whose parent has not completed consent. Resolution: block data collection until consent is received. Student re-opens app after consent expires. Resolution: re-prompt consent flow.

**Notes:** The privacy promise wording from the existing PRD must be used verbatim unless BAHA revises it. No data collection of any kind before this screen is acknowledged.

---

### FR-OB-003 — Consent Tier Configuration

**Description:** At onboarding and at any later time, students in the self-consent band or parent/guardian together with the student in the minor flow can configure which privacy tiers of data are shared with parents. Data is classified from least to most private. Parents may see only the tiers they are granted access to.

**User Story:** As a parent, I want to agree with my child on what I can see in the app so that the app helps us have conversations rather than breaking trust.

**Priority:** P1

**Acceptance Criteria:**
- Consent tier configuration screen is shown during onboarding and accessible in settings.
- Minimum three privacy tiers are defined: (1) completion/engagement data, (2) aggregate wellness trends, (3) individual sensitive responses. Parents may access tier 1 or tiers 1+2 only; tier 3 is always private unless a safety override is triggered.
- Tier selections are stored and enforced across all parent-facing views.
- Students can review and adjust tier settings at any time; changes for users aged 9–17 follow the approved parent or guardian consent framework, while users aged 18–19 can adjust settings directly.

**Dependencies:** FR-OB-002. BAHA review of tier definitions.

**Edge Cases:** Parent and student disagree on tier settings. Resolution: default to the more restrictive tier. Parent consent is withdrawn after setup. Resolution: revert to minimum-share configuration within 24 hours.

**Notes:** Tier definitions must be reviewed by BAHA before pilot. The tier system addresses the stakeholder feedback requirement that parents can be allowed access to only non-private or least-private categories.

---

## 8.2 Check-Ins and Personal Trend Dashboard

---

### FR-CI-001 — Weekly Check-In (Core Cadence)

**Description:** The default engagement cadence is weekly, not daily. Students complete a short structured check-in covering mood, sleep quality, energy, stress, perceived screen time, physical activity, lifestyle factors (food habits, social life), and academic stress. Daily check-ins are available as an optional higher-engagement mode.

**User Story:** As a student, I want to check in on how I'm feeling this week so I can track my patterns without it feeling like homework every day.

**Priority:** P0

**Acceptance Criteria:**
- Weekly check-in prompt is served at the student's chosen day/time.
- Check-in covers all eight input dimensions: mood, sleep, energy, stress, screen time, physical activity, lifestyle, academic stress.
- Total check-in completion time is under 3 minutes.
- Daily optional check-in mode is available but not the default.
- Missed check-ins do not trigger shame messaging; the streak resets without negative reinforcement.
- Check-in data is stored privately and used only for the student's personal trend dashboard and (if consented) aggregate parent summaries.

**Dependencies:** FR-OB-002 (privacy acknowledged). BAHA review of question wording.

**Edge Cases:** Student submits a check-in mid-week and then again at the weekly prompt. Resolution: store both; display the most recent in the dashboard. Student submits extreme values (e.g., lowest possible mood repeatedly). Resolution: trigger monitoring signal (FR-ES-001); do not block submission.

**Notes:** Question wording must be reviewed per age band. Clinical language must be avoided in student-facing text. HEADSS and SSHADESS frameworks should inform which domains are covered.

---

### FR-CI-002 — Mood Vocabulary Builder

**Description:** Over time, the app helps students identify and name their emotions with increasing precision. Initial check-ins offer simple mood categories; over time, a richer vocabulary of feeling words is introduced contextually.

**User Story:** As a student, I want to get better at describing exactly how I feel so I understand myself more clearly.

**Priority:** P1

**Acceptance Criteria:**
- Initial mood selection uses simple categories (e.g., happy, okay, sad, stressed, angry, tired).
- After 4+ weeks of check-ins, more nuanced vocabulary options are introduced progressively.
- No diagnosis labels are ever presented to the student.
- Vocabulary expansion is age-band-appropriate.

**Dependencies:** FR-CI-001. Content review by BAHA.

**Edge Cases:** Student resets their profile. Resolution: restart vocabulary progression from the beginning.

**Notes:** Vocabulary should be developed in consultation with BAHA's clinical team. The goal is emotional literacy, not emotional categorization for clinical purposes.

---

### FR-CI-003 — Personal Trend Dashboard

**Description:** Students see a simple, non-diagnostic weekly trend view summarizing their check-in patterns. Insights are phrased in plain, supportive language (e.g., "Your sleep felt lighter on days you reported late screen use"). No clinical labels or risk scores are displayed.

**User Story:** As a student, I want to see a simple picture of how my week went so I can notice patterns for myself.

**Priority:** P0

**Acceptance Criteria:**
- Dashboard displays trends for all check-in dimensions across the past 4 weeks minimum.
- Insights are expressed in the student's own check-in language, not clinical terminology.
- No risk scores, warning labels, or clinical diagnoses appear anywhere in the student view.
- Dashboard is accessible at any time, not only immediately after check-in.
- Trend visualizations are age-appropriate in complexity.

**Dependencies:** FR-CI-001.

**Edge Cases:** Fewer than 2 check-ins completed. Resolution: show a prompt to complete more check-ins before trend analysis is meaningful; do not show empty charts.

**Notes:** Visualization style should be validated in usability testing with the target age band.

---

### FR-CI-004 — Indirect Assessment Mode

**Description:** For sensitive domains (e.g., substance exposure, peer pressure, sexual health concerns), the platform uses indirect, non-confrontational assessment approaches — contextual scenarios, reflection prompts, or analogy-based questions — rather than direct self-disclosure questions.

**User Story:** As a student, I want to be able to indicate that something is bothering me without having to say it directly.

**Priority:** P1

**Acceptance Criteria:**
- Indirect assessment question types are defined and reviewed by BAHA for each sensitive domain.
- Indirect responses feed into the same monitoring signals as direct responses without labeling the student's answer as a risk indicator.
- Students are not alerted that indirect assessment is being used.

**Dependencies:** BAHA clinical review of indirect question designs. FR-CI-001.

**Edge Cases:** Indirect assessment signals conflict with direct check-in responses. Resolution: flag both for human review if they cross the monitoring threshold; do not automate resolution.

**Notes:** Inspired by SSHADESS framework's strengths-based and indirect approach. Must be reviewed by BAHA before any deployment.

---

## 8.3 Engagement and Gamification

---

### FR-GA-001 — Check-In Streaks

**Description:** Students earn streak recognition for completing check-ins consistently. Streaks reward consistency, not "good" wellness scores. No shame messaging for missed days.

**User Story:** As a student, I want to be encouraged to keep checking in regularly without feeling bad if I miss a day.

**Priority:** P1

**Acceptance Criteria:**
- Streak counter increments for each completed check-in within the student's cadence (weekly or daily).
- Missing a check-in resets the streak silently — no negative reinforcement message.
- Streak milestones (e.g., 4-week, 8-week, 3-month) trigger private milestone recognition (not public).
- Streak display is optional and can be turned off in settings.

**Dependencies:** FR-CI-001.

**Edge Cases:** Student completes check-in one day late due to network issues. Resolution: allow a grace period (configurable, default 24 hours) for late submissions without streak reset.

---

### FR-GA-002 — Progress Badges and Milestones

**Description:** Students earn private badges for completing specific wellness actions: finishing a learning module, trying a new breathing exercise, completing a sleep reset challenge, submitting a reflection. Badges are private (no public leaderboards).

**User Story:** As a student, I want to feel a sense of progress as I learn and try new things in the app.

**Priority:** P1

**Acceptance Criteria:**
- Badge library covers all major action categories: check-ins, learning modules, games, safe questions, reflections, help-pathway engagement.
- Badges are visible only to the student in their private profile.
- Badge achievement does not require "good" wellness outcomes — only action completion.
- Badge descriptions explain what was accomplished in plain language.

**Dependencies:** FR-CI-001, FR-GM-001 (Games), FR-LM-001 (Learning Module).

**Edge Cases:** Student earns a badge related to a sensitive action (e.g., "Asked for Help"). Resolution: badge is shown with supportive, non-stigmatizing language.

---

### FR-GA-003 — Wellness Habit Challenges

**Description:** Students can opt into structured short-duration habit challenges: 3-night sleep reset, 7-day screen wind-down, 5-day mood journal, academic stress reflection week. Each challenge has a defined start, daily or weekly action, and reflection prompt at the end.

**User Story:** As a student, I want to try a short experiment to see if changing one habit makes me feel better.

**Priority:** P1

**Acceptance Criteria:**
- At least four challenge types are available at launch: sleep reset, screen wind-down, mood journal, stress reflection.
- Challenges are opt-in only; no challenge is automatically started.
- Challenge completion is tracked privately and contributes to milestone badges.
- End-of-challenge reflection is prompted and stored privately.
- Challenges are age-band-appropriate.

**Dependencies:** FR-CI-001, FR-GA-002. BAHA content review.

---

### FR-GA-004 — Learning Completion Milestones

**Description:** Students earn recognition for completing BAHA learning modules. Milestones mark progress through the learning journey without creating competitive pressure.

**Priority:** P1

**Acceptance Criteria:** See FR-LM-004 (Learning Progress Tracking).

---

### FR-GA-005 — Community Interest Matching (Opt-In)

**Description:** Students can optionally join interest-based peer groups (e.g., sports, creative arts, music, study circles) within the platform. Interaction in these groups is moderated and anonymized. This feature is opt-in and requires separate consent review.

**User Story:** As a student, I want to connect with others who share my interests in a safe, moderated space within the app.

**Priority:** P2

**Acceptance Criteria:**
- Interest group feature is opt-in; students are not added by default.
- All group interactions are anonymized (no real names shown by default).
- Group content is moderated; BAHA/admin can remove content.
- Separate consent covers community participation.
- Social features are not visible in the parent or teacher view.

**Dependencies:** Separate privacy and consent review. Moderation infrastructure.

**Edge Cases:** Student joins a group and encounters distressing content. Resolution: report mechanism triggers BAHA review; content is removed within 24 hours.

**Notes:** This feature requires a dedicated moderation workflow and BAHA sign-off before live activation.

---

### FR-GA-006 — Nearby Events Discovery (Opt-In)

**Description:** Students can optionally discover local events, activities, and wellness programs (sports, arts, mental health workshops) matching their interests. This is a curated directory feed, not a social media feature.

**Priority:** P2

**Acceptance Criteria:**
- Events feed is opt-in and uses only coarse location (city level, not precise GPS).
- Events are curated and vetted by BAHA/NGO before appearing in the feed.
- No event requires in-app purchase or exposes the student to unknown third parties.

**Dependencies:** Location consent (coarse only). Event curation workflow. Launch-readiness review for partner and safety operations.

---

## 8.4 Chatbot Companion — BAHA Buddy

---

### FR-CB-001 — Companion Chatbot Core

**Description:** BAHA Buddy is a non-diagnostic companion chatbot that students can talk to for support, reflection, and guidance. It answers questions using BAHA-approved content, helps students reflect on their feelings, provides coping suggestions, and routes help requests to the appropriate support pathway. It does not provide clinical diagnosis, medical advice, or generative responses outside the approved BAHA content corpus.

**User Story:** As a student, I want to have something I can talk to privately that gives me helpful, safe responses — not a robot that judges me or diagnoses me.

**Priority:** P0

**Acceptance Criteria:**
- BAHA Buddy responds only within the BAHA-approved content corpus for sensitive topics.
- All responses in sensitive domains (mental health, substances, sexual health, self-harm) are drawn from the BAHA Safe Questions Library, with source citations visible to the student.
- Chatbot clearly identifies itself as a non-clinical companion, not a doctor, counselor, or therapist.
- Students can exit the chatbot and access the help pathway (human support) at any time.
- Chatbot is available 24/7 within the app.
- No raw conversation transcripts are transmitted externally without explicit student consent.

**Dependencies:** BAHA-approved Q&A corpus (FR-CB-002). FR-OB-002 (privacy acknowledged). FR-ES-001 (escalation workflow).

**Edge Cases:** Student asks a question outside the approved corpus. Resolution: chatbot acknowledges the question, explains it cannot answer on that topic, and offers to connect with the Safe Questions Library or a human support pathway. Student attempts to "break" the chatbot with inappropriate prompts. Resolution: chatbot de-escalates, redirects, and logs the interaction flag for BAHA review.

**Notes:** The chatbot implementation must be reviewed and approved by BAHA before activation. Generative AI response paths (if used) must be restricted to a retrieval-augmented model grounded strictly in the BAHA content corpus, with no hallucination-prone open-ended generation for clinical content.

---

### FR-CB-002 — BAHA Safe Questions Library Integration

**Description:** BAHA Buddy draws on a curated library of BAHA-reviewed question-and-answer pairs covering mental health, sleep, screen habits, substance peer pressure, privacy, and escalation guidance. Each answer includes a source citation and a help-seeking prompt.

**Priority:** P0

**Acceptance Criteria:**
- All Q&A pairs in the library are reviewed and approved by a named BAHA clinical reviewer before deployment.
- Each answer includes: the approved response text, a source citation (BAHA module or reference), an age-band flag, and a review date.
- Library is updatable by BAHA admins without requiring a new app release.
- Expired or flagged Q&A pairs are automatically suppressed until re-reviewed.

**Dependencies:** BAHA clinical reviewer assigned. Content management system in BAHA/counselor app.

---

### FR-CB-003 — Student Profile Building by Chatbot

**Description:** BAHA Buddy builds a private, longitudinal student profile based on chatbot interactions. The profile tracks emotional patterns, engagement habits, common concerns, support preferences, learning interests, and potential risk indicators over time. This profile is used to personalize future chatbot responses and to inform the monitoring signals reviewed by BAHA clinicians.

**User Story:** As a student, I want the app to remember that I've been stressed about exams so it doesn't make me explain everything from scratch each time.

**Priority:** P1

**Acceptance Criteria:**
- Profile is built incrementally across sessions; no single session requires complete disclosure.
- Profile includes at minimum: emotional pattern trends (from chatbot interactions), most frequently raised concerns, preferred support types (informational / reflective / referral), learning module interests, and any risk indicators flagged by escalation logic.
- Profile is stored locally or server-side per the approved data storage model; not transmitted externally in raw form.
- Student can view a plain-language summary of their profile at any time.
- Student can request deletion of profile data per the data rights provisions.
- Profile is not visible to parents or teachers.

**Dependencies:** FR-CB-001. FR-OB-002 (privacy model). FR-ES-002 (escalation signals).

**Edge Cases:** Student deletes their profile mid-escalation. Resolution: escalation in progress is not cancelled; the counselor record is retained under the safeguarding protocol even if student profile is deleted.

**Notes:** The profile must not be used for clinical diagnosis or risk scoring without BAHA clinical review. It is a personalization and pattern-awareness tool, not a clinical assessment instrument.

---

### FR-CB-004 — Chatbot Escalation Detection

**Description:** BAHA Buddy monitors conversation signals for indicators of distress, self-harm ideation, abuse disclosure, substance crisis, or other serious concerns. When such signals are detected above the BAHA-defined threshold, the chatbot transitions to the escalation workflow, surfaces the crisis hotline, and routes to the BAHA support queue.

**User Story:** As a student, if I'm going through something serious and I mention it to the app, I want it to connect me to real help, not just give me a generic response.

**Priority:** P0

**Acceptance Criteria:**
- Signal detection logic is reviewed and approved by BAHA before activation.
- Escalation triggers are defined for at minimum: self-harm ideation, suicidal ideation, abuse/violence disclosure, acute substance crisis, and POCSO-covered disclosures.
- When an escalation signal is detected, the chatbot: (1) acknowledges the student with a supportive, non-alarmist message; (2) surfaces the 24/7 crisis hotline; (3) offers to connect with a counselor; (4) creates a case in the BAHA support queue.
- Escalation does not happen silently — the student is informed that support is being arranged.
- Escalation logic does not block the student from continuing to use the app.
- False-positive escalations are reviewable by BAHA and feed back into signal calibration.

**Dependencies:** FR-ES-001 (escalation workflow). BAHA-defined signal thresholds. Named safeguarding owner confirmed.

**Edge Cases:** Student triggers escalation and then closes the app. Resolution: case remains open in the BAHA support queue; counselor attempts follow-up via the school pathway within the agreed response time. Escalation triggered outside school hours. Resolution: 24/7 crisis hotline is surfaced; BAHA after-hours owner is notified.

**Notes:** No escalation pathway should be activated without a named, available human responder. Thresholds remain disabled until BAHA signs off and pilot support is staffed.

---

### FR-CB-005 — Chatbot Privacy and Consent Controls

**Description:** Students are informed at onboarding and within the chatbot interface about what chatbot conversations are stored, how they are used, and under what conditions they may be reviewed by BAHA. Students can opt out of profile building while retaining chatbot access.

**Priority:** P0

**Acceptance Criteria:**
- Chatbot privacy disclosure is shown before the first chatbot interaction.
- Students can opt out of longitudinal profile building; opting out limits chatbot personalization but does not block access.
- BAHA clinicians can access chatbot interaction records only under the escalation protocol or with explicit student/guardian consent.
- Chatbot data is not used for research or training without separate ethics-approved consent.

**Dependencies:** FR-OB-002. BAHA legal review.

---

## 8.5 Insight-Generating Games

Games are distinct from gamification mechanics. Each game is designed to improve or support cognitive and emotional skills while generating behavioral signals that can surface patterns in engagement, attention, stress, decision-making, or emotional regulation. Games are not generic entertainment. Every game session has a strict maximum of 30 minutes.

---

### FR-GM-001 — Emotion Explorer

**Description:** A scenario-based game where students navigate short social situations and identify emotions experienced by characters. Students choose from a set of emotion options, receive BAHA-reviewed explanations, and reflect on whether they've felt similarly. The game builds emotional literacy and surfaces which emotion categories the student finds easiest or most difficult to identify.

**Behavioral Insights Generated:**
- Accuracy of emotion recognition across primary emotion categories.
- Time to response (as a proxy for cognitive ease/difficulty with specific emotions).
- Pattern of emotion categories the student repeatedly misidentifies or avoids.
- Self-reflection engagement rate (measures willingness to connect game scenarios to personal experience).

**User Story:** As a student, I want to play a game that helps me understand emotions better in everyday situations.

**Priority:** P1

**Acceptance Criteria:**
- Scenarios are BAHA-reviewed, age-band-appropriate, culturally sensitive, and free of stigmatizing language.
- Game session is capped at 30 minutes; hard cutoff with a reminder at 25 minutes.
- Behavioral signals are logged privately; student can see a simple summary (e.g., "You found surprise the trickiest to spot this week").
- Signals feed into the chatbot profile (FR-CB-003) and monitoring layer (FR-ES-001) only at aggregate, not at per-response level.
- Game is accessible offline with a subset of scenarios.

**Dependencies:** BAHA content review of all scenarios. FR-OB-002 (privacy). FR-GA-002 (badge on completion).

**Edge Cases:** Student selects the same emotion for every scenario. Resolution: game adapts by introducing forced-choice scenarios; flag unusual response pattern for counselor awareness (not as a clinical alert).

---

### FR-GM-002 — Friendship Choices

**Description:** A narrative decision-making game where students navigate social scenarios involving peer pressure, conflict, digital communication, and bystander situations. Students make choices and see the consequences unfold. The game builds decision-making skills and social reasoning, and generates signals about how students approach peer conflict and pressure.

**Behavioral Insights Generated:**
- Decision patterns under peer pressure (e.g., tendency to comply, resist, or seek help).
- Response to conflict scenarios (avoidance vs. engagement).
- Recognition of unhealthy relationship dynamics.
- Repeated selection of high-risk narrative paths (potential flag for counselor awareness).

**User Story:** As a student, I want to practice handling tricky social situations in a safe space where I can see what might happen.

**Priority:** P1

**Acceptance Criteria:**
- All narrative paths are BAHA-reviewed; no path normalizes harm, abuse, or substance use.
- Game session capped at 30 minutes.
- Students can replay scenarios to explore different outcomes.
- Behavioral signals are stored privately.
- Scenarios include culturally relevant Indian social contexts.

**Dependencies:** BAHA narrative review. FR-OB-002.

**Edge Cases:** Student repeatedly chooses the highest-risk narrative path across multiple sessions. Resolution: after BAHA-defined threshold, flag to counselor awareness queue (not as an automated alert); counselor reviews and decides whether to follow up.

---

### FR-GM-003 — Calm Breathing and Stress Regulation Activities

**Description:** A guided interactive breathing and grounding activity, presented as a game-like experience with visual pacing guides, gentle audio cues, and a simple reflection prompt at the end. Sessions are short (3–10 minutes). The activity generates signals about which regulation techniques the student engages with and whether engagement correlates with preceding stress check-in scores.

**Behavioral Insights Generated:**
- Engagement rate with breathing/grounding activities (correlates with stress reports).
- Technique preference (breathing vs. grounding vs. visualization).
- Session completion rate as a proxy for motivation and openness to self-regulation.

**User Story:** As a student, I want a quick way to calm down when I'm stressed that actually feels engaging rather than awkward.

**Priority:** P0

**Acceptance Criteria:**
- Multiple techniques available: 4-7-8 breathing, box breathing, 5-4-3-2-1 grounding, visualization.
- Visual and audio cues are adjustable for accessibility.
- Session is 3–10 minutes; not subject to the 30-minute cap (shorter by design).
- Post-activity reflection prompt is optional.
- Technique recommendation is based on the student's current check-in stress score if available.

**Dependencies:** FR-CI-001 (stress check-in). BAHA review of techniques.

---

### FR-GM-004 — Game Session Governance

**Description:** All game sessions are subject to the 30-minute maximum cap. The platform tracks total daily game time and surfaces a gentle "time to take a break" message if the student has played for 30 minutes within a 24-hour window. This directly addresses the gamification/screen-time trade-off concern raised in the stakeholder feedback.

**Priority:** P0

**Acceptance Criteria:**
- Each game session has a hard maximum of 30 minutes per session.
- A reminder is shown at 25 minutes within a session.
- Total daily game time is tracked; a gentle break prompt appears if 30 minutes of total game play is reached in a 24-hour window.
- Student can dismiss the prompt and continue; it is advisory, not a hard block (except for age band under 13, where it is a soft block requiring confirmation).
- No game data is used for advertising or third-party profiling.

**Dependencies:** FR-OB-002. Age-band profile (FR-OB-001).

---

## 8.6 Learning Module

---

### FR-LM-001 — Multi-Role Learning Module

**Description:** A structured learning platform serving three roles: students, parents, and teachers. Each role has a distinct learning journey built from BAHA's existing educational material, covering both psychological and physical health topics. Content is role-appropriate, age-banded (for students), and updatable by BAHA admins.

**User Story:** As a student, I want to learn about topics like sleep, stress, and mental health in a way that makes sense for my age. As a parent, I want to learn how to support my child's health. As a teacher, I want to understand the wellness themes my students are engaging with.

**Priority:** P1

**Acceptance Criteria:**
- Three distinct learning journeys are available: student track, parent track, teacher track.
- Student track content is filtered by age band.
- All content is BAHA-reviewed before publication.
- Content can be updated by BAHA admins without requiring a new app release.
- Each role's learning journey is accessible from within their respective app view.

**Dependencies:** BAHA content access. Content management system (FR-LM-007). FR-OB-001 (age band).

---

### FR-LM-002 — Content Categorization and Tagging

**Description:** All learning content is tagged with: theme (sleep/activity, mental health/emotional wellbeing, digital/media use, substance awareness, life skills, nutrition, social wellbeing), age band (early/mid/late), role (student/parent/teacher), format (card/video/quiz/story/checklist/reflection), and review status.

**Priority:** P1

**Acceptance Criteria:**
- Content tagging schema is defined and approved before content ingestion begins.
- All published content carries a complete tag set.
- Tag-based filtering is functional in the student, parent, and teacher views.
- Content without a complete tag set cannot be published to students.

**Dependencies:** BAHA clinical reviewer sign-off on tagging schema.

---

### FR-LM-003 — Multimedia Content Support

**Description:** Learning content can be delivered in multiple formats: short text cards, illustrated stories, short videos (≤5 minutes), audio narrations, infographics, interactive checklists, and reflection prompts. Format selection is guided by age band and content type.

**Priority:** P1

**Acceptance Criteria:**
- All six format types are supported in the content management system.
- Videos are capped at 5 minutes.
- Audio narrations have accessible transcripts.
- Infographics have alt-text.
- Content is accessible on low-bandwidth connections (offline caching for text and audio; video requires WiFi prompt).

**Dependencies:** FR-LM-001. BAHA content in digitizable formats.

---

### FR-LM-004 — Learning Progress Tracking

**Description:** Each user's progress through their learning journey is tracked. Students see a private progress view. Teachers and BAHA admins see aggregate completion rates (not individual sensitive content completion). Parents see completion of modules they are enrolled in.

**Priority:** P1

**Acceptance Criteria:**
- Progress is tracked per module, per role, per user.
- Student progress view is private; shows completed modules, in-progress modules, and recommended next modules.
- Teacher/BAHA aggregate view shows class-level completion rates without individual sensitive content detail.
- Completion milestones feed into the gamification badge system (FR-GA-004).
- Progress is retained across app updates.

**Dependencies:** FR-LM-001. FR-GA-002 (badges).

---

### FR-LM-005 — Quizzes and Assessments

**Description:** Each learning module includes a short quiz or reflection assessment to reinforce learning. Quizzes are formative (not graded for pass/fail); they provide feedback and re-explain concepts where responses indicate a gap. No quiz score is shared with parents or teachers.

**Priority:** P1

**Acceptance Criteria:**
- Every module has at least one associated quiz or reflection prompt.
- Quiz feedback is immediate, supportive, and non-punitive.
- No quiz scores are shared outside the student's private view.
- Incorrect answers trigger a brief re-explanation, not a negative message.
- Quiz completion (not score) contributes to module progress.

**Dependencies:** FR-LM-001. BAHA review of quiz content.

---

### FR-LM-006 — Parent and Teacher Awareness Modules

**Description:** Dedicated modules are available in the parent track and teacher track covering: understanding adolescent development, supporting mental health conversations at home/school, recognizing warning signs, how to use the BAHA Wellness Companion effectively, and what to do when concerned about a student.

**Priority:** P1

**Acceptance Criteria:**
- Parent track includes at minimum: understanding adolescent health themes, conversation guide for each theme, privacy model explanation, how to interpret weekly summaries.
- Teacher track includes at minimum: understanding the wellness themes, how to use the class trends dashboard, referral pathway, pastoral flagging guide, safeguarding training overview.
- Both tracks are completable in under 2 hours total.
- Completion is tracked and confirmed before teachers/parents receive system access to more sensitive features.

**Dependencies:** FR-LM-001. BAHA review. Teacher and parent onboarding flows.

---

### FR-LM-007 — BAHA Admin Content Management

**Description:** BAHA admins can create, review, publish, update, archive, and flag content in the learning module without requiring a developer. A content workflow supports draft → clinical review → approved → published states. Content with expired review dates is automatically flagged for re-review.

**Priority:** P1

**Acceptance Criteria:**
- Admin content management interface supports all CRUD operations on learning content.
- Content lifecycle states: draft, under review, approved, published, archived, flagged.
- Review date is required for all published content.
- Content that passes its review date is automatically moved to "flagged" status until re-approved.
- Admin interface is role-gated to BAHA clinical and admin accounts only.

**Dependencies:** BAHA/counselor app admin interface. FR-LM-002.

---

## 8.7 Parent and Teacher Support Features

---

### FR-PT-001 — Parent Weekly Summary

**Description:** Parents receive a weekly aggregate summary (consent-gated) covering: sleep consistency, mood trend direction (improving/declining/stable — not the specific mood words), module completion, and a suggested conversation guide.

**Priority:** P1

**Acceptance Criteria:**
- Summary is delivered once per week; no more.
- Summary content is strictly limited to the tiers approved in the consent configuration (FR-OB-003).
- No raw check-in responses, mood words, or diary entries are shown.
- A BAHA-reviewed conversation guide is included alongside the summary.
- Parent can disable summaries at any time.

**Dependencies:** FR-OB-003 (consent tiers). FR-CI-001 (check-in data). BAHA review of summary language.

---

### FR-PT-002 — Teacher Pastoral Input

**Description:** Teachers can flag pastoral observations about students (e.g., "seemed distressed in class," "disclosed a concern informally") into the system. These flags are visible to the assigned counselor and BAHA as soft signals, not as direct alerts. Student privacy is protected: flags are counselor-mediated, not directly surfaced to parents.

**User Story:** As a teacher, I want to be able to note that a student seemed to be struggling this week so the counselor has context, without me having to formally report every observation.

**Priority:** P1

**Acceptance Criteria:**
- Pastoral flag input is available in the teacher app.
- Flags are text-based (brief, free-text note) and structured category options.
- Flags are visible to the assigned counselor and BAHA admin only.
- Flags are not visible to parents.
- Flags are not visible to students.
- Flag data is retained for the counselor case review period and then anonymized.

**Dependencies:** Teacher app. Counselor/BAHA app support queue. Privacy review.

---

### FR-PT-003 — Live One-to-One Counselor Sessions

**Description:** The platform supports scheduling of live one-to-one video or in-person sessions between students and their assigned school counselor. Session scheduling is initiated by the student or counselor. Video sessions (if offered) use a vetted, privacy-compliant video platform.

**Priority:** P2

**Acceptance Criteria:**
- Student can request a session from within the app; counselor receives the request in their support queue.
- Session type (in-person or video) is selectable.
- Session records (date, type, duration) are stored in the counselor case management view.
- No session content is recorded or transcribed without explicit consent from all parties.

**Dependencies:** Counselor availability and scheduling infrastructure. BAHA approval of video platform. Launch-readiness review for privacy and operational support.

---

## 8.8 Escalation Workflows

---

### FR-ES-001 — Rule-Based Monitoring Signals

**Description:** The monitoring framework uses BAHA-reviewed, human-authored rules (not AI prediction) to detect signal patterns from check-ins, chatbot interactions, game behavioral signals, and teacher pastoral flags. When patterns cross BAHA-defined thresholds, the monitoring signal triggers a review prompt in the BAHA/counselor support queue.

**Priority:** P0

**Acceptance Criteria:**
- All signal rules and thresholds are defined, reviewed, and approved by BAHA before activation.
- Signals cover at minimum: repeated poor sleep, repeated low mood/high stress, help request, acute safety disclosure, academic stress pattern, game-derived behavioral flags.
- No threshold is activated without a named human counselor/BAHA owner confirmed.
- Monitoring signals surface in the counselor support queue; they do not send automatic alerts to parents or teachers without counselor review.
- Thresholds are configurable per deployment context (school, age group) by BAHA admins.
- False-positive rates are reviewed weekly during pilot.

**Dependencies:** BAHA clinical review of all rules and thresholds. Named safeguarding owner per escalation category confirmed. FR-OB-002 (student informed of override conditions).

**Edge Cases:** No counselor is available when a signal fires. Resolution: signal remains open in the queue; 24/7 crisis hotline details are surfaced to the student; BAHA after-hours owner is notified.

---

### FR-ES-002 — Acute Safety Disclosure Pathway

**Description:** When a student discloses or indicates suicidal ideation, self-harm, abuse, POCSO-covered concerns, or immediate danger (via check-in, chatbot, or help request), the platform activates the acute safety disclosure protocol. This protocol is always human-in-the-loop; no automated-only handling.

**Priority:** P0

**Acceptance Criteria:**
- Acute safety disclosure triggers: (1) surfacing of 24/7 crisis hotline to student; (2) creation of a priority case in BAHA support queue with named owner notified immediately; (3) surfacing of emergency contacts (student-configured).
- Student is informed supportively that help is being arranged; they are not left without a response.
- Protocol does not block the student from using the rest of the app.
- All acute disclosures are retained in the counselor case management system regardless of student profile deletion requests.
- Protocol documentation is reviewed and approved by BAHA before any pilot activation.

**Dependencies:** Named safeguarding owner per escalation category confirmed. 24/7 crisis hotline number confirmed. FR-CB-004 (chatbot escalation). BAHA approval of exact protocol wording.

**Edge Cases:** Student triggers the safety protocol multiple times in the same day. Resolution: each instance is logged; counselor receives aggregated notification, not duplicate alerts.

---

### FR-ES-003 — Consent Override Notification

**Description:** When a privacy override is triggered (acute safety disclosure), the student is informed — in age-appropriate plain language — that a trusted adult or counselor is being involved, which information is being shared, and why. This notification happens in real time, not after the fact.

**Priority:** P0

**Acceptance Criteria:**
- Consent override notification is shown to the student immediately when the override is triggered.
- Notification explains: what is being shared, with whom, and why.
- Notification uses BAHA-reviewed plain language appropriate to the student's age band.
- Notification is logged and timestamped.

**Dependencies:** FR-ES-002. BAHA-approved wording.

---

### FR-ES-004 — Support Queue and Case Management

**Description:** The BAHA/counselor app includes a structured support queue where all escalation signals, pastoral flags, help requests, and acute safety disclosures are tracked. Counselors can review, assign, action, and close cases. Each case retains a log of events and actions taken.

**Priority:** P0

**Acceptance Criteria:**
- Support queue shows all open cases, sorted by priority (acute safety > monitoring signal > pastoral flag > help request).
- Cases include: student ID (anonymised by default), signal source, timestamp, signal type, and action log.
- Counselors can assign cases, add notes, mark actions taken, and close cases.
- Closed cases are retained for the retention period defined in the data policy.
- BAHA admins can view aggregate case statistics without accessing individual case details.

**Dependencies:** BAHA/counselor app. FR-ES-001, FR-ES-002. Named safeguarding owner per category.

---

## 8.9 Physical Activity and Lifestyle Support

---

### FR-PA-001 — Physical Activity Contact Referral

**Description:** Students can optionally connect with physical activity coaches or community sports groups through an in-app directory. Referrals are opt-in and facilitated by BAHA/NGO-vetted contacts.

**Priority:** P2

**Acceptance Criteria:**
- Directory lists BAHA/NGO-vetted physical activity contacts by city/region.
- Student can express interest and receive a follow-up connection (not an automatic enrollment).
- No third-party data about the student is shared without explicit consent.

**Dependencies:** BAHA/NGO vetting of directory contacts. Launch-readiness review for referral operations.

---

# 9. Non-Functional Requirements

---

### NFR-001 — Privacy by Default

**Description:** All student check-in data, chatbot conversation data, and profile data are private by default. No data is shared with parents, teachers, or third parties without explicit consent or an active safeguarding protocol.

**Priority:** P0

**Acceptance Criteria:**
- Raw check-in responses are never transmitted to parent or teacher views.
- No biometric, location, or behavioral data is collected passively.
- Data minimization is applied throughout: only the data required for the stated function is collected.
- All external data transmissions (if any) are logged and auditable.
- Privacy by default is verified in a security/privacy audit before any live pilot.

**Dependencies:** Legal and compliance review (DPDP Act 2023, DPDP Rules 2025, ICMR guidelines).

---

### NFR-002 — Consent Management

**Description:** The platform must support verifiable parental/guardian consent for minors, self-consent for users aged 18–19, adolescent assent where applicable, school permission, and role-specific data-sharing boundaries. Consent records are stored, auditable, and revocable.

**Priority:** P0

**Acceptance Criteria:**
- Parental or guardian consent is collected before any user's data is processed for users aged 9–17.
- Self-consent is collected before any user's data is processed for users aged 18–19.
- Consent records are timestamped, versioned, and retained for the required period.
- Consent withdrawal is processed within 24 hours.
- Consent covers: data collection, data sharing, chatbot interaction, game behavioral signals, and learning module participation.

---

### NFR-003 — Data Security

**Description:** All personally identifiable student data is stored encrypted at rest and in transit. Access is role-gated. Authentication is required for all platform users.

**Priority:** P0

**Acceptance Criteria:**
- All PII is encrypted at rest (AES-256 or equivalent).
- All data in transit uses TLS 1.2+.
- Role-based access control is enforced; no role can access data outside its defined scope.
- Authentication uses secure credential management; no plaintext password storage.
- Security review is completed before any live pilot.

---

### NFR-004 — Performance and Availability

**Description:** The Android app suite must be functional on mid-range Android devices and support offline access to the highest-frequency student features. The backend and shared services must sustain simultaneous usage across separate stakeholder apps.

**Priority:** P1

**Acceptance Criteria:**
- Student app loads within 3 seconds on a mid-range Android device on a 4G connection.
- Parent, Teacher, and BAHA/Counselor apps load within 4 seconds on supported Android devices under normal 4G or WiFi conditions.
- Core student features (check-in, calm breathing, offline-cached learning content) function without an internet connection.
- Escalation pathways and chatbot require connectivity; a clear offline-state message is shown when unavailable.
- Push notification delivery for reminders, summaries, and operational alerts is supported on Android.
- Platform availability target: 99% uptime during pilot hours.

---

### NFR-005 — Accessibility

**Description:** The platform must meet WCAG 2.1 AA accessibility standards. Content must be readable at the literacy level of the target age band.

**Priority:** P1

**Acceptance Criteria:**
- All UI elements have sufficient color contrast (WCAG AA).
- All interactive elements are accessible via screen reader.
- Audio content has transcripts.
- Visual content has alt-text.
- All student-facing text is reviewed for reading level appropriateness per age band.

---

### NFR-006 — Scalability

**Description:** The platform architecture must support scale from a 3-school pilot (~150 students) to a broader Bangalore rollout (~5,000 students) without architectural redesign.

**Priority:** P1

**Acceptance Criteria:**
- Backend is designed with stateless, horizontally scalable components.
- Database schema supports multi-school, multi-cohort data partitioning.
- No hard-coded pilot-specific limits.

---

### NFR-007 — Auditability

**Description:** All escalation events, consent changes, content updates, and data access events are logged with timestamps and actor identifiers. Logs are accessible to BAHA admins.

**Priority:** P1

**Acceptance Criteria:**
- Audit log covers: login events, escalation triggers and actions, consent changes, content publish/archive, data access by counselors.
- Logs are tamper-evident.
- Logs are retained for the minimum period required by applicable regulations.

---

### NFR-008 — Modularity

**Description:** Each major feature module (check-in, chatbot, games, learning platform, escalation, analytics, and consent services) should be independently deployable and testable. Each stakeholder app should be able to evolve without forcing a full-system rewrite.

**Priority:** P1

**Acceptance Criteria:**
- Initial Android launch operates without requiring future iOS-specific code paths or research-extension code paths.
- Each module has a clean interface contract.
- Disabling any non-core module does not degrade core check-in or safety pathway functionality.
- Shared backend contracts support separate Student, Parent, Teacher, and BAHA/Counselor apps without duplicating business logic across clients.

---

### NFR-009 — Clinical Boundary Enforcement

**Description:** The platform must not present any output to students as a clinical diagnosis, risk score, or medical recommendation. All clinical boundaries are enforced at the UI layer, the chatbot response layer, and the monitoring signal layer.

**Priority:** P0

**Acceptance Criteria:**
- No diagnosis labels, clinical risk scores, or medical recommendations appear in any student-facing view.
- Chatbot responses in clinical domains are strictly limited to BAHA-approved content.
- Monitoring signals are not described to students as risk assessments.
- UI copy is reviewed by BAHA for clinical boundary compliance before any pilot.

---

### NFR-010 — Cultural and Linguistic Appropriateness

**Description:** All student-facing content, chatbot responses, and game scenarios must be culturally appropriate for urban/peri-urban Indian adolescents in Bangalore and must avoid language that is stigmatizing, dismissive, or culturally incongruent.

**Priority:** P1

**Acceptance Criteria:**
- A BAHA-designated cultural review is performed on all student-facing content before pilot.
- Content does not use Western-default examples, references, or idioms without adaptation.
- At minimum one Indian language (Kannada or Hindi) is supported in Phase 2.

---

# 10. Data, Privacy, and Consent Requirements

## 10.1 Data Collected

| Data Type | Source | Privacy Tier | Retention | Notes |
|---|---|---|---|---|
| Check-in responses (mood, sleep, stress, etc.) | Student self-report | Tier 3 (most private) | Session + configurable; default 12 months | Never shared with parents by default |
| Aggregate weekly trend | Derived from check-ins | Tier 2 (summary) | Retained while account active | May be shared with parents per consent tier |
| Chatbot conversation | Student-chatbot interaction | Tier 3 | Retained for monitoring + escalation; reviewable by BAHA under protocol | Not shared with parents or teachers |
| Game behavioral signals | Game session | Tier 2 (aggregate) | Retained for profile building | Individual responses not shared externally |
| Learning progress | Module completion | Tier 1 (completion only) | Retained while account active | Completion (not quiz scores) shared with parents if consented |
| Pastoral flags | Teacher input | Internal (counselor only) | Case retention period | Not shared with parents or students |
| Escalation records | Escalation events | Internal (counselor + BAHA) | Minimum legal retention period | Retained even if student deletes profile |
| Parent/guardian consent records | Onboarding | Administrative | Minimum legal retention period | Auditable |

## 10.2 DPDP Act 2023 Compliance Checklist

- Child data provisions: special handling for users aged 9–17 confirmed.
- Verifiable parental consent: mechanism specified in FR-OB-002.
- Purpose limitation: data used only for stated wellness and safeguarding purposes.
- Data minimization: only minimum necessary data collected per function.
- Retention limits: configurable per data type; default defined above.
- Deletion rights: student/parent can request deletion per FR-OB-002.
- Behavioral monitoring restriction: no passive behavioral tracking in the initial launch.

## 10.3 ICMR Guidelines Compliance Checklist

- School/institutional permission required before any on-site data collection.
- Parental/guardian consent required for all minors.
- Child assent (age-appropriate) required alongside parental consent.
- Structured instruments; no identifiable high-risk disclosures without staffed safeguarding protocol.
- Institutional review recommended before data collection begins at pilot schools.

## 10.4 Consent Override Categories (BAHA Approval Required)

The following categories allow privacy to be overridden by the safeguarding protocol:
- Suicidal ideation or active self-harm disclosure.
- POCSO-covered disclosures (Protection of Children from Sexual Offences Act, India).
- Active substance use in a dangerous context.
- Sexual assault disclosure.
- Immediate danger to self or others.

These categories must be explicitly approved by BAHA, communicated to students in plain language during onboarding (FR-OB-002), and reviewed by legal counsel before any pilot activation.

---

# 11. Reporting and Analytics Requirements

---

### FR-AN-001 — Student Private Trend Analytics

**Description:** Students see their personal trend dashboard (FR-CI-003). Analytics are private, non-diagnostic, and expressed in plain language.

**Priority:** P0 — see FR-CI-003.

---

### FR-AN-002 — Parent Aggregate Summary

**Description:** Parent weekly summaries are auto-generated from consented data tiers. Summary generation is rule-based and does not use AI interpretation.

**Priority:** P1 — see FR-PT-001.

---

### FR-AN-003 — Teacher Class Trends Dashboard

**Description:** Teachers see anonymized class-level trends: average sleep consistency, mood trend direction, module completion rates, check-in participation rates. No individual student data is identifiable in this view except under the approved safeguarding protocol.

**Priority:** P1

**Acceptance Criteria:**
- Class trends are shown at the cohort level; minimum cohort size of 5 before individual anonymization risk is sufficient.
- Trend directions only (improving / stable / declining); no absolute values that could identify individuals.
- Teacher can filter by week and by wellness theme.
- Dashboard updates weekly (not real-time).

**Dependencies:** FR-CI-001. Privacy review.

---

### FR-AN-004 — BAHA Pilot Analytics Dashboard

**Description:** BAHA admins see pilot-level analytics: check-in participation rates, module completion rates, chatbot interaction volumes, escalation event counts (aggregated), game engagement rates, needs assessment outcomes, and content effectiveness indicators.

**Priority:** P1

**Acceptance Criteria:**
- All analytics are at aggregate level unless an individual case has been formally opened.
- Dashboard supports export for pilot report generation.
- Analytics are updated daily.
- No individual student data is visible in the aggregate analytics view.

**Dependencies:** FR-ES-004 (support queue data). FR-LM-004 (learning progress). FR-CI-001 (check-in data).

---

### FR-AN-005 — Intervention Effectiveness Tracking

**Description:** The platform tracks whether students who engaged with specific interventions (e.g., sleep reset challenge, calm breathing activity, a particular learning module) subsequently showed improved self-reported wellness trends. This is a research-use metric available to BAHA only, and is not shown to students.

**Priority:** P2

**Acceptance Criteria:**
- Intervention-outcome correlation data is available in the BAHA admin analytics view.
- Data is aggregate; no individual linkage is presented in the analytics view without opening a formal case.
- This metric is flagged as indicative and not clinical proof of efficacy.

**Dependencies:** BAHA ethics approval for research data use. FR-CI-001, FR-GM-001, FR-LM-001.

---

# 12. Assumptions and Dependencies

## 12.1 Assumptions

1. BAHA will assign a named clinical reviewer for content, thresholds, nudge wording, and crisis categories before the pilot.
2. A named safeguarding owner will be confirmed for each escalation category before any high-risk flow is activated.
3. At least 2–3 Bangalore schools will be accessible through the BAHA/NGO network for the needs assessment, testing, and Android pilot deployment.
4. BAHA's existing educational material will be made available to the team for content mapping, digitization, and app delivery.
5. The target deliverable is a functioning Android app suite backed by shared backend, content, consent, and safeguarding infrastructure.
6. School permission, parental consent, adolescent assent, and 18-plus self-consent processes will be clarified by BAHA/NGO before any live data collection begins.
7. All stakeholder decisions from the BAHA/NGO working sessions, including launch scope, consent route, deployment mode, and safeguarding ownership, are confirmed before development begins.

## 12.2 External Dependencies

| Dependency | Owner | Criticality | Notes |
|---|---|---|---|
| BAHA clinical reviewer assigned | BAHA | P0 | Blocks all content and threshold work |
| Named safeguarding owner per category | BAHA | P0 | Blocks all high-risk flow activation |
| Consent and assent route approved | BAHA / Legal | P0 | Blocks live pilot deployment |
| BAHA content access for learning module | BAHA | P1 | Blocks content map and learning module |
| School access through NGO/BAHA network | BAHA / NGO | P1 | Blocks needs assessment fieldwork and pilot deployment |
| DPDP Act legal review completed | Legal counsel | P1 | Required before any live data collection |
| ICMR ethics review (if classified as research) | Institutional review board | P1 | Required if pilot data used for research publications |
| Video platform selection (for live counselor sessions) | BAHA + tech team | P2 | Required before live video session activation |
| App-store policy review | Tech team | P2 | Required before any public Android or iOS app-store release |

---

# 13. Success Metrics

## 13.1 Initial Launch Success

The initial launch is successful if the team delivers all of the following:

1. Functioning Android Student App with onboarding, check-ins, trend dashboard, learning, games, BAHA Buddy, and help pathway.
2. Functioning Android Parent App with consent configuration, weekly summaries, conversation support, and parent learning content.
3. Functioning Android Teacher App with class trends, pastoral input, referral pathway, and teacher learning content.
4. Functioning Android BAHA/Counselor App with support queue, case management, escalation workflows, content review, and pilot analytics.
5. Shared backend, authentication, consent, content, chatbot, analytics, and audit infrastructure operational across all four apps.
6. Monitoring and escalation logic, privacy model, consent model, and safeguarding model reviewed by BAHA and integrated into the working system.
7. Needs assessment package, four-theme BAHA content map, and pilot plan for 2–3 schools with deployment owner, consent route, and escalation owner identified.

## 13.2 Pilot Success Metrics (Android Launch Pilot)

| Metric | Target | Notes |
|---|---|---|
| Privacy comprehension rate | ≥80% of student testers correctly describe what parents can see | Measured in app-based usability sessions |
| Willingness to use (weekly check-in) | ≥60% of surveyed students say they would complete a weekly check-in | Needs assessment survey |
| Content relevance rating | ≥70% of students rate module content as relevant to their age group | Needs assessment co-design feedback |
| Trust in privacy model | ≥70% of students rate the app as trustworthy for private check-ins | App-based usability sessions |
| Counselor workload acceptability | Counselors rate escalation workflow as manageable in pilot | Semi-structured interview during pilot |
| Parent usefulness rating | ≥65% of parents find weekly summaries useful for conversations | Parent usability feedback |
| Multi-app operational reliability | ≥95% of pilot-critical workflows complete without blocker defects across all four apps | Internal QA and pilot issue logs |

## 13.3 Platform Success Metrics (Post-Launch)

| Metric | Target | Notes |
|---|---|---|
| 4-week check-in retention | ≥40% of onboarded students complete 4 consecutive weekly check-ins | Engagement tracking |
| Game session time within limit | 100% of game sessions end at or before 30-minute cap | Compliance metric |
| Escalation false-positive rate | Reviewed weekly; target <20% of signals requiring no action | Counselor feedback loop |
| Learning module completion rate | ≥50% of enrolled students complete at least one full module in 4 weeks | Engagement tracking |
| Chatbot out-of-scope query rate | <15% of chatbot queries result in "cannot answer" responses | Signals gaps in the BAHA Q&A corpus |

---

# 14. Risk Register

| Risk | Severity | Likelihood | Mitigation |
|---|---|---|---|
| Adolescents do not trust the privacy model | High | Medium | Plain-language onboarding, usability-tested privacy screen, no raw parent/teacher access. |
| Unowned crisis alert (no named human responder) | High | Low (if process followed) | No high-risk flow activated without confirmed owner. 24/7 hotline required. |
| Chatbot provides unsafe or inaccurate response | High | Medium | Strict content corpus scoping; BAHA review of all Q&A pairs; no open-ended generation for sensitive topics. |
| Gamification increases net screen time | Medium | Medium | 30-minute game cap; advisory daily screen-time prompt; non-gamified engagement alternatives available. |
| BAHA content not in digitizable format | Medium | Medium | Content mapping begins early; gaps identified before launch content freeze. |
| Separate stakeholder apps multiply engineering complexity | High | Medium | Shared backend contracts, shared design tokens where appropriate, and clear app-boundary ownership reduce duplication. |
| Scope creep into AI prediction or passive sensing | High | Low (if managed) | Initial-launch boundary written into deliverables and sprint scope; extensions require separate ethics approval. |
| Daily check-in fatigue | High | High | Default to weekly cadence; daily is opt-in only. |
| Over-surveying minors in needs assessment | Medium | Low | Short anonymous instruments; age-appropriate language; no identifiable high-risk disclosure without staffed protocol. |
| School access delayed | Medium | Medium | Parallel preparation of survey instruments; BAHA/NGO introduction letters prepared in advance. |
| Data storage and residency compliance (DPDP) | High | Medium | Legal review completed before any live data collection; India-based data residency preferred. |
| Counselor capacity overwhelmed by monitoring signals | Medium | Medium | Conservative initial thresholds; weekly false-positive review; gradual threshold calibration. |
| Community/social feature creates moderation burden | Medium | Medium | Dedicated moderation workflow, review SLA, and BAHA activation sign-off required before live rollout. |
| Parent/counselor expects full surveillance access | Medium | Medium | Framed as conversation-support tool; aggregate-only parent view; onboarding for parents and teachers required. |

---

# 15. Incremental Build Plan

## Release 1 — Android Functional Launch Milestones

### Milestone 1 — Product Foundation and Research
- Finalize app boundaries across Student, Parent, Teacher, and BAHA/Counselor apps.
- Finalize age-segmentation and consent-routing model.
- Complete needs assessment instruments and fieldwork.
- Begin four-theme content map and data model definition.

### Milestone 2 — Shared Platform and Backend
- Implement authentication, role-based access control, consent records, notification model, and audit logging.
- Stand up shared APIs, operational database, and content services.
- Define shared analytics and escalation event schemas.

### Milestone 3 — Student App Core
- Deliver onboarding, privacy flow, check-ins, trend dashboard, help pathway, and age-banded UX logic.
- Deliver BAHA Buddy integration, Safe Questions flow, and core learning-module access.
- Deliver games, streaks, badges, and challenge tracking.

### Milestone 4 — Stakeholder App Core
- Deliver Parent App weekly summaries, privacy controls, and parent learning track.
- Deliver Teacher App class trends, pastoral input, and referral pathway.
- Deliver BAHA/Counselor App support queue, case management, content review, and analytics dashboard.

### Milestone 5 — Safety, Content, and Launch Hardening
- Finalize rule-based monitoring signals, escalation workflow, and consent override handling.
- Finalize four-theme content map, Q&A corpus structure, and learning-module role journeys.
- Complete integration testing across all four apps and shared services.
- Prepare Android pilot deployment package, consent templates, rollout plan, and operational handover.

---

# 16. Proposed Technology Stack

| Component | Recommended Option | Notes |
|---|---|---|
| Mobile apps | Flutter | Shared codebase for separate Android apps now; extend to iOS after Android stabilization. |
| Launch platform | Android | Internal or controlled pilot distribution before public store release. |
| Future platform | iOS | Delivered after Android pilot stabilization and parity planning. |
| App backend/API | FastAPI | Unified API layer for Student, Parent, Teacher, and BAHA/Counselor apps. |
| Operational database | PostgreSQL | Supports role-based application data, consent, case management, and auditability. |
| Knowledge/content backend | BAHA RAG platform | Powers Safe Questions, cited retrieval, content ingestion, and evidence-backed chatbot behavior. |
| Authentication and RBAC | Managed auth with custom role enforcement | Must support separate stakeholder identities, minors, guardians, and admin roles. |
| Storage | Cloud object storage plus database-backed metadata | Stores content assets, uploaded resources, reports, and supporting documents. |
| Notifications | Firebase Cloud Messaging | Android reminders, summaries, and operational alerts. |
| Chatbot engine | Retrieval-augmented model grounded on BAHA Q&A corpus | No open-ended LLM generation for sensitive topics in the initial launch. |
| Content management | Custom BAHA admin workflows in the BAHA/Counselor app plus backend services | Must support CRUD, lifecycle states, and review dates without developer involvement. |
| Analytics | Lightweight internal dashboard and event pipeline | No third-party analytics SDKs that process child data. |
| Video sessions | BAHA-vetted, India-compliant video platform | Required before live one-to-one video sessions are activated. |

---

# 17. References

- BAHA Adolescent Problem Statement — Internal document provided by BAHA / supervising faculty.
- BAHA Outreach Letter 2025 — Internal BAHA letterhead document addressed to schools.
- BAHA Wellness Companion App Suite Specification (June 2026) — Design specification covering Student, Parent, Teacher, Counsellor/BAHA, Chatbot, Games, and Learning Platform modules.
- Kadirvelu B. et al. Digital Phenotyping for Adolescent Mental Health. *JMIR*, 2026;28:e72501.
- Laiti J. / Wellby study. Evaluation of a cocreated mobile app and wearable for adolescent wellbeing. *JMIR Human Factors*, 2026; e79381.
- Digital Personal Data Protection Act, 2023. Ministry of Electronics and Information Technology, Government of India.
- Digital Personal Data Protection Rules, 2025. Ministry of Electronics and Information Technology, Government of India.
- ICMR National Ethical Guidelines for Biomedical and Health Research Involving Human Participants.
- Google Play Families Policies.
- Apple Screen Time / Family Controls API overview.
- HEADSS / SSHADESS Psychosocial Interview Frameworks.
- IAP Care App — Indian Academy of Pediatrics (reference for content structure and delivery model).
- MEPRS PRD v2.1 — Structural and formatting reference.

---

*Pre-stakeholder draft. This document does not constitute clinical, legal, ethics, or deployment approval. All thresholds, escalation categories, clinical language, and consent models require BAHA sign-off, legal review, and institutional ethics clearance before any live data collection or pilot activation.*
