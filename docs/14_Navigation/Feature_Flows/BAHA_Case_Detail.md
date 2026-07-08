# B-03 - Case Detail

## Route Identity

- Flutter Route: `/baha/case_detail`
- Deep Link: `/baha/case_detail`
- Required Authentication: Required after bootstrap
- Required Role: BAHA clinician, counselor, or admin
- Required Permission: Operational entitlement; clinical or admin scope as appropriate
- Transition Animation: sharedAxisY
- Arguments: case id, referral id, alert id, school id, or queue filter state as applicable
- Return Value: completion result, updated entity id, or refresh trigger

## Navigation Inputs

- Navigation Sources:
- B-02
- B-04
- BAHA_Shell
- B-01
- Previous Screen: B-02
- Back Navigation: Returns to the previous safe route in the stack; if the stack is invalid, route to the nearest top-level shell destination for this role.
- Bottom Navigation: Not used
- Drawer Navigation: Queue, Cases, Content, Thresholds, Analytics, Audit, Settings
- Tab Navigation: Contextual tab or segmented control only where the Phase 2 UX spec calls for filters, summary ranges, or queue states.
- Deep Links:
- /baha/case_detail
- Notification Entry Points:
- Operational alert notification
- External Entry Points:
- Cold app launch
- Deep link
- Permission Entry Points:
- No dedicated permission prompt entry

## Navigation Outputs

- Navigation Destinations:
- B-02
- B-04
- BAHA_Shell
- B-05
- B-06
- Overlay_Network_Error
- Overlay_Session_Expired
- Overlay_Maintenance_Mode
- Overlay_Validation_Error
- Overlay_Success_Toast
- Overlay_Filter_Sheet
- Overlay_Tooltip
- Next Screen: B-04
- Error Redirects:
- Overlay_Network_Error
- Overlay_Maintenance_Mode
- B-02
- Logout Redirects:
- BAHA_App_Launch
- Session Expiry Redirects:
- Overlay_Session_Expired

## Role Routing Notes

- This screen belongs to the BAHA Operations Shell.
- Cross-role navigation is not supported; cross-role data relationships exist only through shared backend entities.
- If this screen is accessed via deep link and its prerequisites are not satisfied, route to the prerequisite screen and preserve the original intent for post-gate resumption.
