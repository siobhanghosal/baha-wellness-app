# P-13 - Data Rights

## Route Identity

- Flutter Route: `/parent/data_rights`
- Deep Link: `/parent/data_rights`
- Required Authentication: Required after bootstrap
- Required Role: Parent or Guardian
- Required Permission: Guardian-linked session
- Transition Animation: slideUp
- Arguments: policy version, consent band, and linked student or guardian identifiers where applicable
- Return Value: completion result, updated entity id, or refresh trigger

## Navigation Inputs

- Navigation Sources:
- P-12
- P-14
- Previous Screen: P-12
- Back Navigation: Returns to the previous safe route in the stack; if the stack is invalid, route to the nearest top-level shell destination for this role.
- Bottom Navigation: Summary, Guides, Learn, Settings
- Drawer Navigation: Not used
- Tab Navigation: Contextual tab or segmented control only where the Phase 2 UX spec calls for filters, summary ranges, or queue states.
- Deep Links:
- /parent/data_rights
- Notification Entry Points:
- No direct notification entry by default
- External Entry Points:
- Cold app launch
- Deep link
- Permission Entry Points:
- No dedicated permission prompt entry

## Navigation Outputs

- Navigation Destinations:
- P-12
- P-14
- Overlay_Network_Error
- Overlay_Session_Expired
- Overlay_Maintenance_Mode
- Overlay_Validation_Error
- Overlay_Success_Toast
- Next Screen: P-14
- Error Redirects:
- Overlay_Network_Error
- Overlay_Maintenance_Mode
- P-12
- Logout Redirects:
- Parent_App_Launch
- Session Expiry Redirects:
- Overlay_Session_Expired

## Role Routing Notes

- This screen belongs to the Parent App Shell.
- Cross-role navigation is not supported; cross-role data relationships exist only through shared backend entities.
- If this screen is accessed via deep link and its prerequisites are not satisfied, route to the prerequisite screen and preserve the original intent for post-gate resumption.
