# Password Fields

- Status: `reserved`
- Used In: Not currently used by a PRD-backed screen.

## Purpose

Reserved secure text entry primitive for platform auth surfaces outside the current PRD-backed screen set.

## Variants

- Masked
- Visible
- Validated

## States

- Empty
- Typing
- Focused
- Error
- Disabled

## Properties

- label
- value
- obscureText
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

- Standardized for future authentication contexts; not currently used in the 88-screen repository.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Offer a reveal toggle and strong error messaging
- Respect secure autofill and password managers

## Don't

- Display raw values by default
- Block paste in managed operational environments

## Flutter Widget Mapping

- `TextFormField with obscureText and reveal toggle`

## Figma Component Mapping

- `Password Field / State={State}`
