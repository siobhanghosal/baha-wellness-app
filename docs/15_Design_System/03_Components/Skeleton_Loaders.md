# Skeleton Loaders

- Status: `active`
- Used In: S-00, P-00, T-00, B-00

## Purpose

Geometry-preserving loading placeholders for cards, lists, charts, and detail surfaces.

## Variants

- Card skeleton
- List skeleton
- Chart skeleton
- Detail skeleton

## States

- Visible
- Fading out

## Properties

- shapeModel
- lineCount
- showMediaSlot

## Sizing

- Contextual to parent component

## Spacing

- Inner padding uses the global spacing scale, typically `space.3` to `space.6` depending on density.
- Component-to-component spacing follows layout rhythm rather than ad hoc margins.

## Accessibility

- Feedback components must match severity to context and manage focus when they interrupt the user.
- This component must meet WCAG 2.1 AA contrast requirements in both light and dark themes.

## Keyboard Behaviour

- Dialogs trap focus, snackbars expose action shortcuts when present, and dismiss actions are keyboard reachable.

## Screen Reader Behaviour

- Urgent or blocking feedback uses alert semantics; transient feedback avoids excessive interruption.

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

- Used on any live-data surface expected to resolve within one round-trip.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Match final layout geometry closely
- Respect reduced-motion preferences

## Don't

- Show skeletons for long offline errors
- Swap to completely different loaded layouts

## Flutter Widget Mapping

- `Shimmer or custom animated placeholder widgets`

## Figma Component Mapping

- `Skeleton / Variant={Variant}`
