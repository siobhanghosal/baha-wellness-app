# BAHA Presentation Deck Refresh Guide

## Purpose

This document is the source-of-truth briefing for updating the current BAHA client presentation deck:

- current deck reviewed: `BAHA_Wellness_Companion_Client_Demo_Presentation-2.pptx`
- purpose of this document:
  - summarize the current prototype accurately
  - give presentation-safe language for product, analytics, privacy, and AI
  - explain the daily check-in framework and how it should be justified
  - identify exactly what must change in the current PPT

This document is intentionally stricter than the older deck.

Where the current prototype is strong, this guide says so clearly.
Where the old deck overclaims or reflects older product versions, this guide marks it for rewrite.

## 1. One-Line Product Positioning

**BAHA Wellness Companion is a privacy-first adolescent wellness platform that helps students check in on how they are doing, understand repeated patterns in their wellbeing, learn through age-appropriate health content, use supportive activities, and talk to a bounded AI companion, while giving parents only privacy-safe summaries instead of surveillance access.**

## 2. What The Current Prototype Actually Is

The current live prototype is:

- a functioning Android-first Flutter mobile app
- one unified app with role-based experiences inside it
- connected to a real backend and seeded demo data
- meaningfully implemented for:
  - student
  - parent / guardian
- only partially represented for:
  - teacher
  - counselor

Presentation-safe phrasing:

- one mobile platform
- separate role-specific experiences inside one app
- shared backend, analytics, content, and safety logic

Do not say:

- separate production-ready apps for all stakeholders
- fully deployed platform
- clinically validated diagnostic tool

## 3. Core Product Story

The strongest presentation story is:

1. adolescents need a private, trusted, engaging support layer
2. most current systems are reactive, adult-led, and not engaging
3. BAHA creates a structured, youth-friendly wellness layer
4. the platform is privacy-first, not surveillance-first
5. the system helps with:
   - self-awareness
   - early support
   - guided learning
   - healthier parent-child conversations
6. the AI companion is bounded and support-oriented, not diagnostic

## 4. Current Student Experience

The student journey currently supports:

1. role selection
2. sign in or register
3. one-time onboarding baseline
4. daily check-in
5. student home dashboard
6. separate weekly analytics view
7. learning section
8. activities section
9. BAHA Buddy
10. SOS / support flow

Important presentation clarification:

- the student home dashboard is intentionally simpler now
- the deeper analytics no longer sit directly on the main home page
- the deeper trend view is a separate screen: `Your Week`

### Student Home

The home screen now emphasizes:

- recommended next step
- quick support actions
- daily check-in
- Buddy
- SOS help

This is cleaner and more demo-friendly than a data-heavy dashboard landing screen.

### Student Analytics

The student analytics view now supports:

- multiple time windows:
  - `7D`
  - `14D`
  - `30D`
  - `All`
- factor-specific views:
  - sleep
  - energy
  - mood
  - stress
  - physical symptoms
  - support
- evidence-led narrative insights instead of only numeric cards

This is important in the presentation because it shows:

- the app does not just collect data
- the app interprets repeated patterns
- the app avoids diagnosis language

### Student Learning

The student learning side is organized around five core topics:

- Sleep
- Stress
- Bullying
- Healthy Gaming
- Alcohol Safety

The strongest current learning implementation is the student learning lane structure, especially the age-banded flow already visible in the app.

The learning system is presented as:

- short guided modules
- progress-aware lanes
- age-appropriate phrasing
- small practical actions

This should be pitched as guided micro-learning, not document browsing.

### Student Activities

Current student activities include:

- Calm Breathing
- Focus Catch
- Comet Sequence
- Journal

The journal now supports:

- free write
- guided reflection
- gratitude note
- saved entries
- favorites
- streaks

### Student Buddy

The student can open BAHA Buddy as a chat companion.

Current presentation-safe description:

- safe conversational support
- grounded in approved BAHA material when relevant
- age-adapted reply style
- supportive but bounded

Do not describe it as:

- therapy
- diagnosis
- crisis management AI

## 5. Current Parent / Guardian Experience

The parent flow currently supports:

