# Data Table

- Status: `active`
- Used In: T-07, B-01, B-02, B-07, B-09, B-15, B-16

## Purpose

Dense multi-column operational data view for BAHA and select teacher/admin contexts.

## Variants

- Standard table
- Sticky header table
- Selectable rows table

## States

- Loading
- Empty
- Populated
- Sorted
- Filtered

## Properties

- columns
- rows
- sortState
- selectionState
- pagination

## Sizing

- Desktop
- Tablet responsive

## Spacing

- Inner padding uses the global spacing scale, typically `space.3` to `space.6` depending on density.
- Component-to-component spacing follows layout rhythm rather than ad hoc margins.

## Accessibility

- Data components must pair visual information with textual summaries and preserve privacy thresholds.
- This component must meet WCAG 2.1 AA contrast requirements in both light and dark themes.

## Keyboard Behaviour

- Sortable tables and tabs must be traversable by keyboard with visible active state.

## Screen Reader Behaviour

- Narrative summaries, axis labels, and row or column headers must be exposed semantically.

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

- Used in support queues, content review, audit logs, and user management surfaces.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Expose column sort and status clearly
- Preserve row identity during refreshes

## Don't

- Force tables onto narrow student mobile screens
- Hide critical actions inside ambiguous row menus

## Flutter Widget Mapping

- `DataTable, PaginatedDataTable, custom sliver table`

## Figma Component Mapping

- `Data Table / Variant={Variant} / State={State}`
