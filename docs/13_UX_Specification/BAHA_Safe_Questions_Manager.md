# B-10 - Safe Questions Manager

## Core Identity

- Screen ID: `B-10`
- Screen Name: `Safe Questions Manager`
- Description: Maintains chatbot Q&A corpus and expiry states.
- User Goal: Complete the primary task implied by the screen name and PRD purpose without ambiguity or hidden policy risk.
- User Persona: BAHA clinician, counselor, content reviewer, or operational admin managing safeguards and platform governance.

## Conditions

- Entry Conditions:
- Valid authenticated session for this role.
- Role entitlement resolved during bootstrap.
- Operational scope or clinical/admin entitlement is active.
- Exit Conditions:
- User explicitly navigates away using back, app navigation, or a primary CTA.
- Screen commits any pending draft state before route change or warns the user if a draft would be lost.

## Navigation Relationships

- Navigation Sources:
- App bootstrap router
- Back stack return path
- Home dashboard CTA
- Safe Questions entry
- Support banner CTA
- Navigation Destinations:
- Previous screen via back navigation
- Buddy Citation Detail
- Help Center
- Consent Override Notification
- Incoming Screens:
- App bootstrap router
- Back stack return path
- Home dashboard CTA
- Safe Questions entry
- Support banner CTA
- Outgoing Screens:
- Previous screen via back navigation
- Buddy Citation Detail
- Help Center
- Consent Override Notification
- Buttons:
- Send
- Open Citation
- Get Human Help
- Button Destinations:
- Send: Safe Questions Manager
- Open Citation: Buddy Citation Detail
- Get Human Help: Help Center or support request flow
- Gesture Navigation:
- Standard Android back gesture returns to the previous safe route unless the flow is gated or destructive changes are unsaved.
- Vertical scrolling is the default primary gesture across all long-form content and list surfaces.
- Long-press on a message should open only privacy-safe utility actions such as citation view, not raw export by default.
- Deep Links:
- /baha/safe_questions_manager
- Conditional Navigation:
- Route access depends on the entitlement and gating state resolved at bootstrap.
- If the required backend data is unavailable, route to the screen's explicit loading, empty, offline, or error state rather than silently failing.
- Permission-based Navigation:
- Notification-permission-specific navigation should remain contextual and never hard-block core usage unless the PRD requires reminders for that role.
- Connectivity-dependent destinations must surface a clear offline explanation if the user attempts to enter them without network.
- Sensitive downstream routes should remain hidden or disabled when the current user lacks the required role or training scope.
- Role-based Navigation:
- This route is only available inside the BAHA application shell.
- Cross-role navigation is not supported through the UI because the product uses separate app surfaces rather than role-switched views.
- Shared backend identifiers may connect records across roles, but routes themselves remain role-isolated.
- Alternative Navigation:
- A push notification or in-app alert may deep-link to this screen when the corresponding event exists and the user is entitled to view it.
- If a direct route cannot be opened safely, the app should route to the nearest valid parent screen and show an explanatory banner.
- Users can always return to the top-level safe route for their role using the app shell or system back behavior.

## Layout and Structure

- Header: Dense operational header with role context, queue counters, filters, and export or action shortcuts. Screen title is 'Safe Questions Manager'.
- Footer: No persistent footer; footer area is reserved for queue metrics, audit notices, or review state banners.
- Navigation Bar: Sidebar or adaptive navigation with Support Queue, Cases, Content, Thresholds, Analytics, Audit, and Settings.
- Tabs: No dedicated tabs; use a single-scroll layout with anchored sections.
- Floating Buttons: No floating action button on this screen; primary actions live in cards, the header, or bottom CTA rows.
- Search: No dedicated search field. If future product growth requires search, add it in the header without changing screen semantics.
- Filters: No interactive filters beyond the role-safe default view.
- Cards: Use cards to present the main units of information on 'Safe Questions Manager'. Cards should expose status, summary metadata, a primary action, and a clear affordance for deeper detail.
- Lists: List patterns are secondary on this screen and should only appear for compact supporting data.
- Sections: Organize the screen into a clear hero or status section, primary task section, secondary informational section, and policy or metadata section.
- Widgets: Compose the screen from reusable Flutter widgets aligned to the Phase 1 component library: status banners, headers, cards, chips, progress indicators, lists, forms, and disclosure panels.

## Form and Input Model

- Forms: No primary multi-field form on this screen; any compact interaction should still follow consistent spacing and inline validation rules.
- Inputs: No free-text input is required by the current PRD for the primary happy path on this screen.
- Dropdowns: No dropdown is needed in the base design; if a dropdown is later introduced it must remain constrained and auditable.
- Sliders: No slider is required for the current screen definition.
- Checkboxes: No checkbox interaction is required in the default layout.
- Radio Buttons: No radio control is required by the current screen contract.

## Feedback and Supporting Components

