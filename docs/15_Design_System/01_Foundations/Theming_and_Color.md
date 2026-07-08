# Theming and Color

## Color Palette

| Family | Light | Dark | Purpose |
|---|---|---|---|
| Primary trust | `#155EEF` | `#84ADFF` | Main actions and active states |
| Secondary calm | `#0F766E` | `#5EEAD4` | Wellness, guidance, supportive actions |
| Warm neutral | `#F8F6F2` | `#1B1E23` | Canvas and restful backgrounds |
| Ink neutral | `#101828` | `#F5F7FA` | Primary text |
| Success | `#127A4B` | `#6CE9A6` | Completion and saved state |
| Warning | `#B54708` | `#FEC84B` | Advisory caution |
| Danger | `#B42318` | `#FDA29B` | High-risk or destructive states |
| Information | `#175CD3` | `#84CAFF` | Explanatory banners and info states |

## Light Theme

- Canvas uses warm neutrals rather than pure white to reduce glare on student and parent surfaces.
- Cards stay slightly elevated with low shadow and strong text contrast.
- BAHA tables use cooler neutral rows to improve scanability at density.

## Dark Theme

- Dark mode preserves calm contrast and avoids saturated neon tones.
- Student achievement surfaces remain warm but muted to avoid over-stimulation.
- Charts switch to high-legibility semantic strokes and labels with a stronger focus ring.

## Semantic Colors

| Token | Light | Dark | Usage |
|---|---|---|---|
| `color.text.primary` | `#101828` | `#F5F7FA` | Primary content |
| `color.text.secondary` | `#475467` | `#CDD5DF` | Supporting copy |
| `color.surface.canvas` | `#F8F6F2` | `#101318` | App background |
| `color.surface.card` | `#FFFFFF` | `#161B22` | Cards and sheets |
| `color.border.default` | `#D0D5DD` | `#344054` | Inputs and dividers |
| `color.focus.ring` | `#84ADFF` | `#B2CCFF` | Focus visibility |

## Feedback Colors

| State | Background | Foreground | Border |
|---|---|---|---|
| Success | `#ECFDF3` | `#127A4B` | `#ABEFC6` |
| Warning | `#FFFAEB` | `#B54708` | `#FEDF89` |
| Danger | `#FEF3F2` | `#B42318` | `#FECDCA` |
| Information | `#EFF8FF` | `#175CD3` | `#B2DDFF` |
| Neutral | `#F2F4F7` | `#344054` | `#D0D5DD` |

## Role Color Notes

- Student surfaces emphasize calm secondary tones, rounded containers, and low-danger saturation until escalation states are explicit.
- Parent surfaces use higher clarity contrast and more explanatory information color.
- Teacher surfaces bias toward neutral analytics palettes with anonymization-safe severity coding.
- BAHA surfaces retain semantic severity color while avoiding red overload in dense operational contexts.
