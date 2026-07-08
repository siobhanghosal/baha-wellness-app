# T-12 - Notification Center

## Route Identity

- Flutter Route: `/teacher/notification_center`
- Deep Link: `/teacher/notification_center`
- Required Authentication: Required after bootstrap
- Required Role: Teacher or School Counselor
- Required Permission: School-scoped staff session
- Transition Animation: fadeThrough
- Arguments: optional refresh source and tab selection
- Return Value: none or passive refresh signal

## Navigation Inputs

- Navigation Sources:
- T-11
- T-13
- Previous Screen: T-11
- Back Navigation: Returns to the previous safe route in the stack; if the stack is invalid, route to the nearest top-level shell destination for this role.
- Bottom Navigation: Dashboard, Pastoral, Referrals, Learn, Settings
- Drawer Navigation: Not used
- Tab Navigation: Contextual tab or segmented control only where the Phase 2 UX spec calls for filters, summary ranges, or queue states.
- Deep Links:
- /teacher/notification_center
- Notification Entry Points:
- Reminder notification
- External Entry Points:
- Cold app launch
- Deep link
- Permission Entry Points:
- Notification permission prompt

## Navigation Outputs

- Navigation Destinations:
- T-11
- T-13
- Overlay_Network_Error
- Overlay_Session_Expired
- Overlay_Maintenance_Mode
- Overlay_Validation_Error
- Overlay_Success_Toast
- Overlay_Filter_Sheet
- Overlay_Tooltip
- Overlay_Permission_Prompt
- Next Screen: T-13
- Error Redirects:
- Overlay_Network_Error
- Overlay_Maintenance_Mode
- T-11
- Logout Redirects:
- Teacher_App_Launch
- Session Expiry Redirects:
- Overlay_Session_Expired

## Role Routing Notes

- This screen belongs to the Teacher App Shell.
- Cross-role navigation is not supported; cross-role data relationships exist only through shared backend entities.
- If this screen is accessed via deep link and its prerequisites are not satisfied, route to the prerequisite screen and preserve the original intent for post-gate resumption.
