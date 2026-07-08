# Progress Indicators

- Status: `active`
- Used In: S-00, S-11, S-12, S-13, S-14, S-15, S-16, S-17, S-20, S-21, S-22, S-23

## Purpose

Communicates loading, completion, or current step status.

## Variants

- Circular indeterminate
- Linear determinate
- Completion ring
- Inline status progress

## States

- Hidden
- Active
- Complete
- Error

## Properties

- value
- label
- isIndeterminate
- tone

## Sizing

- Inline
- Section
- Full-width

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

- Used during bootstrap, guided flows, learning completion, moderation queues, and data fetches.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Use determinate progress when the system knows the denominator
- Accompany long waits with explanatory copy

## Don't

- Leave users in spinner-only states without context
- Animate for extended periods without status updates

## Flutter Widget Mapping

- `CircularProgressIndicator, LinearProgressIndicator, custom completion meter`

## Figma Component Mapping

- `Progress / Type={Type} / State={State}`
