# Dropdown

- Status: `active`
- Used In: S-37, T-05, T-06, B-04, B-05, B-08, B-11, B-16

## Purpose

Constrained selection for filters, school scopes, statuses, tags, and review states.

## Variants

- Single select
- Grouped select
- Icon-leading select

## States

- Closed
- Open
- Selected
- Error
- Disabled

## Properties

- label
- selectedOption
- options
- helperText
- errorText

## Sizing

- md
- lg

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

- Used for queue filters, content tags, threshold settings, and learning sort controls.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Use for stable option sets with short labels
- Mirror current selection in the collapsed field

## Don't

- Use dropdowns for binary choices
- Hide destructive consequences in option text

## Flutter Widget Mapping

- `DropdownMenu, MenuAnchor, custom bottom-sheet picker on mobile`

## Figma Component Mapping

- `Dropdown / State={State} / Density={Density}`
