# Empty States

- Status: `active`
- Used In: S-39, P-14, T-14

## Purpose

Structured no-data treatment with explanation and next best action.

## Variants

- No history
- No results
- No linked data
- Filtered empty

## States

- Visible

## Properties

- title
- body
- illustration
- primaryAction
- secondaryAction

## Sizing

- Card
- Full-page

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

- Used in trend-empty, offline summary placeholders, sparse queues, and search zero-results states.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Explain why the screen is empty
- Offer one clear recovery path

## Don't

- Leave users on blank white space
- Use blame-oriented language

## Flutter Widget Mapping

- `Column or sliver composition with illustration and action row`

## Figma Component Mapping

- `Empty State / Variant={Variant}`
