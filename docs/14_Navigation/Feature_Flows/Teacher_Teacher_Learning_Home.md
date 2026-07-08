# T-09 - Teacher Learning Home

## Route Identity

- Flutter Route: `/teacher/teacher_learning_home`
- Deep Link: `/teacher/teacher_learning_home`
- Required Authentication: Required after bootstrap
- Required Role: Teacher or School Counselor
- Required Permission: School-scoped staff session
- Transition Animation: sharedAxisX
- Arguments: module id, content id, and recommendation source
- Return Value: none or passive refresh signal

## Navigation Inputs

- Navigation Sources:
- T-08
- T-10
- Teacher_Shell
- Previous Screen: T-08
- Back Navigation: Returns to the previous safe route in the stack; if the stack is invalid, route to the nearest top-level shell destination for this role.
- Bottom Navigation: Dashboard, Pastoral, Referrals, Learn, Settings
- Drawer Navigation: Not used
- Tab Navigation: Contextual tab or segmented control only where the Phase 2 UX spec calls for filters, summary ranges, or queue states.
- Deep Links:
- /teacher/teacher_learning_home
- Notification Entry Points:
- Reminder notification
- External Entry Points:
- Cold app launch
- Deep link
- Permission Entry Points:
- No dedicated permission prompt entry

## Navigation Outputs

- Navigation Destinations:
- T-08
- T-10
- Teacher_Shell
- Overlay_Network_Error
- Overlay_Session_Expired
- Overlay_Maintenance_Mode
- Overlay_Validation_Error
- Overlay_Success_Toast
- Next Screen: T-10
- Error Redirects:
- Overlay_Network_Error
- Overlay_Maintenance_Mode
- T-08
- Logout Redirects:
- Teacher_App_Launch
- Session Expiry Redirects:
- Overlay_Session_Expired

## Role Routing Notes

- This screen belongs to the Teacher App Shell.
- Cross-role navigation is not supported; cross-role data relationships exist only through shared backend entities.
- If this screen is accessed via deep link and its prerequisites are not satisfied, route to the prerequisite screen and preserve the original intent for post-gate resumption.
