# Bottom Sheets

- Status: `active`
- Used In: B-02, B-14

## Purpose

Secondary action menus, filter pickers, and compact mobile disclosures.

## Variants

- Action sheet
- Filter sheet
- Picker sheet
- Half-height detail sheet

## States

- Hidden
- Expanded
- Dragging
- Submitting

## Properties

- title
- content
- primaryAction
- dismissible

## Sizing

- Peek
- Half
- Full

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

- Used on mobile-friendly filters, content actions, and list utility menus.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Keep the primary selection task focused
- Use sheets instead of new routes for short utility tasks

## Don't

- Hide critical policy copy below a drag gesture
- Overfill sheets with long forms

## Flutter Widget Mapping

- `showModalBottomSheet, DraggableScrollableSheet`

## Figma Component Mapping

- `Bottom Sheet / Height={Height} / State={State}`
