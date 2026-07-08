# P-12 - Notification Settings

## Route Identity

- Flutter Route: `/parent/notification_settings`
- Deep Link: `/parent/notification_settings`
- Required Authentication: Required after bootstrap
- Required Role: Parent or Guardian
- Required Permission: Guardian-linked session
- Transition Animation: fade
- Arguments: settings subsection and source screen
- Return Value: changed-settings flag

## Navigation Inputs

- Navigation Sources:
- P-11
- P-13
- Parent_Shell
- Previous Screen: P-11
- Back Navigation: Returns to the previous safe route in the stack; if the stack is invalid, route to the nearest top-level shell destination for this role.
- Bottom Navigation: Summary, Guides, Learn, Settings
- Drawer Navigation: Not used
- Tab Navigation: Contextual tab or segmented control only where the Phase 2 UX spec calls for filters, summary ranges, or queue states.
- Deep Links:
- /parent/notification_settings
- Notification Entry Points:
- No direct notification entry by default
- External Entry Points:
- Cold app launch
- Deep link
- Permission Entry Points:
- Notification permission prompt

## Navigation Outputs

- Navigation Destinations:
- P-11
- P-13
- Parent_Shell
- Overlay_Network_Error
- Overlay_Session_Expired
- Overlay_Maintenance_Mode
- Overlay_Validation_Error
- Overlay_Success_Toast
- Overlay_Permission_Prompt
- Next Screen: P-13
- Error Redirects:
- Overlay_Network_Error
- Overlay_Maintenance_Mode
- P-11
- Logout Redirects:
- Parent_App_Launch
- Session Expiry Redirects:
- Overlay_Session_Expired

## Role Routing Notes

- This screen belongs to the Parent App Shell.
- Cross-role navigation is not supported; cross-role data relationships exist only through shared backend entities.
- If this screen is accessed via deep link and its prerequisites are not satisfied, route to the prerequisite screen and preserve the original intent for post-gate resumption.