1. parent sign in or registration
2. secure linking through:
   - student ID
   - short-lived six-digit verification code
3. platform approval for under-18 students
4. summary-sharing approval flow
5. linked-children management
6. privacy-safe child summary views
7. parent learning
8. parent Buddy
9. parent SOS / support screen

### Parent Home

The parent home is now support-first.

The parent lands on:

- Parent Buddy
- SOS Help
- Linked children
- link child account flow

This is more accurate than older PPT language that implied the parent home was mostly a summary dashboard.

### Parent Summary Boundary

Parents do not see:

- raw student check-in answers
- private journal entries
- message-level chat history
- real-time surveillance data

Parents do see:

- high-level trends
- repeated signal summaries
- support nudges
- conversation guidance

This is one of the strongest parts of the product story.

## 6. Daily Check-In Framework

## What The Daily Check-In Is

The current daily check-in is a short, custom BAHA micro-check-in.

It is designed to:

- stay short enough for repeated use
- capture stable wellbeing factors over time
- personalize wording and interpretation by age and onboarding context
- support pattern detection and recommendations
- avoid acting like a diagnosis instrument

## What It Measures

The current check-in tracks six stable factors:

1. sleep
2. energy
3. mood
4. stress
5. physical symptoms
6. support

Important presentation note:

- older wording such as `physical state`, `body`, or `connectedness` should be updated
- the student-facing meaning now aligns more clearly with:
  - physical symptoms
  - support

## Scoring Model

Each core answer is converted into a burden score from `0` to `4`:

- `0` = low burden
- `1` = mild strain
- `2` = moderate strain
- `3` = high strain
- `4` = very high strain

Important clarification:

- internally, higher scores mean more strain
- in charts, values are visually inverted so that higher-looking graphs feel positive to the user

## Follow-Up Logic

The check-in is not a long static questionnaire.

It uses:

- 6 core factor questions
- a few follow-up questions only when triggered

Current follow-up logic is based on:

- selected answers in the same session
- age band
- onboarding context
- specific relevance, including optional periods-related relevance

This is important because it shows the product is trying to reduce friction rather than ask long fixed forms every day.

## Onboarding Personalization

The one-time onboarding baseline improves interpretation of later check-ins.

It captures context such as:

- usual sleep quality
- usual energy
- usual stress frequency
- main stress source
- help-seeking comfort
- social baseline
- physical-context relevance where appropriate

This data is used to:

- personalize wording
- personalize recommendations
- make pattern interpretation more useful

It is not used to label the user clinically.

## Pattern Detection Logic

The app does not react to one answer alone unless it is giving a same-day takeaway.

Longer pattern logic is based on:

- repeated strain
- elevated averages
- consecutive elevated values
- linked factor movement

Current examples:

- repeated sleep strain
- elevated stress pattern
- repeated low-support pattern
- physical-symptom repetition when onboarding context makes it relevant
- linked patterns such as:
  - sleep + energy
  - stress + mood
  - support + mood

## Recommendations

Recommendations are driven by:

- dominant strain factor
- time-window trend direction
- linked factor patterns
- onboarding context
- curated topic mapping to learn lanes and support activities

Example:

- if sleep is showing the strongest repeated strain, the app should point first toward sleep-oriented support rather than an unrelated content lane

## 7. How To Justify The Questionnaire Framework

## The Honest Answer

The current BAHA daily check-in is **not** a direct PROMIS questionnaire and should **not** be described that way.

The defensible statement is:

**The BAHA daily check-in is a custom, product-oriented wellbeing pulse that is informed by patient-reported outcome principles and by domain structures similar to PROMIS, but it is not a direct PROMIS short form, CAT, or scored clinical PROMIS instrument.**

## Why PROMIS Is Still A Useful Reference

PROMIS is a useful justification reference at the domain level because official HealthMeasures material presents PROMIS as a person-centered patient-reported outcome system organized around:

- physical health
- mental health
- social health

Official HealthMeasures materials also list pediatric / parent-proxy domains relevant to BAHA’s structure, including:

- sleep disturbance
- sleep-related impairment
- psychological stress experiences
- fatigue
- peer relationships
- family relationships

