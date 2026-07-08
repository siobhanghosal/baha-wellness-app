# Tabs

- Status: `active`
- Used In: T-03, T-04, T-05, T-06, T-07, T-08, T-09, T-10, T-11, T-12, T-13, T-14

## Purpose

Parallel view switching for trend ranges, content states, notification buckets, and queue slices.

## Variants

- Fixed
- Scrollable
- Segmented tabs

## States

- Default
- Selected
- Focused
- Disabled
- Badge visible

## Properties

- items
- selectedIndex
- badgeCount
- isScrollable

## Sizing

- Compact
- Standard

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

- Used on teacher analytics, BAHA moderation, and any multi-view surface explicitly supported by the architecture.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Limit tabs to sibling content views
- Retain filter context when changing tabs

## Don't

- Use tabs for sequential workflow steps
- Hide tabs behind horizontal-only affordances without labels

## Flutter Widget Mapping

- `TabBar, SegmentedButton, custom chips-as-tabs`

## Figma Component Mapping

- `Tabs / Type={Type} / State={State}`
