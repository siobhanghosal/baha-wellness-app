# Critical Issues

## PRR-001

- Issue ID: PRR-001
- Title: Generic renderer does not faithfully implement 88 distinct screens
- Description: The application routes into a single large renderer that decides what to show using broad screen-name matching and reusable placeholder sections instead of dedicated screen implementations. This means the live prototype is not an accurate embodiment of the documented UX architecture.
- Severity: Critical
- Category: UX Implementation Fidelity
- Evidence:
  - `components/design-system/screen-renderer.tsx:189-208` uses a generic hero block for many screens.
  - `components/design-system/screen-renderer.tsx:328-666` branches on loose name patterns such as `buddy`, `learning`, `game`, `teacher`, `settings`, and fallback states.
  - `components/design-system/screen-renderer.tsx` is 680 lines long and acts as a central catch-all renderer.
- Why it matters: Stakeholders, Figma designers, and Flutter engineers need screen-specific truth. A generic renderer makes the demo look more complete than it is and prevents reliable implementation mapping.
- Recommendation: Break the renderer into screen-specific or journey-specific modules starting with the top stakeholder demo flows, and explicitly map each route to a dedicated screen component.
- Estimated effort: 2-3 sprints
- Impact: Very high
- Risk if ignored: BAHA will continue to present a concept shell instead of a trustworthy product prototype, causing downstream rework in design and engineering.
- Priority: P0
- Owner: Frontend Engineering with Product Design
- Suggested Sprint: Sprint 1

## PRR-002

- Issue ID: PRR-002
- Title: Role, auth, and permission requirements are documented but not enforced
- Description: The navigation architecture specifies required authentication, required role, and required permission for each route, but the live app accepts any valid role slug and any valid screen slug without checking those rules.
- Severity: Critical
- Category: Navigation and Security
- Evidence:
  - `docs/14_Navigation/Routing_Table.md` defines route-level auth, role, and permission requirements across 88 routes.
  - `app/[role]/page.tsx:4-7` only validates whether the role exists and otherwise falls back to a default student route.
  - `app/[role]/[screen]/page.tsx:5-11` validates only whether the screen slug exists.
- Why it matters: In a wellness product, routing behavior is part of the privacy and safety model. If the live demo ignores role and permission boundaries, stakeholders cannot accurately assess the product.
- Recommendation: Introduce route guards backed by route metadata, demo session context, and explicit permission states. Unauthorized entry should redirect to documented notice, login, or restriction screens.
- Estimated effort: 1-2 sprints
- Impact: Very high
- Risk if ignored: Stakeholders may see restricted screens out of context, and Flutter implementation may copy an unsafe navigation model.
- Priority: P0
- Owner: Frontend Engineering with Security and Product
- Suggested Sprint: Sprint 1
