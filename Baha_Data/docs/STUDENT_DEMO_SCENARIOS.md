# Student Demo Scenarios

These demo student accounts are seeded to show different product stories through
the student dashboard, factor charts, and daily check-in history.

Use the unified app as follows:

- role: `Student`
- entry mode: `Sign in`
- sign-in ID: use the value listed below
- email: use the matching email below

## 1. Aarav Student

- sign-in ID: `supabase-student-demo`
- email: `student.demo@baha.local`
- story: academic stress and sleep strain that improves through the week
- what it demonstrates:
  - stress and sleep can trend down over time
  - energy and mood can recover with them
  - BAHA can show improvement, not just problems

## 2. Nisha Connection

- sign-in ID: `supabase-student-connection-demo`
- email: `connection.demo@baha.local`
- story: low connectedness and low mood across several days, followed by partial recovery
- what it demonstrates:
  - social isolation can show up as a repeated pattern
  - BAHA can separate connection-driven strain from sleep-driven strain
  - the dashboard can suggest a low-pressure next step instead of jumping to alarmist language

## 3. Sana Physical

- sign-in ID: `supabase-student-physical-demo`
- email: `physical.demo@baha.local`
- story: physical discomfort and low energy cluster together early in the week, then improve
- what it demonstrates:
  - body signals, sleep, and energy can move together
  - onboarding context can make physical patterns more interpretable
  - BAHA can show support-oriented pattern recognition without acting like a diagnosis tool

## 4. Kabir Steady

- sign-in ID: `supabase-student-steady-demo`
- email: `steady.demo@baha.local`
- story: stable, healthy week with no repeated high-strain pattern
- what it demonstrates:
  - BAHA is not only for crisis or decline
  - the app can reinforce consistency and healthy routines
  - a positive dashboard view is still meaningful and part of the product story

## Recommended Demo Order

1. `Aarav Student`
2. `Nisha Connection`
3. `Sana Physical`
4. `Kabir Steady`

This order tells the clearest non-technical story:

- early strain
- social strain
- physical-context strain
- stable wellbeing

## Notes

- These accounts are backed by seeded check-in response history plus weekly
  summary payloads.
- The charts are driven by real stored check-in records, not dummy graph lines.
- The top-level weekly story on the dashboard comes from the seeded summary
  payload and is meant to make the demo easier to explain to non-technical
  audiences.
