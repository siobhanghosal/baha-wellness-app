# Flutter Routing

## Client Strategy

- one shared Flutter monorepo or package workspace
- separate app entrypoints for Student, Parent, Teacher, and BAHA
- shared core packages for auth, design tokens, networking, and policy-aware models

## Route Layers

1. bootstrap routes
2. gating routes
3. shell routes
4. feature routes
5. interrupt routes for alerts and emergency states

## Student Route Example

- /launch
- /welcome
- /age-band
- /consent
- /home
- /check-in
- /buddy
- /learn
- /games
- /profile
- /help

## Guards

- auth guard
- consent guard
- training guard
- role guard
- feature availability guard
- connectivity-aware content guard
