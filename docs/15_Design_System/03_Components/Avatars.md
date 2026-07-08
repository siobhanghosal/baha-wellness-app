# Avatars

- Status: `active`
- Used In: S-33, P-03

## Purpose

Person or role marker for linked students, assigned staff, and conversational context.

## Variants

- Initials
- Illustrated
- Role icon
- Group stack

## States

- Default
- Selected
- Status overlaid

## Properties

- image
- fallbackInitials
- statusBadge
- size

## Sizing

- 24
- 32
- 40
- 56

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

- Used in linked-student summaries, case assignment, notification rows, and chat surfaces.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Provide a neutral fallback when no profile image exists
- Keep student identity exposure minimized by context

## Don't

- Display unnecessary personal imagery in operational tables
- Use avatars as the only label

## Flutter Widget Mapping

- `CircleAvatar, Stack, custom status avatar wrapper`

## Figma Component Mapping

- `Avatar / Type={Type} / Size={Size}`
