# Floating Action Button

- Status: `reserved`
- Used In: Not currently used by a PRD-backed screen.

## Purpose

Reserved high-emphasis floating action for future operational acceleration without changing current PRD flows.

## Variants

- Primary FAB
- Extended FAB

## States

- Rest
- Pressed
- Focused
- Hidden
- Disabled

## Properties

- icon
- label
- isExtended

## Sizing

- 56
- 80 extended

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

- Documented as a design-system primitive but not currently instantiated in the 88-screen repository.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Use only for a single dominant contextual action
- Hide during full-screen tasks or overlays

## Don't

- Introduce FABs into consent or crisis flows
- Use multiple FABs on one screen

## Flutter Widget Mapping

- `FloatingActionButton, FloatingActionButton.extended`

## Figma Component Mapping

- `FAB / Type={Type} / State={State}`
