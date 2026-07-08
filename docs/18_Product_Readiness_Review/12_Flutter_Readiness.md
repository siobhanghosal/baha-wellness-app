# Flutter Readiness

## Overall Assessment

The repository is partially ready for Flutter translation. The documentation layer is ahead of the implementation layer, which means Flutter should derive from the architecture docs first and the live prototype second.

## Readiness Matrix

| Area | Score / 100 | Status | Notes |
| --- | --- | --- | --- |
| Route inventory | 80 | Strong | 88 documented routes exist in navigation docs |
| Screen contracts | 62 | Moderate | UX specs are detailed, but live screens are generic |
| State modeling | 68 | Moderate | State diagrams exist, prototype state is simplistic |
| Component mapping | 54 | Moderate-low | UI primitives exist, design-system implementation is thin |
| Theming and tokens | 58 | Moderate-low | Token foundation exists, age and role variants are not fully implemented |
| Localization | 25 | Weak | Infrastructure exists but is not active in UI |
| Accessibility | 35 | Weak | Important semantics and audits are missing |
| Testability | 30 | Weak | No frontend automation baseline |

## What Is Ready To Reuse

- route names and screen IDs from `docs/14_Navigation/`
- screen-level intent and states from `docs/13_UX_Specification/`
- visual direction from `docs/16_Visual_Language/`
- basic token naming from `app/globals.css` and `tailwind.config.ts`

## What Is Not Ready To Reuse Directly

- the generic `screen-renderer.tsx` as a Flutter screen blueprint
- current role switching behavior as a routing model
- current free-text workflow forms as product truth
- current local-storage prototype store as a production state model

## Recommended Flutter Handoff Package

1. Route registry with required auth, role, and permission metadata.
2. One Dart feature module per role journey, not one shared catch-all renderer.
3. Screen-specific state contracts derived from the UX specs.
4. Token export that includes age-band and role variants.
5. Accessibility and localization acceptance criteria per route.

## Flutter Readiness Verdict

Proceed with Flutter architecture planning, but do not treat the current prototype implementation as the canonical source. Use the documentation set as source of truth until the high-severity implementation gaps are closed.
