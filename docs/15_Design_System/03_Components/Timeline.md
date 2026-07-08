# Timeline

- Status: `active`
- Used In: B-03, B-04, B-12, B-15

## Purpose

Chronological event view for cases, action logs, thresholds, and audit-style histories.

## Variants

- Case timeline
- Audit event timeline
- Threshold history

## States

- Loading
- Empty
- Populated
- Filtered

## Properties

- events
- grouping
- status
- actor
- timestamp

## Sizing

- Embedded
- Full-page

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

- Used in BAHA case detail, action history, threshold history, and audit-linked views.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Order newest or most relevant events predictably
- Preserve actor, time, and action semantics

## Don't

- Collapse critical events without affordance
- Hide escalation state transitions

## Flutter Widget Mapping

- `Custom sliver timeline, ListView with vertical rule, expansion tiles`

## Figma Component Mapping

- `Timeline / Variant={Variant} / State={State}`
