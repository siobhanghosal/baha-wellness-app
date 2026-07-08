# Learning Cards

- Status: `active`
- Used In: S-25, S-26, S-27, S-28, P-09, P-10, T-09, T-10

## Purpose

Course, module, and lesson entry points with duration, progress, and modality metadata.

## Variants

- Featured module
- Standard module
- Completed module
- Recommended lesson

## States

- Rest
- Pressed
- Completed
- Locked
- Loading

## Properties

- title
- summary
- duration
- modality
- progress
- cta

## Sizing

- Compact
- Standard
- Hero

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

- Used in student, parent, and teacher learning homes plus module detail lists.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Surface duration and effort before entry
- Use completion status consistently across roles

## Don't

- Hide required module gating
- Mix multiple progress systems in one card

## Flutter Widget Mapping

- `Custom card composition built on Card, LinearProgressIndicator, chips, and InkWell`

## Figma Component Mapping

- `Learning Card / Variant={Variant} / State={State}`
