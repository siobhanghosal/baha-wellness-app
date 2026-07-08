# BAHA Wellness Companion - Figma Build Blueprint

Figma file created:
- https://www.figma.com/design/8s3W6tQTDt7zOiTxVogdAj

Purpose:
- Turn the PRD into a structured product-design file for four separate apps sharing one backend.
- Keep the design Android-first, adolescent-safe, privacy-first, and BAHA-clinically grounded.

## Recommended Page Structure

### 00 Cover
- Frame: `BAHA Wellness Companion / Cover`
- Include:
  - Product title
  - Subtitle: `Adolescent-first, privacy-first wellness platform`
  - Four-role ecosystem chips: `Student`, `Parent`, `Teacher`, `BAHA Counselor`
  - Three core principles:
    - `Support before crisis`
    - `Awareness before intervention`
    - `Self-knowledge before diagnosis`
  - Release roadmap strip:
    - `R1 Android Launch`
    - `R1.1 Pilot Hardening`
    - `R2 iOS Expansion`

### 01 Product Architecture
- Frame: `System Overview`
  - Shared backend in the center
  - Four app surfaces around it
  - Shared services row:
    - Authentication
    - Consent
    - Privacy tiers
    - Notifications
    - Audit logs
    - Analytics
    - Content delivery
    - Escalation workflows
- Frame: `Privacy and Consent Matrix`
  - Minor flow: ages `9-17`
  - Self-consent flow: ages `18-19`
  - Privacy tiers:
    - `Tier 1 - completion and engagement`
    - `Tier 2 - aggregate wellness trends`
    - `Tier 3 - sensitive responses (always private unless safety override)`
- Frame: `Escalation Workflow`
  - Signal detected
  - Rule check
  - BAHA queue
  - Named safeguarding owner
  - Parent or school notification if approved
  - Crisis route if acute disclosure
- Frame: `Navigation Architecture`
  - Student app tree
  - Parent app tree
  - Teacher app tree
  - Counselor app tree

### 02 Student App
- Section: `Age-band Experience`
  - Cards for `9-13`, `14-16`, `17-19`
  - Show tone differences:
    - `9-13`: softer visuals, simpler copy, guided interactions
    - `14-16`: more expressive, stronger self-reflection prompts
    - `17-19`: more autonomy, denser insight views
- Section: `Core Navigation`
  - Bottom nav: `Home`, `Buddy`, `Learn`, `Games`, `Profile`
- Primary screens:
  - `S01 Welcome and Age Band`
  - `S02 Privacy Promise`
  - `S03 Parent Consent Pending / Self-Consent`
  - `S04 Consent Tier Setup`
  - `S05 Weekly Check-In`
  - `S06 Trend Dashboard`
  - `S07 BAHA Buddy`
  - `S08 Safe Questions Library`
  - `S09 Learning Hub`
  - `S10 Challenge and Badge Center`
  - `S11 Games Hub`
  - `S12 Help Pathway`
  - `S13 Profile and Privacy Settings`
- Critical states to show:
  - Empty state before first check-in
  - Consent blocked state
  - Streak celebration
  - Missed check-in without shame messaging
  - Buddy out-of-scope response
  - Safety escalation handoff screen

### 03 Parent App
- Core navigation:
  - `Home`, `Summaries`, `Learn`, `Settings`
- Primary screens:
  - `P01 Parent Onboarding`
  - `P02 Consent Review`
  - `P03 Weekly Summary`
  - `P04 Conversation Guide`
  - `P05 Privacy Tier Settings`
  - `P06 Parent Learning Modules`
  - `P07 Escalation Alert`
  - `P08 Account and Data Rights`
- Key emphasis:
  - No raw student answers
  - Aggregate trend language only
  - Conversation support over surveillance

### 04 Teacher App
- Core navigation:
  - `Dashboard`, `Referrals`, `Learn`, `Settings`
- Primary screens:
  - `T01 Teacher Onboarding`
  - `T02 Class Trends Dashboard`
  - `T03 Pastoral Input`
  - `T04 Referral Pathway`
  - `T05 Teacher Learning Modules`
  - `T06 Student Case Access (restricted)`
  - `T07 Escalation Status`
- Key emphasis:
  - Anonymized class-level patterns
  - Role-limited student access
  - School pastoral workflow support

