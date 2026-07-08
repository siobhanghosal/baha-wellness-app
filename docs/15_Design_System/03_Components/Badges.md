# Badges

- Status: `active`
- Used In: S-19

## Purpose

Compact status, count, and achievement labeling.

## Variants

- Count
- Status
- Achievement
- Severity

## States

- Default
- Emphasized
- Muted

## Properties

- label
- count
- tone
- icon

## Sizing

- sm
- md

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

- Used for streaks, moderation counts, case statuses, and role notifications.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Use short labels and semantic color tokens
- Pair non-text badges with accessible names

## Don't

- Rely on color alone to convey meaning
- Expose sensitive severity labels in student contexts

## Flutter Widget Mapping

- `Badge, Container with tokenized decoration`

## Figma Component Mapping

- `Badge / Tone={Tone} / State={State}`