- Progress Indicators: Use determinate progress for multi-step flows and module completion, and indeterminate progress for network-bound fetches shorter than the skeleton threshold.
- Charts: No chart is mandatory here; if a micro-chart is later added it must reuse the same semantics defined in Phase 1.
- Dialogs: Use dialogs only for destructive confirmation, policy acknowledgement, unsaved draft confirmation, or high-impact operational actions.
- Bottom Sheets: Use bottom sheets for secondary action menus, filter pickers, or mobile-safe disclosures without forcing a full route change.
- Snackbars: Show transient, non-critical confirmation for completed saves, retries queued, or reminder preferences changed.
- Toasts: Avoid free-floating toasts for critical information. If a lightweight toast is used, keep it informational and never privacy-sensitive.
- Popups: Use popups sparingly for contextual explanations or policy notices that do not justify a full dialog.
- Tooltips: Tooltips should explain unfamiliar metrics, consent terms, threshold labels, or operational statuses; on mobile they become tappable info popovers.

## States

- Empty States: If 'Safe Questions Manager' has no data, show a role-appropriate explanation, why the state is empty, and the single next best action. Never show a blank surface.
- Loading States: Show structured loading immediately after route entry when live data is required. Keep action areas disabled until entitlement and privacy checks complete.
- Skeleton Screens: Use skeletons for cards, list rows, charts, and headers when data is expected within one network round trip. Skeleton layout must match final geometry to prevent jumpy reflow.
- Offline States: If the screen supports cached behavior, show cached timestamp and available actions. If it does not, explain what requires connectivity and provide a retry affordance.
- Error States: Render recoverable errors inline with retry, support, or return actions. Do not leak implementation details, IDs, or sensitive payload fragments into the UI.
- Success States: Confirm successful completion using a short status banner, completed iconography, and the next recommended action.

## Rules and Dependencies

- Validation Rules:
- Validate that upstream payloads, role entitlements, and route parameters exist before rendering the main body.
- If there are no editable fields, validation is limited to guard-state checks and action eligibility checks.
- Required Permissions:
- Authenticated staff session
- Operational scope assignment
- Clinical or admin entitlement where applicable
- Connectivity required for live sync, with cached fallback only where Phase 1 explicitly allows it.
- API Endpoints Used:
- /me
- /baha/queue
- /baha/analytics
- /baha/audit
- /baha/cases/{id}
- /baha/cases/{id}/events
- /baha/thresholds
- /baha/content
- Backend Dependencies:
- Identity Service
- Consent Service
- Learning Service
- Chatbot Service
- Escalation Service
- Analytics Service
- Audit Service
- Notification Service
- Database Objects:
- support_cases
- case_events
- case_assignments
- content_items
- content_revisions
- content_tags
- safe_question_items
- consent_records
- privacy_tier_records
- audit_events
- notification_events
- chatbot_sessions
- chatbot_messages
- chatbot_profile_summaries

## Telemetry and Observability

- Analytics Events:
- screen_view
- chat_session_started
- safe_question_opened
- chat_escalation_triggered
- screen_view:B-10
- Logging Events:
- chat_request_received
- retrieval_result
- citation_attached
- escalation_signal_result
- ux_spec_reference:B-10

## Quality, Safety, and Compliance

- Accessibility Notes:
- Meet WCAG 2.1 AA contrast and focus visibility requirements.
- All primary actions, helper text, and error states must be screen-reader accessible and logically ordered.
- Touch targets must remain thumb-safe on Android, especially for student-facing and parent-facing surfaces.
- Where charts or metrics appear, provide equivalent narrative descriptions and non-visual summaries.
- Localization Notes:
- All visible copy should be externalized and keyed for localization.
- Plain-language student copy must remain age-band appropriate after translation.
- Support right-sized text expansion for long German-like or Indian-language strings without clipping.
- Date, time, week labels, and hotline metadata must respect locale formatting rules.
- Security Notes:
- Do not expose raw identifiers, tokens, or internal exception details in the UI layer.
- Revalidate role and data entitlements server-side for every mutation and sensitive query.
- Prevent screenshot-prone or clipboard-happy patterns for highly sensitive support and case data where device policy allows mitigation.
- Operational screens must support tamper-evident action logging and least-privilege access segregation.
- Privacy Notes:
- Display only the minimum data needed for the task described by the PRD.
- Apply consent-tier projection before the payload reaches the client whenever data is parent- or teacher-facing.
- Never introduce diagnosis wording, risk scores, or surveillance framing in student-facing states.
- Animation Notes:
- Use short, low-stress motion to preserve continuity between states.
- Prefer fade, slide, and elevation transitions over flashy effects.
- Respect platform reduced-motion preferences and disable non-essential animation when requested.
- Microinteractions:
- Primary CTA provides pressed, disabled, loading, and success feedback states.
- Inline validation appears at field level before route-level blocking messages.
- Cards, rows, and chips show tactile tap feedback and clear selection state.
- Incoming message, citation reveal, and escalation banner transitions should feel calm and informative.
- Edge Cases:
- Upstream payload for 'Safe Questions Manager' is missing or delayed.
- User loses connectivity during interaction and resumes later.
- Role entitlement changes while the session is active.
- Safe Questions content for the requested topic is expired or unavailable.
- Escalation signal triggers mid-conversation and the app is backgrounded immediately after.

## Mermaid Reference

- Diagram File: [Mermaid/BAHA_Safe_Questions_Manager.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/13_UX_Specification/Mermaid/BAHA_Safe_Questions_Manager.mmd)
