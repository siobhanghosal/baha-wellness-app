# S-38 - Consent Override Notification

## Route Identity

- Flutter Route: `/student/consent_override_notification`
- Deep Link: `/student/consent_override_notification`
- Required Authentication: Partially authenticated or pre-auth onboarding context
- Required Role: Student
- Required Permission: Student session
- Transition Animation: slideUp
- Arguments: policy version, consent band, and linked student or guardian identifiers where applicable
- Return Value: completion result, updated entity id, or refresh trigger

## Navigation Inputs

- Navigation Sources:
- S-37
- S-39
- S-36
- Previous Screen: S-37
- Back Navigation: Returns to the previous safe route in the stack; if the stack is invalid, route to the nearest top-level shell destination for this role.
- Bottom Navigation: Home, Learn, Games, Buddy, Profile
- Drawer Navigation: Not used
- Tab Navigation: Contextual tab or segmented control only where the Phase 2 UX spec calls for filters, summary ranges, or queue states.
- Deep Links:
- /student/consent_override_notification
- Notification Entry Points:
- No direct notification entry by default
- External Entry Points:
- Cold app launch
- Deep link
- Permission Entry Points:
- No dedicated permission prompt entry

## Navigation Outputs

- Navigation Destinations:
- S-37
- S-39
- Overlay_Network_Error
- Overlay_Session_Expired
- Overlay_Maintenance_Mode
- Overlay_Validation_Error
- Overlay_Success_Toast
- Overlay_Permission_Prompt
- Next Screen: S-39
- Error Redirects:
- Overlay_Network_Error
- Overlay_Maintenance_Mode
- S-37
- Logout Redirects:
- Student_App_Launch
- Session Expiry Redirects:
- Overlay_Session_Expired

## Role Routing Notes

- This screen belongs to the Student App Shell.
- Cross-role navigation is not supported; cross-role data relationships exist only through shared backend entities.
- If this screen is accessed via deep link and its prerequisites are not satisfied, route to the prerequisite screen and preserve the original intent for post-gate resumption.
