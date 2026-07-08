# List Rows

- Status: `active`
- Used In: S-33, S-36, P-09, P-12, T-09, T-12, T-13, B-07, B-08, B-09, B-14, B-16

## Purpose

Dense repeated rows for settings, resources, modules, notifications, and option lists.

## Variants

- Plain row
- Chevron row
- Selectable row
- Metadata row

## States

- Rest
- Pressed
- Selected
- Disabled

## Properties

- title
- subtitle
- leading
- trailing
- status

## Sizing

- Single-line
- Two-line
- Three-line

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

- Used in help centers, settings, content lists, resources, queues, and notification feeds.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Keep row interaction zones predictable
- Use metadata rows for timestamps and statuses

## Don't

- Pack too many controls into one row
- Use chevrons on non-navigating rows

## Flutter Widget Mapping

- `ListTile, InkWell row, custom slotted row widget`

## Figma Component Mapping

- `List Row / Variant={Variant} / State={State}`
