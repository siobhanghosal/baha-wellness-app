# BAHA Daily Check-In Analytics Logic

## Purpose

This document explains the current implemented logic behind how BAHA:

- captures daily check-in answers
- turns answers into comparable factor scores
- builds trends across time
- decides when to raise a pattern, flag, or recommendation
- personalizes interpretation using onboarding context

This is a logic reference for product, demo, documentation, and future backend alignment.

Current implementation source of truth:

- [student_checkin_logic.dart](/Users/sudharshan/Desktop/PES/RF%20Internship/Baha_Mobile/apps/student_app/lib/src/wellbeing/student_checkin_logic.dart)
- [student_profile_logic.dart](/Users/sudharshan/Desktop/PES/RF%20Internship/Baha_Mobile/apps/student_app/lib/src/wellbeing/student_profile_logic.dart)
- [student_ready_screen.dart](/Users/sudharshan/Desktop/PES/RF%20Internship/Baha_Mobile/apps/student_app/lib/src/ui/student_ready_screen.dart)

## 1. Core Design Rules

The current design follows five rules:

1. The daily check-in must stay short enough to use repeatedly.
2. The same core factors must be tracked every day so changes are comparable over time.
3. The app can personalize wording and interpretation, but not by using crude stereotypes.
4. The app can surface support-oriented conclusions, but not diagnoses.
5. A conclusion must be tied to observed patterns, not to a single dramatic-looking answer alone unless it is only a same-day takeaway.

## 2. What The Daily Check-In Measures

Each daily check-in is organized around six stable factors:

1. `sleep`
2. `energy`
3. `mood`
4. `stress`
5. `physical_wellbeing`
6. `connectedness`

User-facing wording:

- `physical_wellbeing` is presented as physical symptoms or body discomfort
- `connectedness` is presented as support, belonging, or feeling understood

These six factors are the base analytics frame used throughout the student dashboard.

## 3. How A Single Answer Becomes A Score

Each core daily question uses a burden scale from `0` to `4`.

Meaning of the raw score:

- `0` = low burden / healthy signal
- `1` = mild strain
- `2` = mixed / moderate strain
- `3` = high strain
- `4` = very high strain

Important distinction:

- raw analytical scores use `higher = worse`
- the graphs shown to the student invert that for readability, so visually `higher = better`

Graph display conversion:

- displayed chart value = `4 - raw_score`

This inversion is only for display. The inference engine still evaluates the original burden score.

## 4. Which Answers Count Toward Trends

Not every answer in a check-in contributes to the trend analytics.

The trend builder only uses answers that are:

- mapped to one of the six tracked factors
- marked as a core answer
- carrying a numeric normalized score

This means:

- the six main daily factor questions drive trend analytics
- follow-up questions provide context and interpretation, but do not become separate trend lines

## 5. Follow-Up Question Logic

Follow-up questions appear only when their trigger conditions are met.

Current follow-up questions:

- `sleep_reason`
- `hardest_today`
- `energy_reason`
- `body_reason`
- `support_today`

They are triggered by:

- earlier selected answers in the same check-in
- template metadata such as `show_when` and `show_when_any`
- onboarding profile requirements such as age band or periods relevance

Follow-ups improve explanation, but they do not replace the core factor scores.

## 6. Age Personalization Logic

The app changes wording by age band, but not the meaning of the factor.

Current age bands:

- `9_12`
- `13_14`
- `15_18`
- `18_plus`

Examples:

- younger users see simpler prompts
- older users see more nuanced prompts like stress, pressure, or worry

What does not change:

- factor definition
- score scale
- trend structure

That keeps the system easier to understand while preserving comparability across time.

## 7. One-Time Onboarding Context Used In Interpretation

The onboarding profile adds interpretation context to daily analytics.

It does not create diagnosis-like labels. It creates lightweight internal tags.

### 7.1 Profile Tags And Their Conditions

`sleep_vulnerable`

- set when `school_day_sleep_quality` is `poor` or `very_poor`

`energy_vulnerable`

- set when `usual_energy` is `poor` or `very_poor`

`stress_vulnerable`

- set when `weekly_stress_frequency` is:
  - `often`
  - `very_often`
  - `almost_every_day`

