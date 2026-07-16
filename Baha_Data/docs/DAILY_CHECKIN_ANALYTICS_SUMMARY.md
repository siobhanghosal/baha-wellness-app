# BAHA Daily Check-In Analytics Summary

## Overview

BAHA uses a short daily check-in to convert student self-reports into simple wellbeing analytics. The purpose is not to diagnose a condition. The purpose is to detect patterns early, explain them clearly, and recommend the next useful support step.

## What BAHA Measures

The daily check-in tracks six stable factors:

1. sleep
2. energy
3. mood
4. stress
5. physical wellbeing
6. connectedness

These factors stay constant so the app can compare one day with another.

## How Scoring Works

Each core answer becomes a burden score from `0` to `4`:

- `0` = healthy or low difficulty
- `1` = mild strain
- `2` = moderate strain
- `3` = high strain
- `4` = very high strain

Internally, higher scores mean more difficulty. On charts, the values are visually inverted so that higher-looking graphs feel positive to the user.

Only the six core factor questions drive trends and charts. Follow-up questions are used only to explain the result, not to create separate trend lines.

## How Personalization Works

BAHA uses one-time onboarding data as interpretation context. It looks at signals such as:

- usual sleep quality
- usual energy level
- whether stress is mostly linked to school, friends, or family
- whether asking for help feels difficult
- whether the student already feels isolated

These onboarding signals do not create alerts by themselves. They only improve interpretation and recommendation quality.

## How Trends And Insights Are Built

Each submitted check-in becomes one dated trend point. That point stores the six factor scores and an overall daily burden score, which is the average of the available factor scores for that day.

BAHA then compares:

- today against the recent average
- the latest few entries against the few before them
- one factor against another

This allows the dashboard to describe whether the student is improving, declining, or showing linked patterns such as poor sleep and low energy together.

## When BAHA Raises A Concern

BAHA is designed to react to patterns rather than isolated moments.

Current rules include:

- sleep concern:
  - at least `2` of the last `5` sleep scores are `3` or higher
- stress concern:
  - average stress across the last `5` entries is at least `2.6`
  - or stress is `3` or higher for `2` entries in a row
- mood concern:
  - average mood burden across the last `5` entries is at least `2.6`
- support concern:
  - average connectedness burden across the last `5` entries is at least `2.6`
- physical symptom concern:
  - only raised when onboarding already suggests physical symptoms matter for that student
  - and at least `2` of the last `5` physical wellbeing scores are `3` or higher

This makes the system more reliable for demos and more defensible as a support product.

## What The Dashboard Shows

The dashboard turns the data into five plain-language outputs:

- what changed
- what improved
- what to watch
- pattern worth noticing
- what to try next

So the dashboard does not just display data. It interprets recent movement and connects it to an action.

## How Recommendations Are Chosen

Recommendations are based on:

- the factor under the most recent strain
- short-term pattern direction
- onboarding context
- curated topic mapping

Example:

- if sleep is worsening, sleep-related support should be recommended first
- if stress is the dominant issue, stress support should take priority

## Why This Matters

For a demo or product presentation, this logic shows that BAHA is more than a journaling tool. It has a consistent measurement model, threshold-based pattern detection, and a clear pathway from user input to insight and recommendation.
