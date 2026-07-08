# Layout Foundations

## Grid System

| Surface | Grid | Gutters | Notes |
|---|---|---:|---|
| Student mobile | 4-column | 16 | Prioritizes thumb reach and short card stacks |
| Parent mobile | 4-column | 16 | Balances summary density and readability |
| Teacher tablet/mobile | 8-column adaptive | 16 to 24 | Supports chart plus list pairings |
| BAHA desktop/tablet | 12-column adaptive | 24 | Supports rail, table, and detail compositions |

## Responsive Breakpoints

| Token | Width | Usage |
|---|---:|---|
| `bp.xs` | 0 | Narrow phones |
| `bp.sm` | 360 | Standard phones |
| `bp.md` | 600 | Large phone or portrait tablet |
| `bp.lg` | 840 | Landscape tablet |
| `bp.xl` | 1200 | Desktop and BAHA operations |
| `bp.xxl` | 1440 | Wide analytics workspace |

## Column Layouts

- Student and parent surfaces default to single-column content with optional 2-up cards at `bp.md`.
- Teacher analytics surfaces allow 2-column content at `bp.lg`, with filters staying sticky above charts.
- BAHA operations use a persistent left rail plus 2 or 3-column workspace splits at `bp.xl`.

## Container Widths

| Container | Max Width |
|---|---:|
| Reading container | 720 |
| Standard app content | 960 |
| Analytics workspace | 1280 |
| Full operations canvas | 1440 |

## Safe Areas

- Respect platform safe areas on every shell and overlay.
- Student and parent bottom navigation must reserve home-indicator or gesture inset space.
- BAHA desktop layouts reserve room for browser chrome and sticky utility bars.
- Snackbar and bottom-sheet anchors must sit above bottom navigation and keyboard insets.