`school_pressure_driven`

- set when `main_pressure` is `school`

`friendship_pressure_driven`

- set when `main_pressure` is `friends`

`family_pressure_driven`

- set when `main_pressure` is `family`

`somatic_signal_prone`

- set when `main_physical_issue` is anything except `none`

`period_linked_physical_impact`

- set when:
  - `experiences_periods = yes`
  - and `period_impact` is `often` or `a_lot`

`low_help_seeking`

- set when `help_seeking_ease` is `hard` or `very_hard`

`social_isolation_risk`

- set when `social_connectedness` is:
  - `a_bit_isolated`
  - or `very_isolated`

`engagement_prefers_activity`

- set when `support_preference` is `activities_games`

`focus_<factor>`

- set when `checkin_focus` is not `no_preference`

Example:

- if `checkin_focus = sleep`, then the tag becomes `focus_sleep`

### 7.2 How These Tags Are Used

These tags affect:

- wording on the dashboard
- how some factor narratives are phrased
- whether physical-context patterns are taken more seriously
- which learn/activity recommendations are shown

These tags do not directly raise clinical severity.

## 8. How Trend Points Are Built

Each submitted check-in becomes one `WellbeingTrendPoint`.

Each trend point contains:

- submission date
- a map of factor scores for the six tracked factors

Example structure:

- date = one submitted day
- factor scores = sleep, energy, mood, stress, physical wellbeing, connectedness

The overall burden score for a day is:

- average of all factor scores available in that check-in

Formula:

- `overall_score = sum(factor_scores) / number_of_factor_scores`

Because the raw factor scores use `higher = worse`, a higher overall score means a worse day analytically.

## 9. Dashboard Factor Metrics

For the factor cards shown on the student dashboard:

- the latest point is used as the current state
- the previous point is used to infer direction

Each factor card shows:

- label
- normalized card value
- detail text

Card value conversion:

- `card_value = (4 - raw_factor_score) / 4`

This makes the dashboard card feel intuitive:

- higher card fill means better

### 9.1 Severity Labels Used In Metric Narratives

For a single factor:

- if raw score `>= 3`: severity = `elevated`
- else if raw score `>= 2`: severity = `mixed`
- else: severity = `steady`

### 9.2 Direction Labels Used In Metric Narratives

Compare latest factor score to previous factor score:

- if delta `>= 0.35`: direction = `rising`
- if delta `<= -0.35`: direction = `easing`
- otherwise: direction = `holding steady`

Special contextual phrasing:

- for `sleep`, if profile contains `sleep_vulnerable`, the app says it is being judged against the student’s usual sleep baseline
- for `stress`, if profile contains `school_pressure_driven`, the app says school pressure may be a main driver

## 10. Daily Headline Logic

The same-day dashboard headline uses the latest check-in only.

Process:

1. Find the factor with the highest raw burden score.
2. If highest score `>= 3`, show:
   - `X is the strongest strain signal today`
3. Else if the overall score for the day is `< 1.4`, show:
   - `Today looks fairly steady overall`
4. Otherwise show:
   - `X is worth keeping an eye on today`

This is a same-day summary, not a long-term flag.

## 11. Risk Flag Logic

Risk flags use only the most recent `5` trend points, or fewer if fewer exist.

These are support flags, not diagnoses.

### 11.1 Sleep Repetition Flag

Flag shown:

- `Sleep strain has repeated`

Condition:

- count of recent points where `sleep >= 3` is at least `2`

Formal rule:

- `count_at_or_above(last_5, sleep, 3) >= 2`

### 11.2 Stress Persistence Flag

Flag shown:

- `Stress has stayed elevated`

Condition is true if either rule passes:

1. average stress across recent points is at least `2.6`
2. at least `2` consecutive recent points have stress `>= 3`

Formal rule:

- `average(last_5, stress) >= 2.6`
- or `consecutive_at_or_above(last_5, stress, 3, 2)`

### 11.3 Repeated Mood Strain Flag

Flag shown:

- `Mood has been lower more than once`

Condition:

- average mood burden across recent points is at least `2.6`

Formal rule:

- `average(last_5, mood) >= 2.6`

