# B-14 - Analytics Export

## Route Identity

- Flutter Route: `/baha/analytics_export`
- Deep Link: `/baha/analytics_export`
- Required Authentication: Required after bootstrap
- Required Role: BAHA clinician, counselor, or admin
- Required Permission: Operational entitlement; clinical or admin scope as appropriate
- Transition Animation: fadeThrough
- Arguments: content id, review queue filter, or export request context
- Return Value: completion result, updated entity id, or refresh trigger

## Navigation Inputs

- Navigation Sources:
- B-13
- B-15
- Previous Screen: B-13
- Back Navigation: Returns to the previous safe route in the stack; if the stack is invalid, route to the nearest top-level shell destination for this role.
- Bottom Navigation: Not used
- Drawer Navigation: Queue, Cases, Content, Thresholds, Analytics, Audit, Settings
- Tab Navigation: Contextual tab or segmented control only where the Phase 2 UX spec calls for filters, summary ranges, or queue states.
- Deep Links:
- /baha/analytics_export
- Notification Entry Points:
- Operational alert notification
- External Entry Points:
- Cold app launch
- Deep link
- Permission Entry Points:
- No dedicated permission prompt entry

## Navigation Outputs

- Navigation Destinations:
- B-13
- B-15
- Overlay_Network_Error
- Overlay_Session_Expired
- Overlay_Maintenance_Mode
- Overlay_Validation_Error
- Overlay_Success_Toast
- Overlay_Filter_Sheet
- Overlay_Tooltip
- Next Screen: B-15
- Error Redirects:
- Overlay_Network_Error
- Overlay_Maintenance_Mode
- B-13
- Logout Redirects:
- BAHA_App_Launch
- Session Expiry Redirects:
- Overlay_Session_Expired

## Role Routing Notes

- This screen belongs to the BAHA Operations Shell.
- Cross-role navigation is not supported; cross-role data relationships exist only through shared backend entities.
- If this screen is accessed via deep link and its prerequisites are not satisfied, route to the prerequisite screen and preserve the original intent for post-gate resumption.
