# Slider

- Status: `active`
- Used In: S-12, S-17

## Purpose

Graduated scalar input for wellbeing check-ins, threshold tuning, and advisory calibration.

## Variants

- Continuous
- Discrete
- Range

## States

- Idle
- Dragging
- Focused
- Disabled
- Error

## Properties

- label
- value
- min
- max
- divisions
- assistiveText

## Sizing

- Full-width control

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

- Used in student check-ins and BAHA threshold configuration where a bounded continuum is defined by the architecture.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Show the current selected value in plain language
- Use discrete marks when the policy model expects buckets

## Don't

- Use sliders where exact numeric text entry is required
- Hide semantic meaning behind unlabeled scales

## Flutter Widget Mapping

- `Slider, RangeSlider`

## Figma Component Mapping

- `Slider / Type={Type} / State={State}`
