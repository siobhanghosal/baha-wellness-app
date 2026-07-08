# Low Priority Issues

## PRR-015

- Issue ID: PRR-015
- Title: Analytics widgets are largely presentational rather than semantically robust
- Description: Current chart and timeline widgets visually suggest analytics depth, but they operate more like static cards and progress bars than real information visualizations with explicit states, legends, and accessibility support.
- Severity: Low
- Category: Analytics UX
- Evidence:
  - `components/design-system/data-widgets.tsx:24-43` renders a bar chart as simple stacked blocks.
  - `components/design-system/data-widgets.tsx:45-59` uses a lightweight timeline card pattern without richer drill-down semantics.
- Why it matters: The current widgets are acceptable for early demos, but not yet strong enough to serve as authoritative data-visualization references.
- Recommendation: Define canonical chart patterns, legends, no-data states, and accessible summaries in the design system before Flutter implementation.
- Estimated effort: 3-4 days
- Impact: Medium-low
- Risk if ignored: Analytics-heavy screens may need rework during implementation.
- Priority: P3
- Owner: Design Systems with Frontend Engineering
- Suggested Sprint: Sprint 3

## PRR-016

- Issue ID: PRR-016
- Title: Repository structure overstates actual multi-app and design-system maturity
- Description: Folder structure implies separated apps and a reusable design system, but several directories are mostly placeholders or shallow config wrappers.
- Severity: Low
- Category: Repository Maturity
- Evidence:
  - `apps/student/config.ts`, `apps/parent/config.ts`, `apps/teacher/config.ts`, and `apps/counselor/config.ts` mainly export small configuration objects.
  - `design-system/README.md` is a placeholder rather than an implemented library.
  - `styles/README.md` notes that styling is centralized elsewhere.
- Why it matters: This does not block demos directly, but it can create confusion about how much architectural separation has actually been implemented.
- Recommendation: Either simplify the structure to reflect current reality or invest in real package boundaries and reusable system modules.
- Estimated effort: 2-3 days for clarification, longer for structural refactor
- Impact: Low
- Risk if ignored: New contributors may overestimate existing reuse and under-scope implementation work.
- Priority: P3
- Owner: Engineering Leadership
- Suggested Sprint: Sprint 3
