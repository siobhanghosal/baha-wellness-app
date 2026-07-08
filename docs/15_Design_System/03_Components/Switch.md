# Switch

- Status: `active`
- Used In: S-09, S-33, P-12, T-13

## Purpose

Immediate on-off settings for reminders, preferences, and non-destructive operational toggles.

## Variants

- Default
- With helper text
- Disabled

## States

- Off
- On
- Focused
- Disabled
- Updating

## Properties

- label
- supportingText
- isOn
- isLoading

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

- Used in notification settings, privacy settings, and optional personalization controls.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Apply immediate optimistic feedback with rollback on failure
- Describe the effect of enabling the setting

## Don't

- Use switches for multi-step consent changes
- Place multiple destructive toggles adjacent without grouping

## Flutter Widget Mapping

- `Switch, SwitchListTile, custom async preference tile`

## Figma Component Mapping

- `Switch / State={State}`
