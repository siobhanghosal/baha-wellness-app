# Notifications

- Status: `active`
- Used In: S-09, S-29, S-30, S-31, S-32, S-36, S-37, S-38, P-11, P-12, T-05, T-06

## Purpose

List row and card treatment for alerts, reminders, policy updates, and referral updates.

## Variants

- Reminder
- Alert
- Operational update
- Policy update

## States

- Unread
- Read
- Action required
- Archived

## Properties

- title
- body
- timestamp
- tone
- cta
- readState

## Sizing

- Row
- Card
- Banner teaser

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

- Used in notification centers, home alerts, parent summary reminders, and teacher updates.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Reflect urgency through tone and copy, not just color
- Show the destination or expected action clearly

## Don't

- Expose private data in compact notifications
- Mark critical notices as read automatically without acknowledgment

## Flutter Widget Mapping

- `ListTile, Card, badge wrappers, push routing adapters`

## Figma Component Mapping

- `Notification / Variant={Variant} / State={State}`
