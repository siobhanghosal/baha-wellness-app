# App Shell

- Status: `active`
- Used In: S-00, S-01, S-02, S-03, S-04, S-05, S-06, S-07, S-08, S-09, S-10, S-11

## Purpose

Provides the shared scaffold for each role surface, including safe areas, shell navigation, banners, and content containers.

## Variants

- Student mobile shell
- Parent mobile shell
- Teacher adaptive shell
- BAHA operations workspace

## States

- Default
- Loading
- Offline
- Maintenance
- Session expired

## Properties

- role
- title
- navigationModel
- bannerSlot
- contentSlot
- footerSlot

## Sizing

- Full-screen only

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

- Used on every route after bootstrap and adapted for desktop-like BAHA workspaces versus mobile-first student surfaces.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Keep role navigation stable across sibling screens
- Reserve topmost banner space for privacy or support messages

## Don't

- Rebuild shell structure inside each screen
- Place destructive actions in shell chrome

## Flutter Widget Mapping

- `Scaffold, SafeArea, NavigationBar, NavigationRail, CustomScrollView, SliverAppBar`

## Figma Component Mapping

- `App Shell / Role={Role} / Density={Mode} / State={State}`