### 11.4 Low Support Flag

Flag shown:

- `Support has felt low on recent days`

Condition:

- average connectedness burden across recent points is at least `2.6`

Formal rule:

- `average(last_5, connectedness) >= 2.6`

### 11.5 Physical Symptoms Repetition Flag

Flag shown:

- `Physical symptoms kept showing up`

This flag has an extra gate. It only appears if the student’s profile makes physical patterns more meaningful.

Conditions:

1. profile includes `somatic_signal_prone`
2. count of recent points where `physical_wellbeing >= 3` is at least `2`

Formal rule:

- profile has `somatic_signal_prone`
- and `count_at_or_above(last_5, physical_wellbeing, 3) >= 2`

## 12. Dashboard Narrative Callouts

The dashboard can surface up to four narrative callouts.

The labels are:

- What changed
- What improved
- What to watch
- Pattern worth noticing
- What to try next

Only the first four populated callouts are shown.

### 12.1 What Changed

Preferred source:

- derived trend logic

Fallback source:

- weekly summary text from backend

Derived logic:

1. compare the recent `3` points to the prior `3` points
2. calculate average overall burden in each window
3. look at the delta

Conclusions:

- if delta `<= -0.45`
  - `The last few check-ins look steadier than the days before them`
- if delta `>= 0.45`
  - `The last few check-ins show more strain than the days before them`
- otherwise
  - `Your recent check-ins look fairly steady overall, without a sharp swing either way`

### 12.2 What Improved

This compares:

- the earlier half of the most recent 6-point window
- against the latest 3-point window

Process:

1. take last up to `6` points
2. take first `3` of that window as the earlier group
3. take last `3` points overall as the later group
4. for each factor, compute:
   - `improvement = earlier_average - later_average`
5. choose the factor with the largest improvement

Condition to declare improvement:

- best improvement must be greater than `0.5`

If no factor improves by more than `0.5`, no improvement callout is shown.

### 12.3 What To Watch

This uses the most recent `4` points.

Process:

1. compute average burden for each factor across last `4` points
2. identify the factor with the highest average
3. compare it against the previous 4-point window if available

If highest factor average is `< 2`:

- show:
  - `No repeated high-strain pattern stands out right now`

Otherwise:

Severity bands:

- `>= 3.0` = `high`
- `>= 2.2` = `moderate`
- `< 2.2` but still watch-worthy = `mild`

Direction bands:

- delta vs previous window `>= 0.35` = `rising`
- delta `<= -0.35` = `easing`
- otherwise = `fairly steady`

Special phrasing rules:

- if highest factor is `sleep` and profile contains `sleep_vulnerable`, refer to the student’s usual baseline
- if highest factor is `stress` and profile contains `school_pressure_driven`, explicitly name school pressure as a likely driver

### 12.4 Pattern Worth Noticing

This looks for linked factor clusters across the most recent `4` points.

Rule 1: sleep-energy link

- if `average(sleep) >= 2.2`
- and `average(energy) >= 2.2`
- conclusion:
  - sleep and energy are moving together

Rule 2: stress-mood link

- if `average(stress) >= 2.2`
- and `average(mood) >= 2.2`
- conclusion:
  - stress and mood are moving together

Rule 3: support-mood link

- if `average(connectedness) >= 2.2`
- and `average(mood) >= 2.0`
- conclusion:
  - lower support is appearing alongside mood strain

Only the first satisfied rule is used.

### 12.5 What To Try Next

This is based on the highest average factor across the most recent `3` points.

Mapping:

- highest = `sleep`
  - recommend sleep protection and the Sleep learn lane
- highest = `energy`
  - recommend recovery before productivity
- highest = `mood`
  - recommend one familiar, low-pressure steadying step
- highest = `stress`
  - recommend a short reset, then one manageable next step
  - if profile is `school_pressure_driven`, explicitly suggest shrinking the next school task
- highest = `physical_wellbeing`
  - recommend slowing down and tracking whether rest, food, water, or support changes the pattern
- highest = `connectedness`
  - recommend contacting one trusted person

## 13. Immediate Post-Check-In Takeaways

After one check-in submission, the app can show up to three immediate takeaways.

