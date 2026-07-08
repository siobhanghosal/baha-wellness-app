# Stepper

- Status: `active`
- Used In: S-01, S-02, S-03, S-04, S-05, S-06, S-07, S-08, S-09, S-11, S-12, S-13

## Purpose

Progress cue for onboarding, consent, and check-in sequences.

## Variants

- Linear stepper
- Dot stepper
- Progress ribbon

## States

- Upcoming
- Current
- Completed
- Blocked

## Properties

- steps
- currentIndex
- allowBacktracking

## Sizing

- Compact mobile
- Standard mobile

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

- Used in guided flows where the architecture already defines an ordered path.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Expose current position and remaining scope
- Keep labels short and age-appropriate on student flows

## Don't

- Treat optional branching as fixed completed steps
- Use stepper chrome on single-screen tasks

## Flutter Widget Mapping

- `Stepper, custom progress indicator with step semantics`

## Figma Component Mapping

- `Stepper / Type={Type} / State={State}`
