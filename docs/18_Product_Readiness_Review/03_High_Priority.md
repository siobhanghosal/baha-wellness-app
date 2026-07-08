# High Priority Issues

## PRR-003

- Issue ID: PRR-003
- Title: Cross-role switcher breaks role boundaries described in the specs
- Description: The app shell exposes a persistent role switcher that lets reviewers jump between student, parent, teacher, and counselor views from inside any screen. The UX and navigation documentation repeatedly state that cross-role navigation is not supported in-product.
- Severity: High
- Category: Privacy and UX Integrity
- Evidence:
  - `components/design-system/app-shell.tsx:108-124` renders a global cross-role switcher.
  - `docs/13_UX_Specification/Student_Buddy_Chat.md:69-75` states that cross-role navigation is not supported through the UI.
  - `docs/14_Navigation/Feature_Flows/Student_Buddy_Chat.md:61` repeats the same navigation rule.
- Why it matters: This undermines role-based storytelling, privacy boundaries, and stakeholder trust in the architecture.
- Recommendation: Move role switching back to the demo launcher, or gate it behind a clearly labeled reviewer-only control that is hidden during normal presentation mode.
- Estimated effort: 2-4 days
- Impact: High
- Risk if ignored: Reviewers may misunderstand BAHA as a single blended interface instead of distinct role-scoped products.
- Priority: P1
- Owner: Product Design and Frontend Engineering
- Suggested Sprint: Sprint 1

## PRR-004

- Issue ID: PRR-004
- Title: Prototype navigation exposes only a small subset of screens
- Description: The prototype claims broad route coverage, but the live navigation panel only renders the first eight screens for the current role. This materially limits what a reviewer can discover without direct URL knowledge.
- Severity: High
- Category: Demo Coverage
- Evidence:
  - `components/design-system/screen-renderer.tsx:124-145` labels a panel as "Prototype navigation".
  - `components/design-system/screen-renderer.tsx:133` renders `roleScreens.slice(0, 8)`.
- Why it matters: A stakeholder prototype should make documented coverage legible. Hidden routes create a false sense of completeness and make review uneven.
- Recommendation: Expose all reviewable screens through grouped navigation, scenario launchers, or indexed journey maps.
- Estimated effort: 2-3 days
- Impact: High
- Risk if ignored: Coverage claims will be hard to validate during demonstrations and design review.
- Priority: P1
- Owner: Frontend Engineering
- Suggested Sprint: Sprint 1

## PRR-005

- Issue ID: PRR-005
- Title: Localization framework exists but is not wired into UI copy
- Description: The repository contains translation data and a translation hook, but the visible UI still uses hard-coded English copy across the launcher, shell, renderer, and widgets.
- Severity: High
- Category: Localization
- Evidence:
  - `lib/api.ts:32-35` exposes `getTranslations`.
  - `hooks/use-prototype-data.ts:23-28` defines `useTranslations`.
  - `mock-data/json/translations.json` contains only a minimal dictionary.
  - Search across `app/`, `components/`, and `lib/` shows virtually all user-facing copy is still hard-coded.
- Why it matters: BAHA targets diverse audiences and consent-sensitive flows. Localization cannot be treated as cosmetic after the fact.
- Recommendation: Introduce a consistent translation accessor for all visible strings and expand the translation inventory for high-priority routes.
- Estimated effort: 1-2 sprints
- Impact: High
- Risk if ignored: Future Figma and Flutter work will replicate hard-coded copy and create expensive retrofits.
- Priority: P1
- Owner: Frontend Engineering with Content Design
- Suggested Sprint: Sprint 2

## PRR-006

- Issue ID: PRR-006
- Title: No frontend test, lint, accessibility, or e2e automation exists
- Description: The project has build and typecheck scripts, but no frontend test harness, lint step, accessibility audit step, or end-to-end journey coverage for the stakeholder prototype.
- Severity: High
- Category: QA Readiness
- Evidence:
  - `package.json` contains `dev`, `build`, `start`, and `typecheck` scripts only.
  - `tests/` contains Python-oriented repository tests rather than app-level UI coverage.
- Why it matters: A wellness demo spanning permissions, consent, escalation, and multi-role flows should not rely on manual spot checks alone.
- Recommendation: Add linting, component tests, route smoke tests, accessibility assertions, and at least one e2e demo-path suite.
- Estimated effort: 1 sprint for baseline, ongoing thereafter
- Impact: High
- Risk if ignored: Regressions will appear in navigation, privacy flows, and stakeholder-facing presentations without early warning.
- Priority: P1
- Owner: Frontend Engineering with QA
- Suggested Sprint: Sprint 1

## PRR-007

- Issue ID: PRR-007
- Title: Persona and feedback state are stored locally with realistic mock identities
- Description: The prototype persists reviewer state, persona selection, and feedback entries in local storage while mock datasets include realistic names and school-style identifiers.
- Severity: High
- Category: Privacy and Data Handling
- Evidence:
  - `lib/prototype-store.tsx:98-162` loads and persists prototype state in `localStorage`.
  - `lib/prototype-store.tsx:198-213` stores feedback entries in client state that is later persisted.
  - `components/design-system/feedback-panel.tsx:37-45` exports feedback as a raw JSON download.
  - `mock-data/json/prototype-data.json:18-25` and nearby sections use realistic identities such as student and guardian names.
- Why it matters: Even in a prototype, privacy signaling matters. Demo tooling should model governed handling rather than casual persistence of potentially sensitive-seeming records.
- Recommendation: Replace realistic names with clearly fictionalized data, add demo-data notices, disable persistent storage by default for stakeholder sessions, and define a governed export path.
- Estimated effort: 4-6 days
- Impact: High
- Risk if ignored: Stakeholders may question data governance maturity, especially clinicians and school partners.
- Priority: P1
- Owner: Product, Privacy, and Frontend Engineering
- Suggested Sprint: Sprint 1

## PRR-008

- Issue ID: PRR-008
- Title: Generic free-text forms contradict screen-specific interaction specs
- Description: Several screens documented as no-free-text or narrowly constrained workflows are rendered with generic text inputs, textareas, or message composition fields in the prototype.
- Severity: High
- Category: PRD Fidelity
- Evidence:
  - `docs/13_UX_Specification/Student_Buddy_Chat.md:94` states no free-text input is required for the primary happy path.
  - `components/design-system/screen-renderer.tsx:378-383` renders a message input for buddy chat.
  - `components/design-system/screen-renderer.tsx:539-543` renders a generic workflow form with free-text fields.
  - Many UX spec files in `docs/13_UX_Specification/` explicitly state that no free-text input is required for their primary happy path.
- Why it matters: Input design is closely tied to safeguarding, moderation, validation, and implementation complexity. Generic inputs change the product meaning.
- Recommendation: Replace generic forms with route-specific controls aligned to the UX specification, especially in chat, escalation, and consent journeys.
- Estimated effort: 1 sprint
- Impact: High
- Risk if ignored: Designers and engineers will overbuild unsupported interaction models and misrepresent clinical safeguards.
- Priority: P1
- Owner: Product Design with Frontend Engineering
- Suggested Sprint: Sprint 2