These are same-day interpretations, not week-long conclusions.

### 13.1 Compared With Recent Days

This compares today’s score to the average of previous points for each factor, in this order:

1. stress
2. sleep
3. mood
4. energy
5. connectedness
6. physical_wellbeing

If any factor meets one of these conditions first:

- today - previous_average `>= 0.7`
  - show:
    - `Today shows more strain around X than your recent average`

- today - previous_average `<= -0.7`
  - show:
    - `X looks steadier than your recent average today`

Only the first factor in the ordered scan that meets the threshold is used.

### 13.2 Same-Day Linked Pattern

These rules use the current day only.

Rule 1:

- if `sleep >= 2` and `energy >= 2`
  - conclusion:
    - rest is likely to help tomorrow

Rule 2:

- else if `stress >= 2` and `mood >= 2`
  - conclusion:
    - a quick reset plus one manageable next step makes sense

Rule 3:

- else if `connectedness >= 2`
  - conclusion:
    - reaching one safe person may help more than pushing through alone

### 13.3 Best Next Step

This is driven by the factor with the highest burden score today.

If highest burden is `< 2`:

- show a steady-state message

Otherwise:

- `sleep`
  - recommend a sleep reset
- `energy`
  - recommend recovery before output
- `mood`
  - recommend one grounding activity
- `stress`
  - recommend a calming reset and one small next step
- `physical_wellbeing`
  - recommend noticing whether food, water, rest, or a break changes the pattern
- `connectedness`
  - recommend checking in with one trusted person

## 14. Learn Recommendation Logic

The learn recommendation engine now prioritizes themes using:

- recent factor averages
- latest factor state
- weekly summary language
- risk flags and trend labels
- onboarding tags like digital overload

For older students, the system now tries to prioritize:

1. `Sleep`
2. `Stress`
3. `Bullying`
4. `Healthy Gaming`
5. `Alcohol Safety`

Important correction:

- `Alcohol Safety` is no longer supposed to appear as a generic fallback when the student’s actual weekly pattern is sleep and school-pressure related

That theme should appear only when it is genuinely relevant or when all stronger fallbacks are exhausted.

## 15. Empty-State Rules

If there are no real check-ins yet:

- charts should not fake a pattern
- the system should show an explicit empty state
- the app may still show a placeholder weekly summary, but not fake chart lines

This is deliberate, because inferred analytics should only appear when enough real input exists.

## 16. What The Current System Does Not Do

The current logic does not:

- diagnose a disorder
- estimate clinical risk probability
- perform therapist-style interpretation
- replace school or human support judgment
- treat one difficult day as a confirmed trend

It is a pattern-detection and support-guidance layer only.

## 17. Summary Of Current Thresholds

### Core Score Scale

- `0` healthy / low burden
- `1` mild strain
- `2` moderate / mixed strain
- `3` high strain
- `4` very high strain

### Risk Flags

- repeated sleep strain:
  - `sleep >= 3` on at least `2` of the last `5`
- elevated stress:
  - average stress `>= 2.6`
  - or `2` consecutive entries with stress `>= 3`
- repeated mood strain:
  - average mood `>= 2.6`
- repeated low support:
  - average connectedness `>= 2.6`
- repeated physical symptoms:
  - profile has `somatic_signal_prone`
  - and physical wellbeing `>= 3` on at least `2` of last `5`

### Dashboard Narrative

- big overall change:
  - recent 3 vs prior 3 overall delta `>= 0.45` or `<= -0.45`
- meaningful improvement:
  - best factor improvement `> 0.5`
- linked patterns:
  - paired averages typically need to reach about `2.2`

### Same-Day Takeaways

- today vs recent difference:
  - `>= 0.7` worse than average
  - `<= -0.7` better than average

## 18. Practical Interpretation

The current BAHA daily-check-in analytics system is best understood as:

- a structured burden-tracking model
- shaped by six stable wellbeing factors
- lightly personalized by onboarding context
- used to generate support-oriented trends, flags, and next-step suggestions

It is intentionally conservative.

A conclusion is generally declared only when:

- strain repeats
- the average remains elevated
- or multiple related factors move together

That is the main guard against overreacting to isolated responses.
