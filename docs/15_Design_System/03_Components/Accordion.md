# Accordion

- Status: `active`
- Used In: S-36, P-13, T-12, B-17

## Purpose

Expandable disclosure for guides, policies, FAQs, and grouped metadata.

## Variants

- Single expand
- Multi expand
- Nested section

## States

- Collapsed
- Expanded
- Disabled

## Properties

- title
- summary
- content
- defaultExpanded

## Sizing

- Standard row
- Card section

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

- Used in conversation guides, help content, settings, and policy detail surfaces.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Use concise section titles with short summaries
- Remember expansion state where it helps comparison

## Don't

- Hide mission-critical safety instructions inside deeply collapsed sets
- Mix unrelated tasks in one accordion

## Flutter Widget Mapping

- `ExpansionTile, ExpansionPanelList`

## Figma Component Mapping

- `Accordion / State={State}`
