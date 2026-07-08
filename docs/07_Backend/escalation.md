# Escalation Architecture

## Signal Sources

- repeated low mood and high stress check-ins
- repeated poor sleep patterns
- help requests
- chatbot acute safety disclosures
- game-derived repeated high-risk patterns
- teacher pastoral flags

## Escalation Levels

| Level | Trigger Type | Routing |
|---|---|---|
| L1 | monitoring signal | BAHA queue review |
| L2 | counselor follow-up needed | assigned owner and action log |
| L3 | acute safety disclosure | priority queue, hotline surfaced, override notification |

## Operational Rules

- no automatic parent alert before counselor review except where the approved acute protocol explicitly requires it
- every open case requires an owner
- repeated same-day acute events aggregate into one working case with sub-events
- closed cases remain retained per legal policy
