# API Flows

## Core Request Families

1. Identity and session
2. Consent and privacy tiers
3. Check-ins and trends
4. Learning content and progress
5. Chatbot and Safe Questions
6. Games and telemetry
7. Notifications
8. Escalation and case management
9. Analytics and exports

## Shared Flow Pattern

1. client sends authenticated request
2. API gateway resolves role and deployment context
3. consent and privacy policy checks run when data is sensitive
4. domain service executes command or query
5. audit event is appended for sensitive mutations
6. response is filtered to role-safe payload

## Cross-Service Dependencies

- chatbot may read profile memory but may not expose raw records cross-role
- parent summary depends on trend aggregates and consent tiers
- teacher dashboard depends on weekly cohort rollups and anonymization thresholds
- BAHA queue depends on check-in, chatbot, game, and pastoral signal ingests
