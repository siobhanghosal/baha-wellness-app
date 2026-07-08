# Status Banners

- Status: `active`
- Used In: S-00, S-03, S-05, S-06, S-07, S-08, S-09, S-10, S-11, S-12, S-13, S-14

## Purpose

High-visibility inline messaging for consent blocks, warnings, support notices, and maintenance states.

## Variants

- Info
- Success
- Warning
- Danger
- Privacy notice

## States

- Visible
- Dismissed
- Sticky

## Properties

- title
- body
- tone
- actionLabel
- icon

## Sizing

- Inline
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

- Used across offline states, support escalations, consent messaging, and operational notices.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Use banners for route-relevant messaging that must stay visible
- Escalate tone carefully for student-facing distress contexts

## Don't

- Stack multiple banners without priority logic
- Use danger styling for non-urgent preferences

## Flutter Widget Mapping

- `Material banner, custom status banner widget`

## Figma Component Mapping

- `Banner / Tone={Tone} / State={State}`