That domain logic aligns well with BAHA’s six-factor frame:

- sleep
- energy
- mood
- stress
- physical symptoms
- support

## Why BAHA Is Not Claiming PROMIS Validation

BAHA simplifies and adapts the framework for a high-frequency mobile product.

The current check-in differs from PROMIS because it:

- uses a much shorter custom question set
- includes product-specific follow-up logic
- uses onboarding-driven personalization
- maps directly into learning and support recommendations
- is built for repeated in-app engagement rather than formal standardized score reporting

So for the presentation:

- say the framework is informed by patient-reported outcome logic and PROMIS-like domain thinking
- do not say the current app administers PROMIS directly
- do not say the current questionnaire is psychometrically validated in the same way as PROMIS

## Recommended Presentation Wording

Use:

- informed by patient-reported outcome design principles
- aligned with clinically meaningful physical, emotional, and social wellbeing domains
- custom BAHA daily pulse designed for repeated adolescent use

Avoid:

- this is a PROMIS test
- this is a validated clinical screening instrument
- this produces clinical diagnosis scores

## 8. AI / BAHA Buddy Positioning

BAHA Buddy should be presented as:

- a bounded support companion
- a safe conversational entry point
- a way to surface approved guidance and useful next steps

Current technical truth:

- final response generation is OpenAI-backed
- retrieval and grounding logic sits on the backend side
- responses stream into the mobile UI progressively
- reply style is adapted by age band

Presentation-safe phrasing:

- safe AI companion
- support-oriented conversational guide
- grounded wellbeing assistant

## 9. What The Deck Must Not Overclaim

Do not claim:

- teacher and counselor role experiences are fully demo-ready
- all stakeholder experiences are equally complete
- the system provides medical diagnosis
- the chatbot provides therapy
- the app performs clinical risk prediction
- the product is already production deployed
- the questionnaire is a validated PROMIS administration

Safer replacements:

- working Android-first prototype
- backend-connected mobile demo
- student and parent prototype journeys implemented
- teacher and counselor architecture planned, not fully demoed
- pattern detection and support guidance, not diagnosis

## 10. Slide-By-Slide PPT Change Instructions

These instructions are written against the extracted slide structure of the current PPT.

## Slide 1 — Title

Current slide is broadly fine.

Recommended change:

- keep the title
- keep BAHA as the clinical partner
- if space is needed, shorten the subtitle to:
  - `Privacy-first adolescent wellness platform`

Reason:

- cleaner and more presentation-grade

## Slide 2 — One Platform, Multiple Experiences

Keep the overall structure.

Required changes:

- keep `Student` and `Parent`
- keep `Teacher` and `Counselor` clearly marked as `Future`
- keep the `one app / multiple experiences` message
- if possible, change `Personalized for Every User` to:
  - `One unified app with role-based experiences`

Reason:

- this reflects the current architecture exactly

## Slide 3 — Student Journey

Mostly keep.

Recommended update:

- consider renaming `Dashboard` to:
  - `Home + Analytics`

Reason:

- the current prototype separates the simple home screen from the deeper weekly analytics view

## Slide 4 — Daily Wellbeing Check-In

Keep the section, but rewrite the wording.

Required changes:

- `Designed to take less than a minute`:
  - change to `Designed to stay short, usually around 1–2 minutes`
- `Core Metrics`:
  - update the language to the current six-factor model
- `real-time picture`:
  - replace with `longitudinal picture built from repeated check-ins`

Suggested replacement content:

- short daily pulse
- six stable factors
- optional follow-up questions only when needed
- personalized by age and onboarding context

Reason:

- more accurate and less likely to be challenged

## Slide 5 — Daily Check-In Analytics Framework

Keep this slide, but update it carefully.

Required changes:

- `Physical State` should become `Physical Symptoms`
- `Connectedness` should become `Support`
- add a small note that:
  - follow-ups add context but do not create separate trend lines
- add a note that:
  - onboarding context personalizes interpretation
- add a note that:
  - this is a custom BAHA pulse, not a direct PROMIS measure

Reason:

- this slide is central to defending the analytics framework

