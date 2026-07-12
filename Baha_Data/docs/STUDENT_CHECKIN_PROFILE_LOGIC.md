# Student Check-In And Profile Logic

This document describes the current student wellbeing logic implemented in the mobile app and supported by the backend seed data.

## 1. Purpose

The student flow now uses:

- a `one-time wellbeing profile`
- a `short daily wellbeing pulse`
- `adaptive follow-up questions`
- `factor-specific trend views`

The design goal is:

- keep the daily check-in low-friction
- avoid a clinical-feeling questionnaire every day
- personalize follow-up questions only where that improves relevance
- infer trends from repeated patterns, not from one bad day

This is a product support layer, not a diagnostic tool.

## 2. Core Principle

The logic is intentionally split into two layers:

1. `Universal daily core`
2. `Personalized interpretation layer`

The daily core stays mostly the same for everyone so trend data remains comparable.

Personalization changes:

- which follow-up questions appear
- which answer choices are visible
- how trend text is described
- which risk flags matter more for a given student
- which support or learning paths should be suggested first

## 3. One-Time Wellbeing Profile

The app now asks a one-time student profile questionnaire before the adaptive daily check-in flow is used.

Current implementation state:

- stored locally on-device with `SharedPreferences`
- keyed by student development identity
- editable later from settings
- not yet written back into a dedicated backend profile-edit API
- can still be attached to bootstrap metadata later without changing the mobile logic

### 3.1 Profile questions

All profile questions are multiple choice.

Identity and support:

- age band
- gender identity
- who the student usually talks to when something feels wrong

Baseline wellbeing:

- usual school-day sleep quality
- usual energy
- stress frequency in a normal week
- main pressure source

Physical context:

- main recurring physical issue
- whether the student experiences periods
- if yes, how much periods affect energy, pain, or mood

Social and coping style:

- what the student does first when feeling low
- how easy it is to ask for help
- how connected the student usually feels

Support preferences:

- preferred support style
- preferred check-in focus area

### 3.2 Profile tags

The app derives internal profile tags from the onboarding answers.

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
- `engagement_prefers_activity`
- `focus_<factor>`

These tags do not label the student clinically. They only steer interpretation and follow-up behavior.

## 4. Daily Wellbeing Pulse

The backend now seeds an adaptive template:

- template key: `daily_student_pulse_v2_13_14`
- cadence: `daily`

### 4.1 Core daily questions

The current daily core tracks six factors:

1. sleep
2. energy
3. mood
4. stress
5. physical wellbeing
6. connectedness

Every core question is multiple choice with a 5-level answer set.

The stored score direction is consistent:

- `0` means low burden / healthy signal
- `4` means high burden / strain signal

### 4.2 Follow-up questions

Follow-ups only appear when triggered by earlier answers.

Current follow-ups:

- sleep reason
- hardest part of the day
- low-energy reason
- physical discomfort reason
- support preference for today

The app evaluates template metadata such as:

- `show_when`
- `show_when_any`
- option-level `profile_requirements`

Example:

- the `period-related` physical option only appears if the profile says the student experiences periods
- the sleep reason question appears only after poor sleep answers

## 5. Scoring Model

### 5.1 Raw storage

For each answer the app submits:

- `selected_options`
- `numeric_value`
- `normalized_value`

`normalized_value` currently includes:

- `question_key`
- `dimension`
- `choice_key`
- `label`
- `score`
- `is_core`

### 5.2 Burden interpretation

The app treats the six core factors as burden scores from `0` to `4`.

Interpretation:

- `0.0 - 0.9`: very steady
- `1.0 - 1.9`: mild strain
- `2.0 - 2.9`: moderate strain
- `3.0 - 4.0`: high strain

This is not shown as a diagnostic score to the user.

## 6. Trend Logic

Trend charts now use the actual tracked factors instead of placeholder mood/sleep-only visuals.

Current chart factors:

- sleep
- energy
- mood
- stress
- physical wellbeing
- connectedness

The app derives trend points from submitted check-in detail records by reading:

- `normalized_value.score`
- `normalized_value.dimension`
- `normalized_value.is_core`

If no real history exists yet, the app uses a small deterministic demo fallback so the UI remains presentable.

## 7. Risk Flags

Current demo-ready flag rules:

- repeated sleep strain
- repeated elevated stress
- repeated mood dip
- repeated low connectedness
- recurring physical discomfort when the profile already suggests somatic vulnerability

These are surfaced as lightweight product flags such as:

- `Sleep strain repeating`
- `Stress elevated across days`
- `Mood dip needs attention`

They are support signals, not crisis labels.

## 8. Why This Design Was Chosen

This implementation intentionally avoids:

- making the whole questionnaire clinically heavy every day
- changing severity scoring just because the student is male or female
- assuming all female students need the same physical follow-ups
- using sex or gender as a crude substitute for actual context

Instead it personalizes only where useful:

- periods-related physical interpretation
- support style preference
- help-seeking difficulty
- school-pressure vs friendship-pressure emphasis
- baseline sleep/stress vulnerability

## 9. Current Backend Support

The backend currently supports this through existing mobile contracts:

- `GET /mobile/student/checkin-templates`
- `GET /mobile/student/checkin-templates/{template_id}`
- `POST /mobile/student/checkins`
- `GET /mobile/student/checkins`
- `GET /mobile/student/checkins/{response_set_id}`
- `GET /mobile/student/weekly-summary/latest`

No new mobile API endpoint was required for this slice.

The adaptive behavior is driven by:

- richer seeded check-in template metadata
- normalized answer payloads
- locally stored wellbeing profile state in the app

## 10. Current Limitations

- the one-time wellbeing profile is currently local-only
- weekly deeper assessment logic is not yet upgraded to match the daily pulse quality
- trend summaries are still partially app-derived rather than fully generated server-side
- counselor escalation logic is still driven by product rules, not a dedicated safeguarding engine

## 11. Recommended Next Step

The next strong backend step for this area would be:

1. add a server-side student profile read/write model
2. persist profile tags centrally
3. generate trend snapshots and flag summaries on the backend
4. add a deeper weekly reflection/check-in aligned to the same factor model
