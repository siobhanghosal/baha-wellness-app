# Bottom Navigation

- Status: `active`
- Used In: S-10, S-11, S-12, S-13, S-14, S-15, S-16, S-17, S-18, S-19, S-20, S-21

## Purpose

Stable primary navigation for mobile role surfaces.

## Variants

- Student five-tab
- Parent four-tab

## States

- Default
- Selected
- Disabled
- Badge visible

## Properties

- items
- selectedIndex
- badges
- safeAreaInset

## Sizing

- 56 to 80 height depending safe area

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

- Used on student and parent top-level routes after bootstrap and onboarding gates.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Keep labels short and persistent
- Use badges for non-urgent counts only

## Don't

- Place more than five destinations
- Hide active state on role home screens

## Flutter Widget Mapping

- `NavigationBar, BottomNavigationBar`

## Figma Component Mapping

- `Bottom Navigation / Role={Role} / State={State}`
