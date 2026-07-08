# B-17 - Operational Settings

## Route Identity

- Flutter Route: `/baha/operational_settings`
- Deep Link: `/baha/operational_settings`
- Required Authentication: Required after bootstrap
- Required Role: BAHA clinician, counselor, or admin
- Required Permission: Operational entitlement
- Transition Animation: fade
- Arguments: settings subsection and source screen
- Return Value: changed-settings flag

## Navigation Inputs

- Navigation Sources:
- B-16
- BAHA_Shell
- Previous Screen: B-16
- Back Navigation: Returns to the previous safe route in the stack; if the stack is invalid, route to the nearest top-level shell destination for this role.
- Bottom Navigation: Not used
- Drawer Navigation: Queue, Cases, Content, Thresholds, Analytics, Audit, Settings
- Tab Navigation: Contextual tab or segmented control only where the Phase 2 UX spec calls for filters, summary ranges, or queue states.
- Deep Links:
- /baha/operational_settings
- Notification Entry Points:
- No direct notification entry by default
- External Entry Points:
- Cold app launch
- Deep link
- Permission Entry Points:
- Notification permission prompt

## Navigation Outputs

- Navigation Destinations:
- B-16
- BAHA_Shell
- Overlay_Network_Error
- Overlay_Session_Expired
- Overlay_Maintenance_Mode
- Overlay_Validation_Error
- Overlay_Success_Toast
- Next Screen: BAHA_Shell
- Error Redirects:
- Overlay_Network_Error
- Overlay_Maintenance_Mode
- B-16
- Logout Redirects:
- BAHA_App_Launch
- Session Expiry Redirects:
- Overlay_Session_Expired

## Role Routing Notes

- This screen belongs to the BAHA Operations Shell.
- Cross-role navigation is not supported; cross-role data relationships exist only through shared backend entities.
- If this screen is accessed via deep link and its prerequisites are not satisfied, route to the prerequisite screen and preserve the original intent for post-gate resumption.
