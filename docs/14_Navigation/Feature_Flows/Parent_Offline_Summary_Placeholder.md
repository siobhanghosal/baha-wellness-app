# P-14 - Offline Summary Placeholder

## Route Identity

- Flutter Route: `/parent/offline_summary_placeholder`
- Deep Link: `/parent/offline_summary_placeholder`
- Required Authentication: Required after bootstrap
- Required Role: Parent or Guardian
- Required Permission: Guardian-linked session
- Transition Animation: fade
- Arguments: settings subsection and source screen
- Return Value: changed-settings flag

## Navigation Inputs

- Navigation Sources:
- P-13
- P-06
- Previous Screen: P-13
- Back Navigation: Returns to the previous safe route in the stack; if the stack is invalid, route to the nearest top-level shell destination for this role.
- Bottom Navigation: Summary, Guides, Learn, Settings
- Drawer Navigation: Not used
- Tab Navigation: Contextual tab or segmented control only where the Phase 2 UX spec calls for filters, summary ranges, or queue states.
- Deep Links:
- /parent/offline_summary_placeholder
- Notification Entry Points:
- No direct notification entry by default
- External Entry Points:
- Cold app launch
- Deep link
- Permission Entry Points:
- Notification permission prompt

## Navigation Outputs

- Navigation Destinations:
- P-13
- Overlay_Network_Error
- Overlay_Session_Expired
- Overlay_Maintenance_Mode
- Overlay_Validation_Error
- Overlay_Success_Toast
- Next Screen: P-13
- Error Redirects:
- Overlay_Network_Error
- Overlay_Maintenance_Mode
- P-13
- Logout Redirects:
- Parent_App_Launch
- Session Expiry Redirects:
- Overlay_Session_Expired

## Role Routing Notes

- This screen belongs to the Parent App Shell.
- Cross-role navigation is not supported; cross-role data relationships exist only through shared backend entities.
- If this screen is accessed via deep link and its prerequisites are not satisfied, route to the prerequisite screen and preserve the original intent for post-gate resumption.
