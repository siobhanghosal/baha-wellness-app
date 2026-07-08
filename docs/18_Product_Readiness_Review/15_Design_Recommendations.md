# Design Recommendations

## Immediate Design Actions

1. Identify the three highest-value stakeholder flows and create fidelity benchmarks for them.
2. Use the UX specification, not the current prototype screens, as the main source for Figma generation.
3. Define explicit role and age-band visual deltas that must appear in the live prototype.
4. Create chart, empty-state, loading-state, and privacy-state patterns that are implementation-ready.
5. Review every screen currently rendered by generic templates and mark whether it needs unique composition.

## Design System Focus

- Establish token usage rules for student age bands, parent calmness, teacher utility, and counselor seriousness.
- Define when reviewer-only UI can appear and how it must visually separate from the product.
- Add accessibility annotations to components before full-screen Figma production.
- Create input-pattern guidance so unsupported free-text interactions are not accidentally designed back in.

## Design Warning

If Figma generation starts from the current prototype without correction, the resulting screens will be visually consistent but behaviorally inaccurate.
