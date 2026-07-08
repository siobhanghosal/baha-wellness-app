# Medium Priority Issues

## PRR-009

- Issue ID: PRR-009
- Title: Presentation mode still leaks implementation and seeded demo metadata
- Description: Presentation mode reduces some controls, but the app still exposes prototype labels, route context, persona labels, scenario context, and optimistic coverage claims in the live experience.
- Severity: Medium
- Category: Presentation Quality
- Evidence:
  - `components/design-system/app-shell.tsx:91-105` still surfaces pattern and layout metadata unless specific toggles are disabled.
  - `components/design-system/presentation-controls.tsx:110-115` prints route, scenario, and persona context.
  - `components/design-system/demo-launcher.tsx:203-210` presents strong claims such as full documented flow coverage.
- Why it matters: A stakeholder review prototype should feel polished and deliberate, not like an internal implementation console.
- Recommendation: Create a true presentation preset that removes implementation chrome and replaces internal labels with presenter-safe language.
- Estimated effort: 2-3 days
- Impact: Medium
- Risk if ignored: Demos will feel less trustworthy and more obviously unfinished.
- Priority: P2
- Owner: Frontend Engineering
- Suggested Sprint: Sprint 2

## PRR-010

- Issue ID: PRR-010
- Title: Monolithic renderer and hard-coded content are weak units for Flutter handoff
- Description: Large centralized files currently own route rendering, persona logic, scenario logic, and content mapping. This organization is not close to how a Flutter team would structure maintainable screens, flows, and state.
- Severity: Medium
- Category: Flutter Readiness
- Evidence:
  - `components/design-system/screen-renderer.tsx` is 680 lines long.
  - `lib/demo-content.ts` is 648 lines long.
  - `components/design-system/demo-launcher.tsx` combines audience entry, scenarios, personas, and dashboard reporting in one file.
- Why it matters: Flutter implementation should inherit stable boundaries such as route config, journey modules, screen view models, and component contracts.
- Recommendation: Split content, route metadata, view logic, and role-specific screens into explicit modules that map cleanly to Flutter features.
- Estimated effort: 1 sprint
- Impact: Medium
- Risk if ignored: The Flutter team will have to reverse-engineer product structure instead of implementing from stable source artifacts.
- Priority: P2
- Owner: Frontend Architecture
- Suggested Sprint: Sprint 2

## PRR-011

- Issue ID: PRR-011
- Title: Data access is inconsistent and masks failures
- Description: The project contains a mock-service layer, direct local imports, and fallback behavior that suppresses errors. This makes the data story harder to trust and harder to port.
- Severity: Medium
- Category: Reliability
- Evidence:
  - `lib/init-mocks.ts:5-10` swallows MSW boot failures.
  - `lib/api.ts:16-30` resolves role data from imported JSON.
  - `hooks/use-prototype-data.ts:7-13` fetches role data through the local helper rather than a route-accurate API boundary.
  - `mock-data/msw/handlers.ts` defines handlers that are only partially reflected in app usage.
- Why it matters: Reviewers and engineers need to know whether a flow is backed by documented data contracts or just static imports.
- Recommendation: Choose one prototype data strategy and make failures visible. Prefer explicit mock API contracts or explicit static fixture loading, not both.
- Estimated effort: 3-5 days
- Impact: Medium
- Risk if ignored: Later integration work will uncover hidden assumptions and inconsistent behaviors.
- Priority: P2
- Owner: Frontend Engineering
- Suggested Sprint: Sprint 2

## PRR-012

- Issue ID: PRR-012
- Title: Accessibility semantics are incomplete on key controls and forms
- Description: The prototype uses visually strong primitives, but several controls rely on icons, placeholders, or surrounding text without robust programmatic labeling and state semantics.
- Severity: Medium
- Category: Accessibility
- Evidence:
  - `components/design-system/app-shell.tsx:87-89` renders an icon-only back control without a visible text label or explicit `aria-label`.
  - `components/ui/input.tsx` provides styling primitives but not built-in labeling relationships.
  - `components/design-system/feedback-panel.tsx:73-90` uses visible labels and inputs, but dialog semantics, grouping, and keyboard flow are not fully formalized.
  - `components/design-system/data-widgets.tsx:24-43` uses presentational bars for charting without chart semantics.
- Why it matters: Accessibility must be part of the design truth before Figma and Flutter handoff, not added later.
- Recommendation: Add accessible naming, field association, keyboard order validation, focus states for overlays, and semantic chart alternatives.
- Estimated effort: 1 sprint
- Impact: Medium
- Risk if ignored: BAHA will be harder to review, less inclusive, and more expensive to remediate later.
- Priority: P2
- Owner: Frontend Engineering with Design
- Suggested Sprint: Sprint 2

## PRR-013

- Issue ID: PRR-013
- Title: Implemented styling does not yet reflect the documented visual language
- Description: The visual-language documentation describes a nuanced emotional and age-specific design direction, but the prototype currently applies a narrow token layer and a largely uniform typography system.
- Severity: Medium
- Category: Visual Language
- Evidence:
  - `docs/16_Visual_Language/Visual_Guide.md:13-20` defines a "Calm Neo-Modern Care System".
  - `docs/16_Visual_Language/Visual_Guide.md:61-67` describes richer atmospherics, geometry, and emotional qualities.
  - `app/globals.css:5-67` implements a small color-token set and a single body font.
  - `tailwind.config.ts:34-37` defines only one display stack and one body stack for all audiences.
- Why it matters: If the live prototype becomes the visual reference, it will undersell the intentionality documented in the design language.
- Recommendation: Explicitly implement age-group and role-based visual variants, starting with palette, type scale, card styling, and empty/loading states.
- Estimated effort: 1-2 sprints
- Impact: Medium
- Risk if ignored: Figma generation may drift toward the current minimal implementation instead of the intended system.
- Priority: P2
- Owner: Design Systems and Frontend Engineering
- Suggested Sprint: Sprint 3

## PRR-014

- Issue ID: PRR-014
- Title: Fixed overlays and utility chrome can obstruct content on smaller screens
- Description: Presentation controls, feedback tools, and side utility panels are fixed in viewport space and can compete with the actual screen under review.
- Severity: Medium
- Category: Responsive UX
- Evidence:
  - `components/design-system/feedback-panel.tsx:49-55` anchors the feedback tool to the bottom-right corner.
  - `components/design-system/presentation-controls.tsx:63-107` anchors review controls as a floating panel.
  - `components/design-system/app-shell.tsx` combines header metadata and aside content that may compress core layouts.
- Why it matters: Stakeholder reviews often happen on laptops, projectors, or smaller browser windows where overlays can distort perceived layout quality.
- Recommendation: Create a dedicated presenter layout with responsive breakpoints, docking rules, and a one-click "clean view" mode.
- Estimated effort: 2-4 days
- Impact: Medium
- Risk if ignored: Screens may appear more crowded or less polished than the underlying UX warrants.
- Priority: P2
- Owner: Frontend Engineering
- Suggested Sprint: Sprint 2
