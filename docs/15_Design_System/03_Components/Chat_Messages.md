# Chat Messages

- Status: `active`
- Used In: S-29, S-30, S-31, S-32, B-10

## Purpose

Conversational bubbles, quick replies, and citation-aware message blocks for Buddy chat.

## Variants

- User message
- Buddy reply
- Citation message
- Escalation prompt
- Out-of-scope message

## States

- Sending
- Delivered
- Failed
- Selected

## Properties

- author
- timestamp
- body
- citations
- actions

## Sizing

- Bubble
- Full-width system card

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

- Used in Buddy Chat, citation detail entry points, safe refusals, and escalation prompts.
- Prefer composition through shared slots and semantic tokens instead of one-off overrides.

## Do

- Distinguish user and assistant messages clearly
- Keep citation actions visible on supported replies

## Don't

- Animate messages aggressively
- Allow unreviewed rich content to break layout

## Flutter Widget Mapping

- `ListView, custom chat bubble widgets, markdown text renderer, citations row`

## Figma Component Mapping

- `Chat Message / Type={Type} / State={State}`
