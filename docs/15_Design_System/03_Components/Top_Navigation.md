# Top Navigation

- Status: `active`
- Used In: S-00, S-01, S-02, S-03, S-04, S-05, S-06, S-07, S-08, S-09, S-10, S-11

## Purpose

Provides route title, back navigation, contextual actions, and high-priority utility entry points.

## Variants

- Plain app bar
- Search app bar
- Large title
- Operational metadata bar

## States

- Default
- Scrolled
- Loading
- Alert active

## Properties

- title
- leadingAction
- trailingActions
- subtitle
- bannerSlot

## Sizing

- 56
- 64
- Large title expanded

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

- Used on all roles for page identity, safe back behavior, and route-level actions.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Use a clear title that matches the route contract
- Keep support and info actions consistent within a role

## Don't

- Overload app bars with secondary actions
- Use hidden gesture-only navigation controls

## Flutter Widget Mapping

- `AppBar, SliverAppBar, PreferredSizeWidget variants`

## Figma Component Mapping

- `Top Navigation / Variant={Variant} / State={State}`
