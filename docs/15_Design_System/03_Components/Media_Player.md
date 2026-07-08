# Media Player

- Status: `active`
- Used In: S-23, S-25, S-26, S-27, P-09, P-10, T-09, T-10

## Purpose

Playback control surface for audio-guided lessons, calming exercises, and approved media content.

## Variants

- Inline audio
- Expanded player
- Transcript-aware player

## States

- Idle
- Playing
- Paused
- Buffering
- Completed
- Error

## Properties

- title
- duration
- progress
- captions
- transcript
- speed

## Sizing

- Inline
- Card
- Full-width

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

- Used in lesson view, audio cards, calm breathing, and approved content playback.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Support captions or transcripts where media is instructional
- Keep controls large enough for motor accessibility

## Don't

- Autoplay audio in sensitive contexts
- Hide playback state from assistive technology

## Flutter Widget Mapping

- `video_player, just_audio, custom controller widgets`

## Figma Component Mapping

- `Media Player / State={State}`
