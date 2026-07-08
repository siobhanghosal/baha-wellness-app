# Tooltips

- Status: `active`
- Used In: S-14, S-15, S-16, S-29, S-30, S-31, S-32, P-07, T-03, T-04, B-10

## Purpose

Contextual explanation for unfamiliar metrics, policy labels, and status chips.

## Variants

- Hover tooltip
- Tap popover
- Inline info hint

## States

- Hidden
- Visible

## Properties

- label
- body
- trigger
- placement

## Sizing

- Compact
- Expanded popover

## Spacing

- Inner padding uses the global spacing scale, typically `space.3` to `space.6` depending on density.
- Component-to-component spacing follows layout rhythm rather than ad hoc margins.

## Accessibility

- Feedback components must match severity to context and manage focus when they interrupt the user.
- This component must meet WCAG 2.1 AA contrast requirements in both light and dark themes.

## Keyboard Behaviour

- Dialogs trap focus, snackbars expose action shortcuts when present, and dismiss actions are keyboard reachable.

## Screen Reader Behaviour

- Urgent or blocking feedback uses alert semantics; transient feedback avoids excessive interruption.

## Touch Target

- Minimum 48x48 dp for interactive regions; larger where a wellbeing or support flow benefits from easier reach.

## Dark Mode

- Aliases to dark-theme semantic tokens and avoids low-contrast or neon-heavy treatment.

## Light Mode

- Uses light-theme semantic tokens and preserves contrast on warm neutral surfaces.

## Animation

- Use tokenized motion only. Non-essential animation must disable under reduced-motion settings.

## Microinteractions

- Pressed, focus, selected, loading, and completion microstates must be visually and semantically distinct.

## Usage Guidelines

- Used for charts, privacy terminology, threshold metadata, and source citations.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Keep explanations concise and jargon-light
- Ensure mobile tap alternatives exist

## Don't

- Hide required workflow instructions in tooltips
- Use hover-only behavior on touch-first screens

## Flutter Widget Mapping

- `Tooltip, Popover, custom anchored info sheet on mobile`

## Figma Component Mapping

- `Tooltip / Type={Type}`
