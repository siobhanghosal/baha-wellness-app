# Services

## Client Services

- secure storage service
- API client and token refresh service
- notification registration service
- local cache service
- analytics event emitter
- accessibility and localization service
- offline sync orchestrator

## Cross-Cutting Requirements

- never store secrets in plaintext
- never expose raw sensitive student data in logs
- keep retry behavior idempotent for check-ins, pastoral flags, and case actions
