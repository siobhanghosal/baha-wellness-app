# Authentication

## Scope

- Splash bootstrap
- Role resolution
- Session refresh
- Consent gate handoff
- Session expiry redirect

## Component Stack

- App Shell
- Top Navigation
- Progress Indicators
- Status Banners
- Dialogs

## Rules

- Keep first-launch and returning-user bootstrap visually consistent across roles.
- Route to the next valid screen using the Phase 3 routing table rather than branching inside component state.
- Session expiry must interrupt sensitive workflows with a dialog, preserve non-sensitive drafts when allowed, and redirect to the correct splash route.
