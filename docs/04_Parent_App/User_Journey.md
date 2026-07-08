# User Journey

## Journey Phases

- consent grant and verification
- privacy tier negotiation
- weekly summary review
- conversation guide usage
- parent learning completion
- escalation notification handling

## Happy Path

1. User opens app and passes role-specific gate checks.
2. App resolves onboarding, consent, training, or session status.
3. User lands on top-level dashboard or home screen.
4. User completes core weekly or operational task.
5. App records analytics and updates recommendations or queue state.
6. User exits with clear next action or passive reminder.

## Interrupted Pathways

- connectivity loss moves the app into cached-mode messaging where allowed
- expired consent or training routes back to the gating flow
- low-data or empty states explain why a screen has no insights yet
- escalation or alert events create high-priority interruption banners with logged timestamps

## Role-Specific Constraints

- No raw student check-in answers or diary content are exposed.
- Parent visibility is bounded by consent tiers and safeguarding overrides only.
- Weekly summary cadence is capped at once per week.
- Conversation guides frame support, not inspection.
