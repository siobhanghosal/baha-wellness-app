# S-16 - Trend Insight Detail

## Core Identity

- Screen ID: `S-16`
- Screen Name: `Trend Insight Detail`
- Description: Explains one trend relationship in plain language.
- User Goal: Complete the primary task implied by the screen name and PRD purpose without ambiguity or hidden policy risk.
- User Persona: Adolescent student using a private, supportive wellness app.

## Conditions

- Entry Conditions:
- Valid authenticated session for this role.
- Role entitlement resolved during bootstrap.
- Required consent or assent workflow completed unless the screen explicitly belongs to onboarding.
- Exit Conditions:
- User explicitly navigates away using back, app navigation, or a primary CTA.
- Screen commits any pending draft state before route change or warns the user if a draft would be lost.
- Check-in payload is saved locally and synced or queued for sync.

## Navigation Relationships

- Navigation Sources:
- App bootstrap router
- Back stack return path
- Home dashboard CTA
- Reminder notification
- Trend detail return path
- Navigation Destinations:
- Previous screen via back navigation
- Check-In Completion
- Trend Dashboard Active
- Home Dashboard
- Incoming Screens:
- App bootstrap router
- Back stack return path
- Home dashboard CTA
- Reminder notification
- Trend detail return path
- Outgoing Screens:
- Previous screen via back navigation
- Check-In Completion
- Trend Dashboard Active
- Home Dashboard
- Buttons:
- Save and Continue
- Back
- Finish Check-In
- Button Destinations:
- Save and Continue: Next gating or task step
- Back: Previous screen
- Finish Check-In: Check-In Completion
- Gesture Navigation:
- Standard Android back gesture returns to the previous safe route unless the flow is gated or destructive changes are unsaved.
- Vertical scrolling is the default primary gesture across all long-form content and list surfaces.
- Deep Links:
- /student/trend_insight_detail
- Conditional Navigation:
- Route access depends on the entitlement and gating state resolved at bootstrap.
- If the required backend data is unavailable, route to the screen's explicit loading, empty, offline, or error state rather than silently failing.
- Permission-based Navigation:
- Notification-permission-specific navigation should remain contextual and never hard-block core usage unless the PRD requires reminders for that role.
- Connectivity-dependent destinations must surface a clear offline explanation if the user attempts to enter them without network.
- Sensitive downstream routes should remain hidden or disabled when the current user lacks the required role or training scope.
- Role-based Navigation:
- This route is only available inside the Student application shell.
- Cross-role navigation is not supported through the UI because the product uses separate app surfaces rather than role-switched views.
- Shared backend identifiers may connect records across roles, but routes themselves remain role-isolated.
- Alternative Navigation:
- A push notification or in-app alert may deep-link to this screen when the corresponding event exists and the user is entitled to view it.
- If a direct route cannot be opened safely, the app should route to the nearest valid parent screen and show an explanatory banner.
- Users can always return to the top-level safe route for their role using the app shell or system back behavior.

## Layout and Structure

- Header: Top app bar with age-appropriate title, back affordance when not top-level, and optional help action. Screen title is 'Trend Insight Detail'.
- Footer: No persistent footer outside bottom navigation; footer space reserved for safe-area actions and policy banners when needed.
- Navigation Bar: Contextual back navigation only; the persistent app bar stays hidden to reduce complexity.
- Tabs: No dedicated tabs; use a single-scroll layout with anchored sections.
- Floating Buttons: No floating action button on this screen; primary actions live in cards, the header, or bottom CTA rows.
- Search: No dedicated search field. If future product growth requires search, add it in the header without changing screen semantics.
- Filters: No interactive filters beyond the role-safe default view.
- Cards: Use cards to present the main units of information on 'Trend Insight Detail'. Cards should expose status, summary metadata, a primary action, and a clear affordance for deeper detail.
- Lists: List patterns are secondary on this screen and should only appear for compact supporting data.
- Sections: Organize the screen into a clear hero or status section, primary task section, secondary informational section, and policy or metadata section.
- Widgets: Compose the screen from reusable Flutter widgets aligned to the Phase 1 component library: status banners, headers, cards, chips, progress indicators, lists, forms, and disclosure panels.

## Form and Input Model

