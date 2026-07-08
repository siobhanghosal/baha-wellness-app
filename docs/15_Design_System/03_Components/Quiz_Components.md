# Quiz Components

- Status: `active`
- Used In: S-28

## Purpose

Question, answer, explanation, and reflection primitives for formative learning checks.

## Variants

- Single select
- Multi select
- Reflection prompt
- Completion summary

## States

- Unanswered
- Answered
- Validated
- Review
- Completed

## Properties

- question
- answers
- feedback
- progress
- isRequired

## Sizing

- Card
- Stacked flow

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

- Used in student quiz and reflection plus module comprehension across role learning tracks.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Provide supportive explanations after submission
- Keep scoring low-stakes and non-punitive

## Don't

- Use gamified shame states for incorrect responses
- Mix unrelated question types in one dense panel

## Flutter Widget Mapping

- `PageView or sliver stack of cards, RadioListTile, CheckboxListTile, TextField`

## Figma Component Mapping

- `Quiz / Type={Type} / State={State}`
