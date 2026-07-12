# BAHA Story World and Games Plan

## 1. Purpose

This document records the branch audit for `origin/Solomon_UI_Version1` and defines how game features should be integrated into the BAHA product without drifting away from the PRD, current backend architecture, or the intended local-LLM direction.

It should be read with:

- [BAHA_Project_PRD_v2.md](/Users/sudharshan/Desktop/PES/RF Internship/BAHA_Project_PRD_v2.md)
- [APP_FLOW_ARCHITECTURE.md](./APP_FLOW_ARCHITECTURE.md)
- [SCREEN_API_MATRIX.md](./SCREEN_API_MATRIX.md)
- [UI_BACKEND_INTEGRATION_PLAN.md](./UI_BACKEND_INTEGRATION_PLAN.md)

## 2. Audit Summary Of The Teammate Branch

The teammate branch does **not** add a full mini-game suite.

What it actually adds:

- one substantial new student feature called `Story World`
- one new backend game runtime built around that feature
- one separate offline `ui_prototype/` app
- one older onboarding/auth backend direction that does not match the current branch

What it does **not** add:

- multiple backend-backed mini games
- a BAHA-aligned student game hub
- a local-LLM or on-prem model runtime
- a game architecture connected to the current student identity and consent model

Current branch status:

- `Comet Sequence` exists as a local student memory/attention mini-game
- `Calm Breathing` exists as a local student wellness tool
- `Focus Catch` exists as a local student visual-tracking mini-game
- `Story World` now exists in the current branch as a BAHA-aligned backend-backed feature

So the honest state is:

- there are already three lightweight student tools in the current app
- the teammate branch provided the reference direction for one larger story-driven game concept
- there are no other meaningful teammate-built mini games beyond that

## 3. What Was Reused From Story World

The useful parts are mostly product and UX ideas:

- a world-selector game shell inside the student app
- free-text interaction instead of rigid multiple-choice only
- persistent progress across locations
- emotionally safe NPC-guided scenarios
- game progression tied to cooperation, calming, confidence, inclusion, and help-seeking themes
- lightweight retrieval grounding so scenes are informed by approved BAHA content

These are directionally compatible with the PRD because the PRD calls for:

- insight-generating wellness games
- BAHA-approved chatbot/content boundaries
- age-aware presentation
- non-diagnostic behavioral signal capture

## 4. What Should Not Be Reused As-Is

These parts conflict with the current architecture and should not be merged directly:

- `OpenAIStoryEngine` and any OpenAI-dependent response path
- `X-Story-Player-Key` and `X-BAHA-Game-Key` header-based identity
- the separate `game_players` identity model disconnected from `student_profiles`
- the older alternate onboarding/auth schema from the teammate branch
- hard-coding the feature to ages `9-12` at the data-model level
- frontend/backend world mismatches where the backend defines worlds the app does not expose

The main architectural issue is that the teammate branch built a parallel game system instead of extending the existing BAHA student runtime.

## 5. BAHA-Aligned Story World Architecture

This architecture is now implemented in the current branch for the first usable demo slice:

- authenticated student-only access
- persistent progress stored against `student_profile_id`
- additive `story_world_*` runtime tables
- game events recorded through `game_sessions` and `game_session_events`
- non-diagnostic signals recorded through `game_behavioral_signals`
- deterministic server-side narrative progression
- no OpenAI dependency

### 5.1 Identity and access

Story World should run inside the current student-authenticated app flow:

- student logs in through the normal BAHA auth/session system
- backend resolves `student_profile_id` from the authenticated actor
- game state is stored against the existing student identity
- consent, privacy, and safeguarding remain server-side like the rest of the product

Story World should **not** create a separate player identity outside the current student model.

### 5.2 Data model

Use the current operational game schema as the base:

- `game_sessions`
- `game_session_events`
- `game_behavioral_signals`

If Story World needs persistent world-state beyond one session, add additive tables that still point back to `student_profile_id`, for example:

