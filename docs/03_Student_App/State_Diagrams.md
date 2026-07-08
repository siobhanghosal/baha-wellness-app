# State Diagrams

## Core States

- first launch
- consent blocked
- awaiting parent approval
- empty trend history
- offline cached mode
- chatbot unavailable
- override in progress
- profile deletion requested

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
