# Engineering Recommendations

## Core Engineering Moves

1. Replace the catch-all renderer with explicit route-to-component mappings.
2. Introduce route metadata enforcement for auth, role, and permission.
3. Separate reviewer tooling from product UI with a dedicated demo wrapper.
4. Replace local-storage-first persistence with ephemeral demo state by default.
5. Add lint, component test, accessibility audit, and e2e route smoke coverage.

## Architecture Recommendations

- Create a `routes` registry that mirrors `docs/14_Navigation/Routing_Table.md`.
- Create role-specific screen modules instead of name-based rendering branches.
- Move scenario definitions and persona overlays into separate typed data files.
- Normalize screen props around documented screen IDs and state enums.
- Choose one mock-data boundary: fixture imports or mock API, not a blurred hybrid.

## Definition Of Done Upgrade

A screen should not be considered ready unless it has:

- a dedicated component or feature module
- route guard coverage
- documented loading, empty, error, and permission states
- translation-ready strings
- keyboard and screen-reader validation
- automated smoke coverage for entry and exit paths
