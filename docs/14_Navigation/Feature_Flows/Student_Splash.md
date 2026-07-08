# S-00 - Splash

## Route Identity

- Flutter Route: `/student/splash`
- Deep Link: `/student/splash`
- Required Authentication: Not required for initial launch route; resolved inside bootstrap
- Required Role: Student
- Required Permission: Student session
- Transition Animation: fade
- Arguments: optional bootstrap context and previous session metadata
- Return Value: none or passive refresh signal

## Navigation Inputs

- Navigation Sources:
- Student_App_Launch
- S-01
- Previous Screen: Student_App_Launch
- Back Navigation: Returns to the previous safe route in the stack; if the stack is invalid, route to the nearest top-level shell destination for this role.
- Bottom Navigation: Home, Learn, Games, Buddy, Profile
- Drawer Navigation: Not used
- Tab Navigation: Contextual tab or segmented control only where the Phase 2 UX spec calls for filters, summary ranges, or queue states.
- Deep Links:
- /student/splash
- Notification Entry Points:
- No direct notification entry by default
- External Entry Points:
- Cold app launch
- Deep link
- Permission Entry Points:
- No dedicated permission prompt entry

## Navigation Outputs

- Navigation Destinations:
- S-01
- Overlay_Network_Error
- Overlay_Session_Expired
- Overlay_Maintenance_Mode
- Overlay_Validation_Error
- Overlay_Success_Toast
- Next Screen: S-01
- Error Redirects:
- Overlay_Network_Error
- Overlay_Maintenance_Mode
- Student_App_Launch
- Logout Redirects:
- Student_App_Launch
- Session Expiry Redirects:
- Overlay_Session_Expired

## Role Routing Notes

- This screen belongs to the Student App Shell.
- Cross-role navigation is not supported; cross-role data relationships exist only through shared backend entities.
- If this screen is accessed via deep link and its prerequisites are not satisfied, route to the prerequisite screen and preserve the original intent for post-gate resumption.
