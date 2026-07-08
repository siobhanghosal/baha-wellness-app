# Navigation

## Top-Level Structure

- Dashboard
- Pastoral Input
- Referrals
- Learn
- Settings

## Navigation Rules

- first-run routing must honor authentication state and consent state before the app shell appears
- users may deep-link only into views allowed by their current permissions and data availability
- emergency or override notifications can interrupt the normal flow but must preserve a return path
- offline states may expose cached screens but never bypass policy gates

## Deep-Link and Routing Map

| Route Group | Purpose | Guard |
|---|---|---|
| onboarding | profile setup, consent, privacy promise | unauthenticated or incomplete setup only |
| home | main role dashboard | active session plus completed consent/training gate |
| content | learning modules, detail, progress | role and audience filtered |
| support | alerts, help, referrals, cases | role-specific permissions |
| settings | notification, privacy, data rights | authenticated role |

## Mermaid Reference

- [Mermaid/navigation.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/05_Teacher_App/Mermaid/navigation.mmd)
