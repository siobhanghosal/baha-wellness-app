# Navigation

## Top-Level Structure

- Home
- Check-In
- Buddy
- Learn
- Games
- Profile

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

- [Mermaid/navigation.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/03_Student_App/Mermaid/navigation.mmd)
