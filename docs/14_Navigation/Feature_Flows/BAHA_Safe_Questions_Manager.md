# B-10 - Safe Questions Manager

## Route Identity

- Flutter Route: `/baha/safe_questions_manager`
- Deep Link: `/baha/safe_questions_manager`
- Required Authentication: Required after bootstrap
- Required Role: BAHA clinician, counselor, or admin
- Required Permission: Operational entitlement
- Transition Animation: fadeThrough
- Arguments: conversation id, entry source, and optional citation id
- Return Value: none or passive refresh signal

## Navigation Inputs

- Navigation Sources:
- B-09
- B-11
- B-07
- Previous Screen: B-09
- Back Navigation: Returns to the previous safe route in the stack; if the stack is invalid, route to the nearest top-level shell destination for this role.
- Bottom Navigation: Not used
- Drawer Navigation: Queue, Cases, Content, Thresholds, Analytics, Audit, Settings
- Tab Navigation: Contextual tab or segmented control only where the Phase 2 UX spec calls for filters, summary ranges, or queue states.
- Deep Links:
- /baha/safe_questions_manager
- Notification Entry Points:
- No direct notification entry by default
- External Entry Points:
- Cold app launch
- Deep link
- Permission Entry Points:
- No dedicated permission prompt entry

## Navigation Outputs

- Navigation Destinations:
- B-09
- B-11
- Overlay_Network_Error
- Overlay_Session_Expired
- Overlay_Maintenance_Mode
- Overlay_Validation_Error
- Overlay_Success_Toast
- Next Screen: B-11
- Error Redirects:
- Overlay_Network_Error
- Overlay_Maintenance_Mode
- B-09
- Logout Redirects:
- BAHA_App_Launch
- Session Expiry Redirects:
- Overlay_Session_Expired

## Role Routing Notes

- This screen belongs to the BAHA Operations Shell.
- Cross-role navigation is not supported; cross-role data relationships exist only through shared backend entities.
- If this screen is accessed via deep link and its prerequisites are not satisfied, route to the prerequisite screen and preserve the original intent for post-gate resumption.
