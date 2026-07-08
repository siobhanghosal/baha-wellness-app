# S-07 - Self-Consent Confirmation

## Route Identity

- Flutter Route: `/student/self_consent_confirmation`
- Deep Link: `/student/self_consent_confirmation`
- Required Authentication: Partially authenticated or pre-auth onboarding context
- Required Role: Student
- Required Permission: Student session
- Transition Animation: slideLeft
- Arguments: progress token, policy version, and role context
- Return Value: completion result, updated entity id, or refresh trigger

## Navigation Inputs

- Navigation Sources:
- S-06
- S-08
- S-03
- Previous Screen: S-06
- Back Navigation: Returns to the previous safe route in the stack; if the stack is invalid, route to the nearest top-level shell destination for this role.
- Bottom Navigation: Home, Learn, Games, Buddy, Profile
- Drawer Navigation: Not used
- Tab Navigation: Contextual tab or segmented control only where the Phase 2 UX spec calls for filters, summary ranges, or queue states.
- Deep Links:
- /student/self_consent_confirmation
- Notification Entry Points:
- No direct notification entry by default
- External Entry Points:
- Cold app launch
- Deep link
- Permission Entry Points:
- No dedicated permission prompt entry

## Navigation Outputs

- Navigation Destinations:
- S-06
- S-08
- Overlay_Network_Error
- Overlay_Session_Expired
- Overlay_Maintenance_Mode
- Overlay_Validation_Error
- Overlay_Success_Toast
- Next Screen: S-08
- Error Redirects:
- Overlay_Network_Error
- Overlay_Maintenance_Mode
- S-06
- Logout Redirects:
- Student_App_Launch
- Session Expiry Redirects:
- Overlay_Session_Expired

## Role Routing Notes

- This screen belongs to the Student App Shell.
- Cross-role navigation is not supported; cross-role data relationships exist only through shared backend entities.
- If this screen is accessed via deep link and its prerequisites are not satisfied, route to the prerequisite screen and preserve the original intent for post-gate resumption.
