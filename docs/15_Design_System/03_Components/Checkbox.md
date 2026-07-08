# Checkbox

- Status: `active`
- Used In: S-12, S-17, S-33, S-37, P-02, P-12, T-05, T-06, T-13, B-04, B-05, B-08

## Purpose

Independent opt-ins for review checklists, policy acknowledgements, and content tagging.

## Variants

- Standalone
- Checkbox row
- Checkbox group

## States

- Unchecked
- Checked
- Indeterminate
- Focused
- Disabled
- Error

## Properties

- label
- supportingText
- value
- triState

## Sizing

- Default control

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

- Used for acknowledgements, moderation steps, and multi-select filter scenarios.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Keep labels concise and explicit
- Use groups when multiple selections are valid

## Don't

- Use checkboxes for single-choice questions
- Hide required acknowledgements below the fold

## Flutter Widget Mapping

- `Checkbox, CheckboxListTile`

## Figma Component Mapping

- `Checkbox / State={State}`
