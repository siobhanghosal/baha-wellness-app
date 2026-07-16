# Student Check-In And Profile Logic

This document describes the current student onboarding baseline and adaptive daily check-in logic now implemented in the BAHA mobile app.

## 1. Product Position

The student wellbeing flow is designed to be:

- short enough to use daily
- personalized without feeling invasive
- support-oriented, not diagnostic
- comparable over time across repeated check-ins

The core rule is:

- long-form context belongs in onboarding
- short-form state belongs in the daily check-in

## 2. Brutally Honest Critique Of The Older Logic

The previous version had three real problems:

1. It asked too many low-value onboarding questions.
2. It mixed meaningful assessment context with preference-style questions that did not strongly improve interpretation.
3. It collected the baseline profile too close to the daily check-in flow, which made the product feel heavier than it should.

The revised version fixes that by:

- moving the baseline into account creation
- trimming the question set down to what actually changes interpretation
- deriving lower-value app preferences instead of explicitly asking all of them

## 3. Current Implementation State

The current app now does this:

1. student chooses the app role before login
2. if registering, the student completes account basics plus one-time onboarding baseline
3. the onboarding baseline is attached to `POST /auth/bootstrap` as student metadata
4. `GET /mobile/me` returns that metadata back to the app
5. daily check-in is treated as a separate shorter flow

Important practical note:

- the app still keeps a local copy of the profile for resilience
- student baseline edits from settings also attempt to refresh backend metadata through `POST /auth/bootstrap`

## 4. One-Time Student Onboarding Baseline

All onboarding questions are multiple choice.

The current baseline intentionally asks only for factors that affect wording, interpretation, or follow-up relevance.

### 4.1 Questions Asked Directly

Identity and support:

- age band
- gender identity
- who the student usually goes to first when something feels off

Baseline wellbeing:

- normal school-week sleep quality
- normal day-to-day energy
- usual stress frequency
- main pressure source lately

Social and help context:

- usual support / connectedness with friends or classmates
- ease of asking for help

Physical context:

- whether the student experiences periods
- if yes, how much periods affect energy, pain, or mood

### 4.2 Things Now Derived Instead Of Asked Explicitly

The app now derives these fields instead of directly asking them:

- `main_physical_issue`
- `coping_style`
- `support_preference`
- `checkin_focus`

That keeps onboarding shorter while still preserving the downstream personalization hooks the app already uses.

### 4.3 Why Sex/Gender Is Not Used As A Crude Scoring Switch

Gender identity is not used to change severity scoring.

It is used only where it improves:

- tone and phrasing
- optional physical-context follow-up relevance
- respectful personalization

This is deliberate. The model should adapt to actual context, not stereotype.

## 5. Derived Internal Tags

The app converts onboarding answers into non-clinical internal tags.

Current tags include:

- `sleep_vulnerable`
- `energy_vulnerable`
- `stress_vulnerable`
- `school_pressure_driven`
- `friendship_pressure_driven`
- `family_pressure_driven`
- `somatic_signal_prone`
- `period_linked_physical_impact`
- `low_help_seeking`
- `social_isolation_risk`
- `focus_<factor>`

These do not label the child. They only steer interpretation and follow-up relevance.

## 6. Daily Check-In Structure

The current daily pulse is built around six stable factors:

1. sleep
2. energy
3. mood
4. stress
5. physical symptoms
6. support

This is the part that should remain broadly comparable over time.

These labels are intentionally more clinically meaningful than the older `body` and `connection` wording:

- `physical symptoms` captures headaches, stomach issues, pain, fatigue spillover, or other body-based discomfort
- `support` captures whether the student felt supported, included, or understood by people around them

### 6.1 Core Daily Questions

The current daily core asks one question for each factor:

- `sleep_last_night`
- `energy_today`
- `mood_today`
- `stress_today`
- `body_today`
- `connected_today`

Each answer maps to a burden score from `0` to `4`:

- `0` = low burden / healthy signal
- `4` = high burden / strain signal

### 6.2 Follow-Up Questions

Follow-ups are shown only when triggered.

Current follow-up set:

- `sleep_reason`
- `hardest_today`
- `energy_reason`
- `body_reason`
- `support_today`

Trigger logic is based on:

- earlier selected answers
- question metadata such as `show_when` and `show_when_any`
- onboarding context such as periods-related relevance

## 7. Age-Appropriate Personalization

The app now personalizes question wording by age band.

Examples:

- ages `9_12` see simple wording like "How are your feelings today?"
- ages `13_14` keep plain wording like "How stressed or worried do you feel today?"
- ages `15_18` and `18_plus` get more nuanced wording like "How much stress, pressure, or worry are you carrying today?"

The important constraint is:

- wording can adapt
- factor definitions stay stable

That preserves both usability and comparability.

## 8. Inference Model

The app derives trend points from real submitted check-in detail records by reading:

- `normalized_value.score`
- `normalized_value.dimension`
- `normalized_value.is_core`

### 8.1 What The App Infers

From repeated check-ins, the app can infer:

- sleep strain patterns
- stress persistence
- mood dips over multiple days
- lower-support trends across repeated entries
- physical symptom patterns when the onboarding context suggests they matter more
- linked patterns such as:
  - sleep plus energy
  - stress plus mood
  - support plus mood

### 8.2 Example Product Flags

Current demo-facing flags include:

- `Sleep strain has repeated`
- `Stress has stayed elevated`
- `Mood has been lower more than once`
- `Support has felt low on recent days`
- `Physical symptoms kept showing up`

These are support signals only.

They are not:

- diagnoses
- risk scores shown to students
- standalone intervention decisions

## 9. What The Graphs Should Mean

The student graphs should reflect the actual six tracked factors:

- sleep
- energy
- mood
- stress
- physical symptoms
- support

The graphs should not show placeholder categories that are not actually being collected.

Current UI behavior:

- if no real check-ins have been submitted yet, the student dashboard should stay in an explicit empty state
- trend cards and graphs should only appear once actual entries exist
- first-use weekly summary placeholders are acceptable, but fake chart lines are not
- the dashboard overview should explain that the `Overall pulse` graph is a combined strain pattern, not a clinical score
- recent dashboard review should stay trimmed to the latest few real check-ins instead of overwhelming the student

## 10. Backend Contract Used By This Logic

The current implementation relies on:

- `POST /auth/bootstrap`
- `GET /auth/onboarding-state`
- `GET /mobile/me`
- `GET /mobile/student/checkin-templates`
- `GET /mobile/student/checkin-templates/{template_id}`
- `POST /mobile/student/checkins`
- `GET /mobile/student/checkins`
- `GET /mobile/student/checkins/{response_set_id}`
- `GET /mobile/student/weekly-summary/latest`

## 11. Practical Product Recommendation

For this product, this is the right balance:

- keep onboarding concise but meaningful
- keep the daily pulse to six stable factors
- allow only a few targeted follow-ups
- keep the factor names product-friendly, but specific enough to mean something real
- let tone vary by age band while keeping factor scoring stable underneath
- keep all interpretation non-clinical
- intervene based on repeated patterns, not one isolated bad day

That is strong enough for a demo and disciplined enough not to drift into pseudo-diagnosis.