- Forms: Form composition should be explicit, stepwise, and save-safe. Group related fields, show inline helper text, and preserve draft state when connectivity is unstable.
- Inputs: No free-text input is required by the current PRD for the primary happy path on this screen.
- Dropdowns: No dropdown is needed in the base design; if a dropdown is later introduced it must remain constrained and auditable.
- Sliders: Sliders should be used only where the PRD expects scaled or ranged values, especially in check-in or threshold management experiences.
- Checkboxes: No checkbox interaction is required in the default layout.
- Radio Buttons: Radio buttons are used when only one option can be selected and the alternatives must remain visible at once, such as privacy tier, consent route, or narrative choice mode.

## Feedback and Supporting Components

- Progress Indicators: Use determinate progress for multi-step flows and module completion, and indeterminate progress for network-bound fetches shorter than the skeleton threshold.
- Charts: Charts must remain plain-language and privacy-safe. Use only the level of abstraction allowed for this role and this screen.
- Dialogs: Use dialogs only for destructive confirmation, policy acknowledgement, unsaved draft confirmation, or high-impact operational actions.
- Bottom Sheets: Use bottom sheets for secondary action menus, filter pickers, or mobile-safe disclosures without forcing a full route change.
- Snackbars: Show transient, non-critical confirmation for completed saves, retries queued, or reminder preferences changed.
- Toasts: Avoid free-floating toasts for critical information. If a lightweight toast is used, keep it informational and never privacy-sensitive.
- Popups: Use popups sparingly for contextual explanations or policy notices that do not justify a full dialog.
- Tooltips: Tooltips should explain unfamiliar metrics, consent terms, threshold labels, or operational statuses; on mobile they become tappable info popovers.

## States

- Empty States: If 'Trend Insight Detail' has no data, show a role-appropriate explanation, why the state is empty, and the single next best action. Never show a blank surface.
- Loading States: Show structured loading immediately after route entry when live data is required. Keep action areas disabled until entitlement and privacy checks complete.
- Skeleton Screens: Use skeletons for cards, list rows, charts, and headers when data is expected within one network round trip. Skeleton layout must match final geometry to prevent jumpy reflow.
- Offline States: If the screen supports cached behavior, show cached timestamp and available actions. If it does not, explain what requires connectivity and provide a retry affordance.
- Error States: Render recoverable errors inline with retry, support, or return actions. Do not leak implementation details, IDs, or sensitive payload fragments into the UI.
- Success States: Confirm successful completion using a short status banner, completed iconography, and the next recommended action.

## Rules and Dependencies

- Validation Rules:
- All eight weekly check-in dimensions must be completed before submission unless the PRD explicitly marks a field optional.
- Duplicate submission retries must remain idempotent and preserve the latest timestamp.
- Required Permissions:
- Authenticated student session
- Network connectivity for sync
- Push notifications optional
- Connectivity required for live sync, with cached fallback only where Phase 1 explicitly allows it.
- API Endpoints Used:
- /student/check-ins
- /student/trends
- Backend Dependencies:
- Identity Service
- Consent Service
- Student Wellbeing Service
- Learning Service
- Chatbot Service
- Game Service
- Notification Service
- Escalation Service
- Analytics Service
- Audit Service
- Database Objects:
- student_profiles
- check_in_sessions
- check_in_responses
- trend_snapshots
- module_progress
- chatbot_sessions
- chatbot_messages
- game_sessions
- game_signal_snapshots
- notification_events
- audit_events
- mood_vocabulary_progress

## Telemetry and Observability

- Analytics Events:
- screen_view
- checkin_started
- checkin_submitted
- trend_card_opened
- screen_view:S-16
- Logging Events:
- checkin_persist_attempt
- trend_generation_result
- signal_evaluation_result
- ux_spec_reference:S-16

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
- Question progress and response selection should animate minimally to reinforce completion without creating pressure.
- Edge Cases:
- Upstream payload for 'Trend Insight Detail' is missing or delayed.
- User loses connectivity during interaction and resumes later.
- Role entitlement changes while the session is active.
- Student submits after a reminder was already scheduled for the same window.
- The latest submission conflicts with previously cached local data.

## Mermaid Reference

- Diagram File: [Mermaid/Student_Trend_Insight_Detail.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/13_UX_Specification/Mermaid/Student_Trend_Insight_Detail.mmd)
