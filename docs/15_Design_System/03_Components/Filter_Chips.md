# Filter Chips

- Status: `active`
- Used In: T-07, B-01, B-02, B-07, B-08, B-09, B-14, B-15, B-16

## Purpose

Quick multi-state filtering and lightweight option toggling.

## Variants

- Assist chip
- Single-select filter chip
- Multi-select chip
- Input chip

## States

- Rest
- Selected
- Focused
- Disabled

## Properties

- label
- icon
- selected
- count

## Sizing

- sm
- md

## Spacing

- Inner padding uses the global spacing scale, typically `space.3` to `space.6` depending on density.
- Component-to-component spacing follows layout rhythm rather than ad hoc margins.

## Accessibility

- Input components must provide labels, helper text, validation feedback, and semantic grouping.
- This component must meet WCAG 2.1 AA contrast requirements in both light and dark themes.

## Keyboard Behaviour

- Tab advances focus, Shift+Tab reverses, arrow keys adjust grouped controls where applicable, and Escape dismisses attached menus or sheets.

## Screen Reader Behaviour

- Screen readers announce label, required state, current value, helper text, and validation errors.

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

- Used in dashboards, queues, libraries, and search-result refinements.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Expose selected state clearly in text and color
- Keep filter groups horizontally or vertically scroll-safe

## Don't

- Hide critical filters in chips only when counts are large
- Use long sentence labels

## Flutter Widget Mapping

- `FilterChip, ChoiceChip, InputChip`

## Figma Component Mapping

- `Filter Chip / Type={Type} / State={State}`
