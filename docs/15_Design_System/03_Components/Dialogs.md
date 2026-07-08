# Dialogs

- Status: `active`
- Used In: S-03, S-05, S-06, S-07, S-08, S-09, S-24, S-32, S-33, S-34, S-35, S-36

## Purpose

High-importance confirmation, acknowledgment, or interruption surface.

## Variants

- Confirmation
- Blocking policy dialog
- Destructive confirmation
- Session expired

## States

- Hidden
- Visible
- Submitting
- Error

## Properties

- title
- body
- primaryAction
- secondaryAction
- tone

## Sizing

- Standard
- Full-height mobile dialog

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

- Used for destructive actions, consent impact confirmations, session expiry, and unsaved changes.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Move focus into the dialog and return it on close
- Use plain language for consequences

## Don't

- Stack multiple dialogs
- Use dialogs for routine informational content

## Flutter Widget Mapping

- `AlertDialog, Dialog, showAdaptiveDialog`

## Figma Component Mapping

- `Dialog / Type={Type} / State={State}`
