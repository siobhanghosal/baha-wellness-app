# B-00 - Splash

## Route Identity

- Flutter Route: `/baha/splash`
- Deep Link: `/baha/splash`
- Required Authentication: Not required for initial launch route; resolved inside bootstrap
- Required Role: BAHA clinician, counselor, or admin
- Required Permission: Operational entitlement
- Transition Animation: fade
- Arguments: optional bootstrap context and previous session metadata
- Return Value: none or passive refresh signal

## Navigation Inputs

- Navigation Sources:
- BAHA_App_Launch
- B-01
- Previous Screen: BAHA_App_Launch
- Back Navigation: Returns to the previous safe route in the stack; if the stack is invalid, route to the nearest top-level shell destination for this role.
- Bottom Navigation: Not used
- Drawer Navigation: Queue, Cases, Content, Thresholds, Analytics, Audit, Settings
- Tab Navigation: Contextual tab or segmented control only where the Phase 2 UX spec calls for filters, summary ranges, or queue states.
- Deep Links:
- /baha/splash
- Notification Entry Points:
- No direct notification entry by default
- External Entry Points:
- Cold app launch
- Deep link
- Permission Entry Points:
- No dedicated permission prompt entry

## Navigation Outputs

- Navigation Destinations:
- B-01
- Overlay_Network_Error
- Overlay_Session_Expired
- Overlay_Maintenance_Mode
- Overlay_Validation_Error
- Overlay_Success_Toast
- Next Screen: B-01
- Error Redirects:
- Overlay_Network_Error
- Overlay_Maintenance_Mode
- BAHA_App_Launch
- Logout Redirects:
- BAHA_App_Launch
- Session Expiry Redirects:
- Overlay_Session_Expired

## Role Routing Notes

- This screen belongs to the BAHA Operations Shell.
- Cross-role navigation is not supported; cross-role data relationships exist only through shared backend entities.
- If this screen is accessed via deep link and its prerequisites are not satisfied, route to the prerequisite screen and preserve the original intent for post-gate resumption.
