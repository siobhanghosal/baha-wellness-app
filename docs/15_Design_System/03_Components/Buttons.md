# Buttons

- Status: `active`
- Used In: S-01, S-02, S-03, S-04, S-05, S-06, S-07, S-08, S-09, S-20, S-21, S-22

## Purpose

Primary and secondary action triggers for progression, confirmation, retry, and safe exits.

## Variants

- Primary
- Secondary
- Tertiary
- Destructive
- Inline

## States

- Rest
- Pressed
- Focused
- Disabled
- Loading
- Success

## Properties

- label
- leadingIcon
- trailingIcon
- tone
- isLoading
- fullWidth

## Sizing

- sm
- md
- lg

## Spacing

- Inner padding uses the global spacing scale, typically `space.3` to `space.6` depending on density.
- Component-to-component spacing follows layout rhythm rather than ad hoc margins.

## Accessibility

- Action components must expose clear pressed, disabled, and loading feedback while preserving safe tap targets.
- This component must meet WCAG 2.1 AA contrast requirements in both light and dark themes.

## Keyboard Behaviour

- Reachable by Tab, activatable with Enter or Space, and must preserve visible focus.

## Screen Reader Behaviour

- Screen readers announce the control label, current availability, and loading state.

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

- Used across onboarding, check-in, learning, help, moderation, and export workflows.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Use one clear primary action per region
- Use destructive tone only for irreversible actions

## Don't

- Place multiple primary buttons in one card
- Hide required progress behind tertiary-only buttons

## Flutter Widget Mapping

- `FilledButton, OutlinedButton, TextButton, custom BahaButton wrapper`

## Figma Component Mapping

- `Button / Emphasis={Type} / Size={Size} / State={State}`
