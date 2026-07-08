# Icon Buttons

- Status: `active`
- Used In: Not currently used by a PRD-backed screen.

## Purpose

Compact affordances for search, close, info, retry, and contextual utility actions.

## Variants

- Standard
- Filled
- Tonal
- Destructive
- Toggle

## States

- Rest
- Hovered
- Pressed
- Focused
- Disabled
- Selected

## Properties

- icon
- label
- isToggle
- isSelected
- tone

## Sizing

- 40
- 48

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

- Used in app bars, charts, list rows, media controls, and dialogs.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Provide an accessible label on every icon-only action
- Keep hit areas square and thumb-safe

## Don't

- Use icon-only controls for irreversible actions without confirmation
- Stack dense icon clusters on student screens

## Flutter Widget Mapping

- `IconButton, FilledIconButton, custom selectable icon button`

## Figma Component Mapping

- `Icon Button / Style={Style} / State={State}`
