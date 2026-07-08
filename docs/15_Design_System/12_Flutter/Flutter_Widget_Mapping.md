# Flutter Widget Mapping

## Core Mapping Rules

- Start from Material 3 primitives, then wrap them in BAHA-specific widgets to enforce tokens, semantics, and analytics hooks.
- Route composition follows the Phase 3 routing table; widget composition follows the Phase 4 component catalog.

## Key Mappings

| Design System Component | Flutter Mapping |
|---|---|
| App Shell | `Scaffold` plus role shell wrapper |
| Top Navigation | `AppBar` or `SliverAppBar` |
| Bottom Navigation | `NavigationBar` |
| Navigation Rail | `NavigationRail` |
| Cards | `Card` plus BAHA slots |
| Learning Cards | Custom widget over `Card` and progress primitives |
| Chat Messages | Custom sliver or list bubble widgets |
| Data Table | `DataTable` or custom paginated table |
| Dialogs | `showAdaptiveDialog` and typed dialog wrappers |
| Bottom Sheets | `showModalBottomSheet` |
| Charts and Graphs | Charting library wrappers with semantic summaries |

## Implementation Notes

- Keep analytics, accessibility labels, and privacy redaction inside shared widgets where possible.
- Separate app-shell concerns from feature widgets so roles can evolve without component drift.
