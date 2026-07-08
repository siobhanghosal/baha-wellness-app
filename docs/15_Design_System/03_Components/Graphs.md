# Graphs

- Status: `active`
- Used In: S-10, S-14, S-15, S-16, P-03, P-06, P-07, T-03, T-04, B-13

## Purpose

Relationship and multi-metric visualizations for insight detail, threshold trends, and operational comparisons.

## Variants

- Trend graph
- Relationship graph
- Comparative graph

## States

- Loading
- Empty
- Populated
- Filtered
- Error

## Properties

- axes
- legend
- series
- summary
- privacyMode

## Sizing

- Embedded
- Expanded detail

## Spacing

- Inner padding uses the global spacing scale, typically `space.3` to `space.6` depending on density.
- Component-to-component spacing follows layout rhythm rather than ad hoc margins.

## Accessibility

- Data components must pair visual information with textual summaries and preserve privacy thresholds.
- This component must meet WCAG 2.1 AA contrast requirements in both light and dark themes.

## Keyboard Behaviour

- Sortable tables and tabs must be traversable by keyboard with visible active state.

## Screen Reader Behaviour

- Narrative summaries, axis labels, and row or column headers must be exposed semantically.

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

- Used in detail-oriented trend and calibration screens where a chart alone is not sufficient.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Keep legends synchronized with the narrative explanation
- Use simplified labels for student surfaces

## Don't

- Expose raw point data where aggregation is required
- Animate graphs aggressively

## Flutter Widget Mapping

- `Custom graph widgets backed by charting primitives`

## Figma Component Mapping

- `Graph / Type={Type} / State={State}`
