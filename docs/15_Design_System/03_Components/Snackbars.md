# Snackbars

- Status: `active`
- Used In: B-04, B-07, B-08, B-09, B-14, B-16

## Purpose

Transient confirmation, retry, and non-blocking status feedback.

## Variants

- Success
- Warning
- Error with retry
- Informational

## States

- Queued
- Visible
- Dismissed

## Properties

- message
- actionLabel
- tone
- duration

## Sizing

- Single-line
- Two-line

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

- Used for saved settings, queued retries, draft saves, and validation recoveries.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Keep copy brief and action-oriented
- Escalate to dialogs when the user must decide before continuing

## Don't

- Use snackbars for crisis or privacy-critical updates
- Queue multiple messages that hide each other

## Flutter Widget Mapping

- `SnackBar, ScaffoldMessenger, custom inline snackbar host`

## Figma Component Mapping

- `Snackbar / Tone={Tone} / State={State}`
