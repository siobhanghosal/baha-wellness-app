# Backend Architecture

## Shared Service Topology

The backend is a modular FastAPI platform with shared services exposed to four separate Flutter clients. Modules are independently testable and deployable behind one API gateway or service mesh.

## Service Domains

| Domain | Responsibilities |
|---|---|
| Identity Service | authentication, session issuance, password reset, guardian linking, staff entitlements |
| Consent Service | consent records, assent records, privacy tiers, version history, withdrawal processing |
| Student Wellbeing Service | check-ins, trends, challenge state, badge state, profile summary |
| Learning Service | content catalog, filtering, progress, quizzes, review states |
| Chatbot Service | Safe Questions retrieval, cited response assembly, out-of-scope handling, profile memory hooks |
| Game Service | scenario delivery, telemetry capture, time governance, aggregate signal generation |
| Notification Service | reminder scheduling, alert delivery, rate limits, policy gating |
| Escalation Service | monitoring rules, case creation, queue prioritization, action logging |
| Analytics Service | event capture, aggregates, dashboard projections, exports |
| Audit Service | tamper-evident event log for consent, content, access, and escalation |

## Deployment Model

- Android pilot clients authenticate against one shared backend
- backend is stateless at the API layer
- PostgreSQL stores operational records
- object storage stores content assets and reports
- vector retrieval index supports grounded chatbot answers
- scheduled workers perform reminders, review-date scans, analytics refreshes, and threshold aggregation

## Non-Functional Decisions

- no third-party child-data analytics SDKs
- no passive sensing collectors in initial launch
- no open-ended LLM generation for sensitive content
- no threshold activation without a named on-call owner
