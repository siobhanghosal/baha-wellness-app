# Edge Cases

## Role-Specific Edge Cases

- class size below anonymization minimum
- teacher submits duplicate pastoral flags
- teacher attempts to open student raw trend data
- teacher uses free text containing sensitive allegations
- teacher offline during scheduled weekly dashboard refresh

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
