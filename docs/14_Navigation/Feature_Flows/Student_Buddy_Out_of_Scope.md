# S-32 - Buddy Out-of-Scope

## Route Identity

- Flutter Route: `/student/buddy_out_of_scope`
- Deep Link: `/student/buddy_out_of_scope`
- Required Authentication: Required after bootstrap
- Required Role: Student
- Required Permission: Student session; active consent state
- Transition Animation: fadeThrough
- Arguments: conversation id, entry source, and optional citation id
- Return Value: none or passive refresh signal

## Navigation Inputs

- Navigation Sources:
- S-31
- S-33
- S-30
- Previous Screen: S-31
- Back Navigation: Returns to the previous safe route in the stack; if the stack is invalid, route to the nearest top-level shell destination for this role.
- Bottom Navigation: Home, Learn, Games, Buddy, Profile
- Drawer Navigation: Not used
- Tab Navigation: Contextual tab or segmented control only where the Phase 2 UX spec calls for filters, summary ranges, or queue states.
- Deep Links:
- /student/buddy_out_of_scope
- Notification Entry Points:
- No direct notification entry by default
- External Entry Points:
- Cold app launch
- Deep link
- Permission Entry Points:
- No dedicated permission prompt entry

## Navigation Outputs

- Navigation Destinations:
- S-31
- S-33
- Overlay_Network_Error
- Overlay_Session_Expired
- Overlay_Maintenance_Mode
- Overlay_Validation_Error
- Overlay_Success_Toast
- Next Screen: S-33
- Error Redirects:
- Overlay_Network_Error
- Overlay_Maintenance_Mode
- S-31
- Logout Redirects:
- Student_App_Launch
- Session Expiry Redirects:
- Overlay_Session_Expired

## Role Routing Notes

- This screen belongs to the Student App Shell.
- Cross-role navigation is not supported; cross-role data relationships exist only through shared backend entities.
- If this screen is accessed via deep link and its prerequisites are not satisfied, route to the prerequisite screen and preserve the original intent for post-gate resumption.
