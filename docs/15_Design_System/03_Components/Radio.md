# Radio

- Status: `active`
- Used In: S-02, S-04, S-12, S-17, T-02

## Purpose

Mutually exclusive choice sets for consent, age bands, gender preference, and explicit mode selection.

## Variants

- List radio
- Card radio
- Segmented radio

## States

- Unchecked
- Checked
- Focused
- Disabled
- Error

## Properties

- label
- supportingText
- value
- groupValue

## Sizing

- Default control
- Card control

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

- Used in onboarding and policy choices where the user must select exactly one safe option.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Present all exclusive options together
- Explain policy-impacting choices in supporting text

## Don't

- Hide mutually exclusive choices inside multiple taps
- Mix radios and checkboxes for the same question

## Flutter Widget Mapping

- `RadioListTile, SegmentedButton, custom selectable card`

## Figma Component Mapping

- `Radio / Type={Type} / State={State}`
