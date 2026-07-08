# Video Card

- Status: `active`
- Used In: S-25, S-26, S-27, P-09, P-10, T-09, T-10

## Purpose

Video content summary and launch treatment for lesson modules and reviewed BAHA content.

## Variants

- Thumbnail card
- In-progress video
- Completed video

## States

- Rest
- Pressed
- Loading
- Completed

## Properties

- thumbnail
- title
- duration
- progress
- captionAvailability

## Sizing

- Standard
- Hero

## Spacing

- Inner padding uses the global spacing scale, typically `space.3` to `space.6` depending on density.
- Component-to-component spacing follows layout rhythm rather than ad hoc margins.

## Accessibility

- Media components must expose captions, transcript access, and clear playback state.
- This component must meet WCAG 2.1 AA contrast requirements in both light and dark themes.

## Keyboard Behaviour

- Playback controls must support Space, Enter, and arrow key seeking where relevant.

## Screen Reader Behaviour

- Playback state, duration, and caption availability are announced accessibly.

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

- Used in lesson view and learning content summaries where video is an approved modality.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Show duration and caption availability
- Use clear play affordances

## Don't

- Use motion thumbnails that distract from wellbeing context
- Hide progress state across sessions

## Flutter Widget Mapping

- `Card, Stack, AspectRatio, playback launch action`

## Figma Component Mapping

- `Video Card / State={State}`
