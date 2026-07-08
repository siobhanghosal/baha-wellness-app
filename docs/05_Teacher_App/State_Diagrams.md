# State Diagrams

## Core States

- training required
- cohort threshold too small
- dashboard available
- pastoral flag drafted
- referral in review
- referral closed

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
