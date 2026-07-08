# P-06 - Weekly Summary Home

## Route Identity

- Flutter Route: `/parent/weekly_summary_home`
- Deep Link: `/parent/weekly_summary_home`
- Required Authentication: Required after bootstrap
- Required Role: Parent or Guardian
- Required Permission: Guardian-linked session
- Transition Animation: fadeThrough
- Arguments: optional refresh source and tab selection
- Return Value: none or passive refresh signal

## Navigation Inputs

- Navigation Sources:
- P-05
- P-07
- Parent_Shell
- Previous Screen: P-05
- Back Navigation: Returns to the previous safe route in the stack; if the stack is invalid, route to the nearest top-level shell destination for this role.
- Bottom Navigation: Summary, Guides, Learn, Settings
- Drawer Navigation: Not used
- Tab Navigation: Contextual tab or segmented control only where the Phase 2 UX spec calls for filters, summary ranges, or queue states.
- Deep Links:
- /parent/weekly_summary_home
- Notification Entry Points:
- Reminder notification
- External Entry Points:
- Cold app launch
- Deep link
- Permission Entry Points:
- No dedicated permission prompt entry

## Navigation Outputs

- Navigation Destinations:
- P-05
- P-07
- Parent_Shell
- P-08
- P-11
- P-14
- Overlay_Network_Error
- Overlay_Session_Expired
- Overlay_Maintenance_Mode
- Overlay_Validation_Error
- Overlay_Success_Toast
- Overlay_Filter_Sheet
- Overlay_Tooltip
- Next Screen: P-07
- Error Redirects:
- Overlay_Network_Error
- Overlay_Maintenance_Mode
- P-05
- Logout Redirects:
- Parent_App_Launch
- Session Expiry Redirects:
- Overlay_Session_Expired

## Role Routing Notes

- This screen belongs to the Parent App Shell.
- Cross-role navigation is not supported; cross-role data relationships exist only through shared backend entities.
- If this screen is accessed via deep link and its prerequisites are not satisfied, route to the prerequisite screen and preserve the original intent for post-gate resumption.
