# Privacy Findings

## Overall Assessment

Privacy is strongly represented in the BAHA documentation, but the prototype behavior does not yet embody the same level of discipline.

## Privacy Findings

| Finding | Related Issues | Evidence |
| --- | --- | --- |
| Role and permission boundaries are not enforced in routing | PRR-002 | Route files accept any known role and screen slug |
| Cross-role switching normalizes broad access | PRR-003 | App shell allows rapid hopping across role views |
| Prototype state persists locally | PRR-007 | `lib/prototype-store.tsx` writes reviewer state to `localStorage` |
| Feedback exports are raw JSON downloads | PRR-007 | `components/design-system/feedback-panel.tsx` |
| Realistic mock identities reduce the safety margin for demos | PRR-007 | `mock-data/json/prototype-data.json` |

## Privacy Recommendation

Before any stakeholder session that includes privacy-conscious reviewers, the team should:

1. remove realistic identifiers
2. disable persistent local storage by default
3. govern export behavior
4. restore documented role boundaries in the demo itself
5. add clear demo-data and privacy disclaimers where needed

## Privacy Readiness

Status: Not ready for privacy sign-off.
