# Cards

- Status: `active`
- Used In: S-01, S-02, S-04, S-10, S-11, S-12, S-13, S-14, S-15, S-16, S-17, S-18

## Purpose

Default bounded content container for summaries, actions, insights, and feature entry points.

## Variants

- Summary
- Action
- Insight
- Status
- Elevated

## States

- Rest
- Pressed
- Selected
- Disabled
- Loading

## Properties

- headline
- body
- media
- metadata
- cta
- status

## Sizing

- Compact
- Standard
- Full-width

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

- The base container for dashboard summaries, modules, games, policy blocks, and list summaries.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Use one clear hierarchy inside each card
- Keep tap and non-tap cards visually distinct

## Don't

- Nest multiple full action areas in one card
- Use card styling for dense tables

## Flutter Widget Mapping

- `Card, Material, InkWell, custom BahaCard composition`

## Figma Component Mapping

- `Card / Variant={Variant} / State={State}`
