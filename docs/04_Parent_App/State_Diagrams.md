# State Diagrams

## Core States

- consent pending
- consent active
- consent expired
- weekly summary not available
- summary available
- alert active
- student privacy tier changed

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