### 05 BAHA Counselor App
- Recommended surface:
  - Tablet-first and desktop-friendly board layout
- Core navigation:
  - `Queue`, `Cases`, `Content`, `Analytics`, `Settings`
- Primary screens:
  - `B01 Support Queue`
  - `B02 Case Detail`
  - `B03 Escalation Timeline`
  - `B04 Content Review`
  - `B05 Threshold Configuration`
  - `B06 Pilot Analytics`
  - `B07 Expert Routing`
  - `B08 Audit and Activity Log`
- Key emphasis:
  - Clinical clarity
  - Queue prioritization
  - Strong traceability

### 06 Foundations
- Design direction:
  - Android-first
  - Material 3 compatible
  - Warm, calm, not clinical-cold
- Suggested palette:
  - `Deep Teal` for trust
  - `Soft Coral` for supportive highlights
  - `Mist Blue` for secondary calm surfaces
  - `Warm Sand` for background warmth
  - `Graphite` for text
- Typography direction:
  - Clean modern sans with strong readability
  - Larger type scale for student surfaces
  - Denser data labels for counselor surface
- Motion principles:
  - Soft upward reveals
  - Gentle progress transitions
  - No alarming red-heavy animations
- Component groups:
  - App shell
  - Consent cards
  - Check-in sliders and chips
  - Trend cards
  - Buddy message cells
  - Learning cards
  - Badge tiles
  - Support queue rows

## Screen Inventory by Product Area

### Student App
- Onboarding and identity
  - Welcome
  - Age-band selection
  - Gender optional selection
  - Privacy promise
  - Parent consent pending
  - Self-consent confirmation
  - Consent tier setup
- Check-ins
  - Weekly prompt
  - Question flow
  - Completion confirmation
  - Missed check-in recovery
- Insights
  - Dashboard empty
  - Dashboard active
  - 4-week trends
  - Insight detail
- Buddy
  - Conversation home
  - Safe answer with citation
  - Reflection prompt
  - Out-of-scope redirect
  - Escalation handoff
- Learning
  - Learning home
  - Topic detail
  - Video or article view
  - Quiz
  - Completion milestone
- Games
  - Games hub
  - Emotion Explorer
  - Friendship Choices
  - Breathing activity
  - Session timeout
- Help and profile
  - Help entry
  - Human support route
  - Privacy settings
  - Badge wallet
  - Challenge hub

### Parent App
- Consent setup
- Summary home
- Trend explanation
- Conversation prompts
- Privacy tier changes
- Learning and awareness
- Safety alert state
- Data deletion or rights request

### Teacher App
- School onboarding
- Class trends
- Trend drill-down
- Pastoral note submission
- Referral management
- Teacher learning
- Restricted student case state

### BAHA Counselor App
- Queue list
- Queue filters
- Case summary
- Case note editor
- Escalation detail
- Content approval
- Threshold rules
- Analytics dashboard
- Audit log

## Suggested First Visual Boards Inside Figma

If continuing from the new file, build these first:

1. `Cover and Principles`
2. `Role Ecosystem and Shared Backend`
3. `Student App / Core Journey`
4. `Parent App / Summary and Consent`
5. `Teacher App / Trends and Referral`
6. `Counselor App / Queue and Case Management`
7. `Foundations / Color, Type, Components`

## Student Core Journey to Design First

1. Welcome
2. Privacy promise
3. Consent route
4. Weekly check-in
5. Dashboard
6. Buddy
7. Learning
8. Help handoff

## Product Principles to Preserve in Every Screen

- Never present the student experience as surveillance.
- Keep private data private by default.
- Avoid clinical diagnosis language in student surfaces.
- Make every support action feel guided, warm, and non-punitive.
- Keep parent and teacher visibility summary-based unless explicitly approved.
- Treat escalation as a human-owned workflow, not an automated verdict.

## Figma Build Priority

### Priority 1
- Cover
- Architecture
- Student core journey

### Priority 2
- Parent app
- Teacher app
- Counselor app

### Priority 3
- Foundations page
- Expanded edge cases
- Loading, empty, error, and permission states

## Notes

- A new Figma file has already been created, but the Figma MCP session hit the Starter-plan tool-call limit before layout population could continue.
- Once the limit resets or the plan is upgraded, this blueprint can be translated directly into that file.