## Slide 6 — Trend Detection & Recommendation Engine

Keep the structure, but rewrite parts of the language.

Required changes:

- avoid the phrase `clinical data`
- change to:
  - `student-reported wellbeing inputs`
- change `5 basic daily metrics` to:
  - `five narrative insight outputs`

Suggested outputs:

- what changed
- what improved
- what to watch
- pattern worth noticing
- what to try next

Reason:

- the current prototype is narrative and evidence-led, not a clinical scoring dashboard

## Slide 7 — Student Dashboard

This slide needs a meaningful rewrite.

Current issue:

- it implies the home dashboard itself is the main analytics surface

Updated framing:

- the student home is now simpler and action-oriented
- deeper pattern analysis lives in a separate analytics screen

Suggested bullets:

- home screen starts with recommended next step
- quick support actions are visible immediately
- deeper analytics live in a separate weekly view
- analytics use multiple time windows and factor-specific evidence

Reason:

- aligns with the actual product flow

## Slide 8 — Age-Based Learning

This slide needs clear updates.

Current issues:

- the placeholder says `Dashboard Demo Video`
- the age bands are outdated

Required changes:

- fix the demo placeholder title to learning, not dashboard
- update age bands to:
  - `9–12`
  - `13–14`
  - `15–18`
  - `18+`
- if space is limited, present `15–18 / 18+` together
- mention the five current topic families:
  - Sleep
  - Stress
  - Bullying
  - Healthy Gaming
  - Alcohol Safety

Reason:

- this slide currently reflects an older grouping model

## Slide 9 — Interactive Wellness Activities

Keep the idea, but refresh the examples.

Required changes:

- keep:
  - Calm Breathing
  - Focus Catch
  - Comet Sequence
- add:
  - Journal
- remove any implication that story-world is a current core demo feature

Optional wording change:

- `Wellness Activities` is good and should stay

Reason:

- journal is now a meaningful demo-worthy activity

## Slide 10 — BAHA Buddy

Keep the structure.

Required changes:

- keep the boundary slide
- keep the `not diagnosis / not therapy / not emergency decision making` message
- if adding one technical line, say:
  - `responses are generated through a bounded backend AI layer with grounding and safety logic`

Reason:

- preserves the strongest defensible framing

## Slide 11 — Parent Experience

Update the parent flow.

Current issue:

- the flow is slightly too summary-centric and older-version oriented

Updated parent flow:

1. Parent registration / login
2. Secure linking
3. Consent / approval
4. Parent home
5. Open child summary
6. Parent learning
7. Parent Buddy

Also add:

- parent SOS / support option

Reason:

- this matches the current support-first parent home much better

## Slide 12 — Privacy-First Design

Keep this slide.

Recommended edits:

- replace `clinical wellness` language with simpler `wellbeing patterns`
- explicitly mention:
  - no raw check-ins
  - no raw journal access
  - no message-level Buddy access

Reason:

- this is one of the product’s strongest trust differentiators

## Slide 13 — Demo Scenarios

This slide should be updated substantially.

Recommended change:

- move away from generic scenario names
- use the real demo flows and seeded personas

Suggested scenarios:

1. Student onboarding and first check-in
2. Student analytics with `Maya Analytics`
3. Student Buddy conversation
4. Parent linking and privacy-safe child summary

Optional extra:

- add a small note that seeded accounts represent different pattern stories, not just one sample user

Reason:

- this is much stronger than generic demo placeholders

## Slide 14 — Why It Is Different

This slide is broadly good.

Recommended change:

- keep the six pillars
- if editing labels, prefer:
  - Privacy First
  - Early Awareness
  - Age-Appropriate Design
  - Guided Learning
  - Bounded AI Support
  - Family Support Without Surveillance

Reason:

- slightly sharper and more aligned with the current prototype

## Slide 15 — Current Status

This slide needs tightening.

Recommended structure:

- Student journey: implemented
- Parent journey: implemented
- Teacher role: planned / future
- Counselor role: planned / future
- Backend-connected Android prototype: working

Reason:

- the current slide is close, but it should explicitly separate implemented from future

## Slide 16 — Roadmap

This slide needs the biggest rewrite.

