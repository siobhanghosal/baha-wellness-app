# State Diagrams

## Core States

- queue empty
- queue overloaded
- case assigned
- case awaiting follow-up
- case closed
- content flagged expired
- threshold draft
- threshold active

## State Modeling Rules

- gating states resolve before feature states
- empty and loading states are explicit states, not visual afterthoughts
- offline behavior is separate from generic error state where cached functionality exists
- escalation and override states must preserve previous context and auditability

## Recommended State Clusters

- app session state
- role entitlement state
- content availability state
- notification handling state
- support or escalation state
