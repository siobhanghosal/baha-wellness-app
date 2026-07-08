# QA Recommendations

## Baseline QA Stack

1. Add linting for the frontend codebase.
2. Add unit or component tests for launcher, shell, route guards, and feedback tools.
3. Add e2e tests for at least one scenario per role.
4. Add accessibility assertions for launcher, dialogs, and top demo flows.
5. Add route coverage validation against `docs/14_Navigation/Routing_Table.md`.

## QA Priority Matrix

| Priority | Area | Goal |
| --- | --- | --- |
| P0 | Routing | Every documented protected route must enforce expected access behavior |
| P0 | Demo flows | Every guided scenario must reach its intended screens |
| P1 | Accessibility | Keyboard and accessible-name audits for core journeys |
| P1 | Persistence | Prototype reset must clear local demo state completely |
| P1 | Content | Hard-coded claims and mismatched inputs must be detected |

## Exit Criteria For Demo QA

- no broken scenario paths
- no unguarded restricted routes
- no overlapping panels on common laptop sizes
- no critical a11y violations in launcher and primary journeys
- no contradictions between documented and implemented input patterns
