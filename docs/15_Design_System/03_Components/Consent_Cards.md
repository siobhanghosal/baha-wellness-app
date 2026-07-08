# Consent Cards

- Status: `active`
- Used In: S-03, S-05, S-06, S-07, S-08, S-09, S-34, S-35, S-38, P-04, P-05, P-13

## Purpose

Purpose-built cards for consent scope, privacy tiers, and sharing boundaries.

## Variants

- Tier comparison
- Current status
- Override notice
- Pending state

## States

- Default
- Selected
- Pending
- Warning
- Locked

## Properties

- tierName
- summary
- visibilityRules
- status
- cta

## Sizing

- Standard
- Comparison column

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

- Used in privacy promise, consent setup, consent review, and override notification flows.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- State who can see what in plain language
- Use side-by-side comparison only when the architecture already calls for it

## Don't

- Bury safeguarding override rules in footnotes
- Expose hidden internal policy codes to guardians or students

## Flutter Widget Mapping

- `Custom card composition on top of Card, badges, and list rows`

## Figma Component Mapping

- `Consent Card / Variant={Variant} / State={State}`