- `story_world_profiles`
- `story_world_location_progress`
- `story_world_npc_memory`

Do not introduce a separate `game_players` root entity unless it is directly keyed to the existing BAHA student identity.

### 5.3 Content model

Story World content should be published through the governed content layer, not embedded ad hoc in code.

Use content records for:

- world definitions
- location intros
- NPC profiles
- scenario seeds
- progression beats
- age-band variants
- citations and review status

That keeps story content reviewable by BAHA and consistent with the learning/content system.

### 5.4 Runtime intelligence

The intended direction remains:

- deterministic fallback behavior first
- local or self-hosted LLM later
- retrieval grounding from BAHA-reviewed content throughout

For BAHA, the acceptable progression is:

1. rules/templates only
2. rules/templates plus retrieved evidence notes
3. local or self-hosted grounded generation

The product baseline should **not** depend on external OpenAI APIs.

### 5.5 Age-band design

The teammate branch hard-coded a `9-12` feel into both copy and schema. That is too narrow for BAHA.

The better model is:

- `9_12`: playful, guided, magical/exploratory presentation
- `13_14`: still interactive, but less childish and more social-confidence focused
- `15_18`: more grounded life-scenario framing, still safe and non-clinical

This should be handled through content packs and presentation variants, not through separate backend architectures.

## 6. API Shape

The long-term API should sit under the authenticated mobile namespace, not under a detached game namespace.

Implemented endpoints:

- `GET /mobile/student/games/story-world/state`
- `GET /mobile/student/games/story-world/scenes/{location_id}`
- `POST /mobile/student/games/story-world/turns`

Still recommended later if the game hub expands:

- `GET /mobile/student/games`
  returns available game cards, eligibility, and progress summary
- `POST /mobile/student/games/sessions`
  creates or resumes a game session
- `GET /mobile/student/games/sessions/{game_session_id}`
  returns session state
- `POST /mobile/student/games/sessions/{game_session_id}/events`
  records turns, choices, and gameplay events
- `GET /mobile/student/games/story-world/state`
  returns persistent Story World progress if we keep a long-lived world model
- `POST /mobile/student/games/story-world/turns`
  submits a free-text turn and returns the next safe, grounded scene

This keeps the mobile app aligned with the rest of the backend contract.

## 7. Mini-Game Recommendation

Yes, simple cognitive-style games are useful for demo purposes, but only if they support the product intention rather than feeling random.

Good demo-game criteria:

- short session length
- visually engaging on mobile
- easy to explain
- yields non-diagnostic behavioral signals
- maps to skills already present in the PRD

The current best demo portfolio is:

- `Comet Sequence`
- `Calm Breathing`
- `Focus Catch`
- `Story World`

That is already enough for a credible student-game demo slice.

Design direction for the two lightweight cognitive games:

- `Comet Sequence`
  follows the familiar sequence-repeat pattern popularized by games like `Simon`, but wrapped in BAHA visuals and age-safe copy
- `Focus Catch`
  follows the quick tap-and-track rhythm of simple mobile reaction games, but without aggressive scoring loops or noisy arcade framing

Product caution:

- these games are justified as short attention/memory/coordination activities and engagement surfaces
- they should not be marketed as proven therapeutic or intelligence-boosting interventions

Do **not** add generic arcade-style games that do not connect to wellbeing, reflection, or behavior signals.

## 8. Practical Build Order

The best order from here is:

1. keep the current local tools as-is
2. stabilize and polish the implemented Story World slice
3. map Story World beats to governed content records instead of code-only definitions
4. only then add a local or self-hosted grounded model path
5. only after Story World is stable consider one extra cognitive demo game

## 9. Decision

The teammate branch should be treated as a reference branch for Story World UX and content direction only.

It should not be merged wholesale because it would introduce:

- a conflicting auth/identity model
- an OpenAI dependency we do not want
- a parallel game runtime detached from the current backend

The right move is:

- preserve the `Story World` idea
- rebuild it inside the current BAHA backend and student app architecture
