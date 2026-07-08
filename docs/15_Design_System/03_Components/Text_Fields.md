# Text Fields

- Status: `active`
- Used In: S-30, S-37, P-02, T-05, T-06, B-04, B-05, B-08, B-11

## Purpose

Single-line text capture for notes, IDs, search-adjacent filtering, and operational metadata.

## Variants

- Outlined
- Filled
- Read-only
- Validated

## States

- Empty
- Typing
- Focused
- Error
- Disabled
- Read-only

## Properties

- label
- value
- placeholder
- helperText
- errorText
- prefix
- suffix
- maxLength

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

- Used in pastoral notes, case actions, guardian verification, content metadata, and support requests.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Pair fields with visible labels and helper text
- Validate close to the point of entry

## Don't

- Rely on placeholder text as the only label
- Use free text where a safer constrained input exists

## Flutter Widget Mapping

- `TextField, TextFormField, custom BahaTextField`

## Figma Component Mapping

- `Text Field / Variant={Variant} / State={State}`
