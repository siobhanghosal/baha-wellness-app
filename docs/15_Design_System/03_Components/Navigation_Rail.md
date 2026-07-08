# Navigation Rail

- Status: `active`
- Used In: B-01, B-02, B-03, B-04, B-05, B-06, B-07, B-08, B-09, B-10, B-11, B-12

## Purpose

Persistent left-side navigation for denser BAHA operations and tablet-like teacher contexts.

## Variants

- Collapsed
- Expanded
- Badge-enabled

## States

- Default
- Selected
- Disabled

## Properties

- items
- selectedIndex
- isExpanded
- badges

## Sizing

- 72 collapsed
- 256 expanded

## Spacing

- Inner padding uses the global spacing scale, typically `space.3` to `space.6` depending on density.
- Component-to-component spacing follows layout rhythm rather than ad hoc margins.

## Accessibility

- Navigation components must preserve orientation, announce current location, and avoid surprising route changes.
- This component must meet WCAG 2.1 AA contrast requirements in both light and dark themes.

## Keyboard Behaviour

- Arrow keys move within grouped nav controls, Home and End jump when supported, and Enter activates the selected destination.

## Screen Reader Behaviour

- Screen readers announce the route or destination name plus selected state when applicable.

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

- Primary workspace navigation for BAHA operational screens and a responsive fallback for larger canvases.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Use icons plus labels when space allows
- Keep operational destinations in a consistent order

## Don't

- Swap rail order between sibling screens
- Replace critical filters with rail nesting

## Flutter Widget Mapping

- `NavigationRail, custom responsive shell wrapper`

## Figma Component Mapping

- `Navigation Rail / Density={Density} / State={State}`
