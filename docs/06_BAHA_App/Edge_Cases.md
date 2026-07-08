# Edge Cases

## Role-Specific Edge Cases

- no on-call counselor exists for a thresholded event
- multiple acute disclosures from the same student in one day
- content review date expires during active publication
- case closure attempted without action note
- analytics export requested during partial data sync

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