Current issues:

- old topic counts may not be defensible live
- roadmap language reflects older assumptions

Recommended replacement:

### Near-Term Prototype Completion

- polish remaining student learning lanes
- deepen parent learning content
- improve Buddy grounding quality
- strengthen demo flows and hosted deployment readiness

### Next Role Expansions

- teacher role workflows
- counselor workflows
- referral and support queue maturity

### Product Hardening

- production authentication
- hosted backend deployment
- richer multimedia learning
- stronger progress and assessment systems

Reason:

- qualitative roadmap is safer than unsupported numeric counts

## Slide 17 — Thank You

Keep.

Only optional change:

- remove `portrait image placeholder` if it is still visibly a placeholder

## 11. Add / Remove Recommendations

## Add

If the team is open to one additional slide, the best addition is:

- `What Is Implemented Today vs What Is Future Scope`

Reason:

- it prevents overclaiming
- it gives you an honest, confident close

## Remove

If slides must be cut, remove or merge:

- duplicate video placeholder content
- any roadmap numbers that are not defensible live

## 12. Recommended Presentation Structure

If the team decides to rebuild rather than lightly edit, this is the best order:

1. Problem
2. Solution
3. One platform, multiple role-based experiences
4. Student journey
5. Daily check-in framework
6. Trend detection and recommendations
7. Student home + analytics
8. Learning + activities
9. BAHA Buddy
10. Parent journey + privacy boundary
11. What is implemented today
12. Roadmap

## 13. Recommended Wording For The Questionnaire Justification

Use this if someone asks how the questionnaire was derived:

**The BAHA daily check-in is a custom adolescent wellbeing pulse designed for repeated mobile use. It is informed by patient-reported outcome design principles and by domain structures similar to PROMIS, especially the use of physical, emotional, and social health domains. However, it is not a direct PROMIS short form or CAT. We simplified the structure for high-frequency use, kept six stable factors for comparability over time, and added age-based wording plus onboarding context so the output is useful without pretending to be diagnostic.**

## 14. Recommended Reference Links

Current internal source-of-truth documents:

- [PRESENTATION_PITCH_BRIEF.md](/Users/sudharshan/Desktop/PES/RF%20Internship/Baha_Data/docs/PRESENTATION_PITCH_BRIEF.md)
- [STUDENT_CHECKIN_PROFILE_LOGIC.md](/Users/sudharshan/Desktop/PES/RF%20Internship/Baha_Data/docs/STUDENT_CHECKIN_PROFILE_LOGIC.md)
- [DAILY_CHECKIN_ANALYTICS_LOGIC.md](/Users/sudharshan/Desktop/PES/RF%20Internship/Baha_Data/docs/DAILY_CHECKIN_ANALYTICS_LOGIC.md)
- [ACCOUNT_ONBOARDING_SYSTEM.md](/Users/sudharshan/Desktop/PES/RF%20Internship/Baha_Data/docs/ACCOUNT_ONBOARDING_SYSTEM.md)
- [STUDENT_DEMO_SCENARIOS.md](/Users/sudharshan/Desktop/PES/RF%20Internship/Baha_Data/docs/STUDENT_DEMO_SCENARIOS.md)

Official PROMIS / HealthMeasures reference material used for framing:

- Intro to PROMIS: https://www.healthmeasures.net/112-measurement-systems/promis/intro-to-promis
- Intro to Person-Centered Assessment: https://www.healthmeasures.net/resource-center/measurement-science/intro-to-person-centered-assessment
- PROMIS reference populations and pediatric / parent-proxy domains: https://www.healthmeasures.net/score-and-interpret/interpret-scores/promis/reference-populations
- PROMIS Pediatric Psychological Stress Experiences example measure: https://www.healthmeasures.net/index.php?Itemid=992&id=2320&option=com_instruments&view=measure

## 15. Final Presentation Guidance

The best version of this deck should leave the audience with four impressions:

1. this solves a real adolescent support gap
2. it is privacy-first and trust-aware
3. it is more than a chatbot
4. it is already a functioning prototype, not just an idea

That is the strongest honest position for the current BAHA prototype.
