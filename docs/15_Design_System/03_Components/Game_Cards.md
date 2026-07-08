# Game Cards

- Status: `active`
- Used In: S-20, S-21, S-22, S-23, S-24

## Purpose

Entry and state container for guided wellbeing games and calming activities.

## Variants

- Hub card
- Scenario card
- Resume card
- Regulation card

## States

- Rest
- Pressed
- Completed
- Time capped
- Locked

## Properties

- title
- summary
- estimatedTime
- status
- cta

## Sizing

- Standard
- Wide

## Spacing

- Inner padding uses the global spacing scale, typically `space.3` to `space.6` depending on density.
- Component-to-component spacing follows layout rhythm rather than ad hoc margins.

## Accessibility

- Display components must clarify hierarchy and should never conceal critical status information.
- This component must meet WCAG 2.1 AA contrast requirements in both light and dark themes.

## Keyboard Behaviour

- Interactive wrappers such as cards or rows must expose button or link semantics; non-interactive display remains out of the tab order.

## Screen Reader Behaviour

- Screen readers announce heading, supporting text, status, and action affordances in reading order.

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

- Used in Games Hub and game-specific routes including breathing and scenario-based activities.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Keep descriptions supportive rather than competitive
- Show time expectations up front

## Don't

- Use manipulative gamification around distress
- Confuse calm activities with achievement-heavy visuals

## Flutter Widget Mapping

- `Custom card composition with Card, badges, buttons, and progress indicators`

## Figma Component Mapping

- `Game Card / Variant={Variant} / State={State}`
