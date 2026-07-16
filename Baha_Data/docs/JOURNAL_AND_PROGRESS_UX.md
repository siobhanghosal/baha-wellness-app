# Journal And Progress UX Notes

This note explains the current thinking behind two recent unified-app changes:

1. moving weekly scores and pattern visuals off the student home dashboard
2. adding a more complete journaling activity

## Why the home dashboard was simplified

For demo use, the first screen works better when it answers three fast questions:

- what should I do next?
- where do I go if I need help?
- how do I start quickly?

Because of that, the home screen now prioritizes:

- `Recommended next`
- `SOS Help`
- `BAHA Buddy`
- `Daily Check-in`

Detailed weekly score interpretation now lives in a separate `Your Week` screen instead of competing with the first-screen support actions.

## Why a separate `Your Week` screen exists

The old home dashboard tried to do too much at once:

- greeting
- weekly trend explanation
- factor cards
- chart interpretation
- recommendations

That created too much reading and made the first screen feel heavier than it needed to be.

The new `Your Week` screen is meant to be:

- optional
- clearer
- more quantitative
- easier to explain in a demo

It now focuses on:

- a single weekly line
- compact counts
- per-area scores
- short number-led takeaways

## Journal design direction

The journal feature was shaped by patterns that show up repeatedly in current journaling products and wellbeing-journaling literature.

### Product patterns reviewed

`Day One` highlights:

- multiple journals
- reminders
- search and filters
- favorites
- streaks
- templates
- privacy protections
- media-rich entry support

Source:

- https://dayoneapp.com/features/
- https://dayoneapp.com/privacy-pledge/

`Stoic` highlights:

- guided journals
- curated prompts
- habit-building reminders
- streaks and badges
- private-by-default positioning
- breathing and reflection tools in the same ecosystem

Source:

- https://www.getstoic.com/

### Research signals considered

`Jo: The Smart Journal` is useful because it frames journaling as more than static writing. It points toward:

- short text entry
- optional structure
- personalized feedback
- reminders that help create repeat use

Source:

- https://arxiv.org/abs/1907.07861

Privacy also matters more here than in a normal notes product, especially in mental-health-adjacent experiences.

Source:

- https://arxiv.org/abs/2605.02016

## What was realistic to implement now

The current prototype does not attempt to clone a full premium journaling app. Instead it implements the most useful subset for this product stage:

- free write mode
- guided reflection mode
- gratitude mode
- age-band prompt adaptation
- local private persistence
- search
- favorites
- reminder preference toggle
- streak count
- entry count

This is enough to make the feature feel real in a demo without pretending the app already has:

- rich media journaling
- cloud sync
- biometric locking inside the app
- notifications scheduling
- cross-device drafts

## Why the journal is local-first for now

For the current prototype, local persistence is the safer and faster choice because it:

- avoids creating a second sensitive data backend path right now
- keeps the feature responsive
- demonstrates the UX clearly
- reduces risk of accidental overexposure of private writing

If this becomes a production path later, the likely next steps would be:

- optional encrypted cloud sync
- passcode / biometric gate
- media attachment support
- structured journal insights with explicit consent

## Current product stance

The journal is intentionally presented as:

- a private reflection tool
- a gentle habit builder
- a support feature

It is not presented as:

- diagnosis
- therapy
- surveillance
- automated emotional scoring

That framing is important for both product trust and presentation clarity.
