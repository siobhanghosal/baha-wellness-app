# Profile Cards

- Status: `active`
- Used In: S-33, P-03

## Purpose

Condensed summary of person-linked preferences, consent posture, or eligible summary scope.

## Variants

- Student summary
- Guardian link
- Preference summary
- Consent snapshot

## States

- Default
- Selected
- Warning
- Restricted

## Properties

- title
- subtitle
- avatar
- status
- actions

## Sizing

- Standard
- Wide

## Spacing

- Inner padding uses the global spacing scale, typically `space.3` to `space.6` depending on density.
- Component-to-component spacing follows layout rhythm rather than ad hoc margins.

## Accessibility

- Display components must clarify hierarchy and should never conceal critical status information.
- This component must meet WCAG 2.1 AA contrast requirements in both light and dark themes.

## Keyboard Behaviour

- Interactive wrappers such as cards or rows must expose button or link semantics; non-interactive display remains out of the tab order.

## Screen Reader Behaviour

- Screen readers announce heading, supporting text, status, and action affordances in reading order.

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

- Used in student profile summary, parent linked-student views, and consent-related review screens.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Show only the minimum profile summary needed for the task
- Use explicit status treatment for restricted access

## Don't

- Expose hidden notes or private identifiers
- Mix unrelated preference controls into summary cards

## Flutter Widget Mapping

- `Custom card composition using Card, ListTile, badges, and buttons`

## Figma Component Mapping

- `Profile Card / Variant={Variant} / State={State}`
