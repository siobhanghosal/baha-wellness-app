# Charts

- Status: `active`
- Used In: S-10, S-14, S-15, S-16, P-03, P-06, P-07, T-03, T-04, B-13

## Purpose

Quantitative, plain-language visual summaries for trends, cohort views, and analytics dashboards.

## Variants

- Line
- Bar
- Stacked bar
- Sparkline

## States

- Loading
- Empty
- Populated
- Filtered
- Error

## Properties

- title
- timeRange
- series
- annotations
- narrativeSummary

## Sizing

- Card chart
- Full-width chart

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

- Used for student trend cards, parent summaries, teacher class dashboards, and BAHA pilot analytics.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Pair every chart with plain-language interpretation
- Respect privacy thresholds before rendering data

## Don't

- Use charts without text alternatives
- Show diagnostic or stigmatizing labels

## Flutter Widget Mapping

- `CustomPaint, fl_chart, syncfusion_flutter_charts, semantic summary wrapper`

## Figma Component Mapping

- `Chart / Type={Type} / State={State}`
