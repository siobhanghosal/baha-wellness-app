# Accessibility System

## WCAG Compliance

- Minimum target: WCAG 2.1 AA across contrast, focus, semantics, and text resize.
- Student and parent surfaces should exceed AA where feasible because readability is part of psychological safety.

## Focus Behaviour

- Every interactive control receives a visible focus ring using `color.focus.ring`.
- Dialogs, sheets, and menus trap focus until dismissed.
- Returning focus after overlays close is mandatory.

## Contrast Rules

- Body text contrast target: 4.5:1 minimum.
- Large text and prominent metrics: 3:1 minimum.
- Status color may not be the only carrier of meaning.

## Screen Reader Guidance

- Use route-level titles as semantic headings.
- Announce unread counts, chart summaries, consent states, and support banners in plain language.
- Complex charts must expose a narrative summary adjacent to the visualization.

## Reduced Motion

- Disable shimmer, large transforms, and breathing animation loops when reduced motion is enabled.
- Replace animated state transitions with opacity or immediate swaps where possible.

## Large Text

- Support at least 200 percent text scaling without clipping or overlap.
- Bottom navigation labels may wrap to two lines or switch to alternative layout at large sizes.

## Voice Control

- Buttons, tabs, and rows must have distinct accessible names.
- Avoid multiple identical labels such as repeated "Open" without context.

## Keyboard Navigation

- BAHA and teacher surfaces must be fully keyboard operable.
- Tab order follows visual hierarchy, then safe action priority.
- Data tables require keyboard cell and row traversal support when interactive.
