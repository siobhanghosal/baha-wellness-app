# Edge Cases

## Role-Specific Edge Cases

- student selects incorrect age band intentionally
- parent consent never arrives
- student submits duplicate weekly check-ins
- student repeatedly selects same emotion in game scenarios
- student triggers escalation and closes the app
- student opts out of profile building but keeps chatbot access

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
