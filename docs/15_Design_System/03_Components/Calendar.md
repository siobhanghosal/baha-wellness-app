# Calendar

- Status: `reserved`
- Used In: Not currently used by a PRD-backed screen.

## Purpose

Reserved date-grid primitive for future scheduling contexts without changing the current PRD screen model.

## Variants

- Month grid
- Week strip
- Agenda hybrid

## States

- Default
- Selected
- Disabled
- Range selected

## Properties

- selectedDate
- range
- events
- availability

## Sizing

- Compact strip
- Full month

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

- Standardized for the system but not currently mapped to a PRD-backed screen.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Use locale-aware week starts and labels
- Expose selected date textually

## Don't

- Introduce calendar-first flows where the architecture uses prompts
- Encode schedule status with color only

## Flutter Widget Mapping

- `TableCalendar, custom date strip`

## Figma Component Mapping

- `Calendar / Variant={Variant} / State={State}`
