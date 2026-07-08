# Achievement Components

- Status: `active`
- Used In: S-13, S-19, S-20, S-21, S-22

## Purpose

Non-competitive recognition for streaks, completions, and personal milestones.

## Variants

- Badge tile
- Milestone ribbon
- Completion summary
- Wallet item

## States

- Locked
- Earned
- Newly earned
- Viewed

## Properties

- title
- icon
- criteria
- earnedAt
- isNew

## Sizing

- Compact
- Standard

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

- Used in badge wallet, challenge completion, and supportive end-of-flow summaries.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Frame achievements as personal progress, not leaderboards
- Pair new awards with calm confirmation

## Don't

- Introduce public ranking or social comparison
- Use achievement visuals in crisis flows

## Flutter Widget Mapping

- `Card, badge wrappers, animated entry chip`

## Figma Component Mapping

- `Achievement / Variant={Variant} / State={State}`
