import re
from pathlib import Path
from textwrap import dedent


ROOT = Path("/Users/solomonkaruppiah/Desktop/Baha_Data")
DOCS = ROOT / "docs"
VISUAL_ROOT = DOCS / "16_Visual_Language"


def write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(dedent(content).strip() + "\n", encoding="utf-8")


def build_root_docs() -> dict[str, str]:
    return {
        "README.md": """
        # Phase 5 Visual Language

        This repository defines the artistic direction for the BAHA platform before any Figma screens are generated.

        It translates the BAHA mission, age segmentation, consent posture, and Phase 4 design system into a coherent visual language that can be applied consistently across Student, Parent, Teacher, and BAHA applications.

        ## Core Outputs

        - [Visual_Guide.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/Visual_Guide.md)
        - [Theme_Guide.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/Theme_Guide.md)
        - [Illustration_Guide.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/Illustration_Guide.md)
        - [Motion_Guide.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/Motion_Guide.md)
        - [Colour_Guide.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/Colour_Guide.md)
        - [Typography_Guide.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/Typography_Guide.md)
        - [Icon_Guide.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/Icon_Guide.md)
        - [Component_Styling.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/Component_Styling.md)
        - [Age_Group_Guide.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/Age_Group_Guide.md)
        - [Role_Guide.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/Role_Guide.md)

        ## Sections

        - [01_Brand_Identity](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/01_Brand_Identity/Brand_Identity.md)
        - [02_Emotional_Design](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/02_Emotional_Design/Emotional_Design.md)
        - [03_Illustration_System](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/03_Illustration_System/Illustration_System.md)
        - [04_Iconography](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/04_Iconography/Iconography.md)
        - [05_Colour_Psychology](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/05_Colour_Psychology/Colour_Psychology.md)
        - [06_Typography_Mood](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/06_Typography_Mood/Typography_Mood.md)
        - [07_Imagery](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/07_Imagery/Imagery.md)
        - [08_Motion_Style](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/08_Motion_Style/Motion_Style.md)
        - [09_Microinteractions](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/09_Microinteractions/Microinteractions.md)
        - [10_Visual_Rules](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/10_Visual_Rules/Visual_Rules.md)
        - [11_Theme_Variations](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/11_Theme_Variations/Theme_Variations.md)
        - [12_Figma_References](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/12_Figma_References/Figma_References.md)
        - [13_Flutter_References](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/13_Flutter_References/Flutter_References.md)
        - [Mermaid](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/Mermaid/README.md)

        ## Intent

        - Do not create UI screens in this phase.
        - Do create the visual language that future Figma and Flutter work will follow.
        - Keep every visual decision faithful to BAHA's adolescent-first, privacy-safe, non-diagnostic product stance.
        """,
        "Visual_Guide.md": """
        # Visual Guide

        ## Mission

        BAHA's visual language exists to make adolescents feel safe, understood, and oriented while helping adults act responsibly and calmly.

        ## Vision

        Build a wellness platform that looks emotionally intelligent rather than medical, friendly rather than childish, and operationally trustworthy without becoming cold.

        ## Chosen Style

        BAHA uses a **Calm Neo-Modern Care System**.

        This style blends:

        - Apple-like clarity in hierarchy and restraint
        - Headspace-like softness in emotional tone
        - Material 3-like adaptability across devices and themes
        - Operational density for teacher and BAHA workflows where needed

        ## Why This Style

        - The product supports sensitive wellbeing conversations, so harsh or hyper-gamified visuals would undermine trust.
        - Students need warmth and simplicity without being spoken down to.
        - Parents and teachers need clarity and evidence of governance.
        - BAHA staff need speed, legibility, and controlled severity handling.

        ## Brand Personality

        - Calm
        - Trustworthy
        - Warm
        - Clear
        - Protective
        - Thoughtful
        - Quietly confident

        ## Brand Voice

        BAHA speaks in plain language, avoids judgment, and gives people a clear next step without dramatizing the moment.

        ## Tone

        - Student: gentle, encouraging, non-diagnostic
        - Parent: clear, respectful, privacy-explicit
        - Teacher: concise, practical, safeguarding-aware
        - Counselor and Admin: precise, composed, accountable

        ## Emotional Keywords

        - safe
        - supported
        - calm
        - seen
        - trustworthy
        - steady

        ## Visual Keywords

        - warm light
        - rounded geometry
        - breathable whitespace
        - soft gradients
        - grounded contrast
        - purposeful density

        ## Interaction Keywords

        - guided
        - predictable
        - low-friction
        - respectful
        - legible
        - reassuring

        ## What BAHA Is Not

        - not a neon wellness app
        - not a surveillance dashboard
        - not a clinical diagnostic portal
        - not a playful social game product
        """,
        "Theme_Guide.md": """
        # Theme Guide

        ## Theme Architecture

        BAHA uses one visual system with controlled expressions, not multiple unrelated brands.

        ## Shared Theme Base

        - Warm neutral canvases
        - Trust-blue action color
        - Calm teal support color
        - Rounded containers
        - Soft low-elevation cards
        - High legibility text

        ## Theme Variations

        ### Light Theme

        - Default theme for all roles
        - Favours warm off-white backgrounds and low-glare surfaces
        - Best for student, parent, and daytime teacher use

        ### Dark Theme

        - Optional theme for low-light reading and extended sessions
        - Uses deeper neutral canvases instead of pure black
        - Keeps success, warning, and danger tones muted but readable

        ### Role Expression

        - Student themes increase softness, larger spacing, and visual warmth
        - Parent themes increase explanatory clarity and summary contrast
        - Teacher themes reduce ornament and strengthen data readability
        - BAHA themes increase density and operational structure without changing core brand color logic

        ## Why Variation Matters

        - The product serves different emotional contexts across roles and ages.
        - Variation helps each audience feel respected without fragmenting the platform identity.
        - Controlled variation lets Figma and Flutter share the same token backbone.
        """,
        "Illustration_Guide.md": """
        # Illustration Guide

        ## Purpose

        Illustration in BAHA should welcome, explain, and soften empty or completion moments without trivializing emotional difficulty.

        ## Core Style

        - soft geometric characters
        - grounded anatomy with slightly simplified proportions
        - expressive but not exaggerated faces
        - gentle gradients and warm ambient light
        - rounded objects and low-detail environments

        ## Do

        - use illustrations for onboarding, empty states, progress, and calm learning
        - show agency, curiosity, reflection, and support
        - keep diversity broad and respectful without tokenism

        ## Don't

        - depict crisis literally
        - use panic imagery, hospital aesthetics, or melodrama
        - make adolescents look infantile

        ## System Rules

        - Use one perspective family across a scene set.
        - Keep shadows soft and consistent.
        - Use outlines sparingly and only where clarity is needed.
        - Prefer metaphorical support imagery over literal emotional distress.
        """,
        "Motion_Guide.md": """
        # Motion Guide

        ## Motion Character

        BAHA motion is calm, orienting, and lightly tactile.

        ## Motion Principles

        - motion should explain, not entertain
        - transitions should lower uncertainty
        - success can feel rewarding without becoming noisy
        - distress or escalation states should stay visually steady

        ## Signature Motion

        - soft fade-through route changes
        - shared-axis movement for guided flows
        - subtle card lift on press
        - breathing pulse reserved for regulation experiences

        ## Motion Restraint

        - no bounce-heavy celebration in serious flows
        - no aggressive chart motion
        - no chat effects that make the assistant feel toy-like
        """,
        "Colour_Guide.md": """
        # Colour Guide

        ## Master Palette

        | Role | Primary | Secondary | Background | Accent |
        |---|---|---|---|---|
        | Core BAHA | `#155EEF` | `#0F766E` | `#F8F6F2` | `#F59E0B` |
        | Student soft | `#4F7CFF` | `#2AA198` | `#FBF8F3` | `#F7B267` |
        | Parent clear | `#155EEF` | `#2F6F91` | `#F7F7F5` | `#7C9A92` |
        | Teacher neutral | `#3056D3` | `#4B5563` | `#F4F6F8` | `#0F766E` |
        | BAHA ops | `#1D4ED8` | `#344054` | `#F5F7FA` | `#B42318` |

        ## Psychological Role of Color

        - Blue builds trust and stable direction.
        - Teal communicates care, regulation, and reflection.
        - Warm neutrals reduce glare and make the product feel human.
        - Amber is used for guidance and gentle advisories.
        - Red is restricted to clearly owned high-severity moments.

        ## Why These Choices

        - Students need calm before stimulation.
        - Parents need clarity before warmth.
        - Teachers need neutrality before personality.
        - BAHA staff need signal before decoration.
        """,
        "Typography_Guide.md": """
        # Typography Guide

        ## Mood Direction

        Typography should feel human, composed, and easy to trust.

        ## Type Personality

        - Headlines: warm, confident, rounded sans tone
        - Body: highly legible neutral sans
        - Operational labels: tighter, cleaner metadata handling

        ## Typographic Mood

        - 9-13: larger, softer, more open rhythm
        - 14-16: balanced hierarchy with slightly more contrast
        - 17-19: more editorial and self-directed
        - Parent: calm readability
        - Teacher and BAHA: concise and utilitarian

        ## Guidance

        - Use sentence case almost everywhere.
        - Avoid all-caps blocks except tiny metadata labels.
        - Protect line length to keep long wellbeing copy readable.
        """,
        "Icon_Guide.md": """
        # Icon Guide

        ## Icon Family

        BAHA uses rounded outline-first icons with selective filled severity symbols.

        ## Character

        - approachable
        - modern
        - unthreatening
        - clear at small sizes

        ## Rules

        - Outline icons are the default.
        - Filled icons are reserved for alerts, active states, and achievement emphasis.
        - Students see softer rounded forms; BAHA operations may use tighter geometry but keep the same family DNA.
        """,
        "Component_Styling.md": """
        # Component Styling

        ## Cards

        - Student cards use softer radii, warmer fills, and more breathing room.
        - Parent cards balance warmth with higher information clarity.
        - Teacher cards are flatter and more modular.
        - BAHA cards become panels with stronger border structure and less decorative color.

        ## Navigation

        - Student and parent navigation should feel easy to scan and calm to revisit.
        - Teacher navigation prioritizes fast category switching.
        - BAHA navigation prioritizes persistent orientation and data workload management.

        ## Buttons

        - Primary buttons are confident but not loud.
        - Secondary buttons are clearly available without competing.
        - Destructive buttons are visually rare and explicit.

        ## Charts

        - Student charts look supportive and simplified.
        - Parent charts explain before they impress.
        - Teacher charts emphasize pattern recognition.
        - BAHA charts emphasize accountability and trend clarity.

        ## Empty and Loading States

        - Empty states should feel guided, not blank.
        - Loading states should feel alive but not restless.
        - Crisis-adjacent routes should use restrained loading motion and stronger textual reassurance.
        """,
        "Age_Group_Guide.md": """
        # Age Group Guide

        ## 9-13 Students

        - Colour palette: soft blue, seafoam teal, peach accents, warm cream backgrounds
        - Typography: larger type, rounder visual rhythm, minimal density
        - Illustration style: gentle characters, clearer emotional cues, supportive environments
        - Card style: taller cards, soft shadows, generous padding
        - Navigation style: highly explicit labels, clear active states
        - Icon style: rounded outlines with simple metaphors
        - Animations: slower, softer, more guided
        - Button style: large, high-clarity, full-width where appropriate
        - Backgrounds: warm matte surfaces with subtle gradient halos
        - Charts: simplified charts with plain-language annotation
        - Empty states: encouraging and action-led
        - Loading screens: calm shimmer or simple pulse
        - Achievements: private, warm, low-competition milestones
        - Badges: soft pill badges with friendly iconography

        ## 14-16 Students

        - Colour palette: richer blue, balanced teal, slightly cooler neutrals
        - Typography: still open but more contrast between heading and body
        - Illustration style: more expressive, more identity-oriented, less childlike
        - Card style: structured cards with clearer sectioning
        - Navigation style: calm but slightly sharper hierarchy
        - Icon style: rounded-modern with more nuance
        - Animations: responsive, low-latency, still soft
        - Button style: slightly tighter with stronger contrast
        - Backgrounds: subtle layered gradients
        - Charts: more detailed but still non-clinical
        - Empty states: reflective, self-discovery oriented
        - Loading screens: brisker than 9-13 but still gentle
        - Achievements: progress-focused and identity-safe
        - Badges: cleaner geometric tokens

        ## 17-19 Students

        - Colour palette: deeper blue, muted teal, refined neutral contrasts
        - Typography: more editorial and autonomy-driven
        - Illustration style: mature, understated, less playful
        - Card style: flatter premium cards with stronger content framing
        - Navigation style: confident and direct
        - Icon style: still rounded but slightly more precise
        - Animations: faster, cleaner, less ornamental
        - Button style: compact but still touch-safe
        - Backgrounds: sophisticated soft-neutral surfaces
        - Charts: denser insights with stronger labels
        - Empty states: autonomy and next-step oriented
        - Loading screens: minimal and efficient
        - Achievements: discreet personal milestones
        - Badges: cleaner, more mature tokens
        """,
        "Role_Guide.md": """
        # Role Guide

        ## Parents

        - Colour palette: clear blue, muted teal, parchment-neutral background
        - Typography: calm readable sans, moderate density
        - Illustration style: supportive family-adjacent metaphors, not sentimental scenes
        - Card style: summary-first cards with clear section labels
        - Navigation style: obvious destinations, minimal cognitive load
        - Icon style: legible and explanatory
        - Animations: minimal and reassuring
        - Button style: clear hierarchy, moderate weight
        - Backgrounds: clean warm neutrals
        - Charts: explanatory, text-supported, privacy-safe
        - Empty states: clarify why data is limited and what happens next
        - Loading screens: stable and low-noise
        - Achievements: rarely emphasized; use completion and guidance instead
        - Badges: mostly status or reminder treatments

        ## Teachers

        - Colour palette: structured blue, slate neutrals, controlled teal support
        - Typography: efficient and professional
        - Illustration style: minimal use; diagrams preferred over character scenes
        - Card style: flatter analytical modules
        - Navigation style: quick context switching with stable locations
        - Icon style: clean and readable at smaller sizes
        - Animations: brisk and practical
        - Button style: concise and compact
        - Backgrounds: cool-light neutral work surfaces
        - Charts: trend legibility over decoration
        - Empty states: operationally clear
        - Loading screens: subtle and fast
        - Achievements: training completion only
        - Badges: counts, states, and completion markers

        ## Counselors

        - Colour palette: trust-blue with deeper teal and slightly warmer support neutrals
        - Typography: readable with controlled density
        - Illustration style: minimal; empathetic support metaphors where appropriate
        - Card style: detail panels with clear ownership and next actions
        - Navigation style: structured and case-oriented
        - Icon style: slightly stronger severity legibility
        - Animations: calm and accountable
        - Button style: decisive and explicit
        - Backgrounds: neutral with severity accents only when needed
        - Charts: support triage and case interpretation
        - Empty states: task-oriented, not decorative
        - Loading screens: brief, status-aware
        - Achievements: not used
        - Badges: status and SLA markers

        ## Administrators

        - Colour palette: stable blue, graphite neutrals, carefully limited red
        - Typography: compact and highly legible
        - Illustration style: near-zero; diagrams and empty-state symbols preferred
        - Card style: panel-based and structured
        - Navigation style: persistent workspace orientation
        - Icon style: crisp operational set within the same rounded family
        - Animations: subtle, functional
        - Button style: compact with strong state contrast
        - Backgrounds: cooler workspace tones
        - Charts: dashboard-first and export-friendly
        - Empty states: explain system conditions and recovery actions
        - Loading screens: minimal and efficient
        - Achievements: not used
        - Badges: states, counts, review flags, audit markers
        """,
    }


def build_section_docs() -> dict[str, str]:
    return {
        "01_Brand_Identity/Brand_Identity.md": """
        # Brand Identity

        ## Mission

        Help adolescents build self-awareness and reach support earlier through a private, trusted, repeat-use digital companion.

        ## Vision

        Become the most emotionally intelligent adolescent wellbeing platform in its category: caring enough for students, clear enough for adults, and rigorous enough for clinical governance.

        ## Brand Personality

        - calm
        - trustworthy
        - warm
        - intelligent
        - protective
        - modern
        - quietly optimistic

        ## Brand Voice

        BAHA speaks clearly, never dramatizes, and always respects the user's emotional state and privacy context.

        ## Tone

        - warm when guiding
        - neutral when explaining
        - direct when safety is involved
        - efficient when operational work is primary

        ## Emotional Keywords

        - safe
        - hopeful
        - grounded
        - private
        - respectful
        - steady

        ## Visual Keywords

        - rounded
        - breathable
        - warm-neutral
        - low-noise
        - modern
        - human

        ## Interaction Keywords

        - predictable
        - assisted
        - low-pressure
        - clear
        - accountable
        """,
        "02_Emotional_Design/Emotional_Design.md": """
        # Emotional Design

        ## Objective

        Emotional design in BAHA should reduce anxiety, increase trust, and preserve dignity while never turning wellbeing into spectacle.

        ## Emotional Layers

        ### Safety

        - built through calm surfaces, predictable flow, and non-alarmist messaging

        ### Agency

        - built through clear controls, visible progress, and age-appropriate autonomy cues

        ### Warmth

        - built through soft shapes, low-glare color, and humane copy

        ### Accountability

        - built through legible operational states, restrained severity coding, and consistent action framing

        ## Emotional Rules

        - avoid celebratory overload
        - avoid fear-driven contrast spikes
        - avoid visual shame states for incomplete tasks
        - support reflection before urgency where safety allows
        """,
        "03_Illustration_System/Illustration_System.md": """
        # Illustration System

        ## Character Style

        - semi-flat soft-geometry characters
        - balanced proportions, not cartoon-stub proportions
        - expressive eyes and brows without exaggerated comedy

        ## Facial Expressions

        - curious
        - thoughtful
        - relieved
        - focused
        - reassured

        Avoid panic, despair, or overly ecstatic expressions.

        ## Poses

        - reflective seated poses
        - collaborative side-by-side poses
        - gentle walking or reading poses
        - grounded breathing or stretching poses

        ## Shapes

        - rounded rectangles
        - soft circles
        - arched frames
        - cloud-like background forms

        ## Gradients

        - warm cream to blush
        - soft sky to trust-blue
        - sage to seafoam

        ## Background Elements

        - leaves
        - stars
        - abstract paper cut shapes
        - quiet room objects
        - books, notebooks, headphones, plants

        ## Objects

        Objects should support reflection, learning, calm activity, or safe communication.

        ## Lighting

        Use diffuse, even lighting with warm ambient softness.

        ## Perspective

        Prefer eye-level or slightly elevated perspective. Avoid heroic or dramatic camera angles.

        ## Shadow Style

        - soft
        - broad
        - low contrast

        ## Outline Style

        - thin and rounded when needed
        - optional on background objects
        - stronger only for accessibility or small-size clarity

        ## Consistency Rules

        - one stroke family per scene
        - one light direction per set
        - one ratio of corner softness per collection
        - minimal texture noise
        """,
        "04_Iconography/Iconography.md": """
        # Iconography

        ## Icon Family

        Rounded humanist line icons with selective filled states.

        ## Stroke Width

        - default: 2px at 24px
        - small icon optimization: 1.75px at 16px if needed
        - filled alert symbols may drop inner strokes for clarity

        ## Rounded vs Sharp

        Rounded is the default because the product should feel approachable and non-punitive.

        Sharper geometry is allowed only in dense operational dashboards where precision matters more than emotional softness.

        ## Filled vs Outline

        - outline for default navigation and utility
        - filled for active state, critical status, and achievement emphasis

        ## Size Scale

        - 16
        - 20
        - 24
        - 32

        ## Colour Rules

        - icon color follows semantic tokens
        - red icons are restricted to owned high-severity states
        - student icons should rarely use hard black

        ## Accessibility

        - never rely on icon meaning without text in sensitive contexts
        - preserve contrast in both themes
        - ensure visible active states beyond color alone
        """,
        "05_Colour_Psychology/Colour_Psychology.md": """
        # Colour Psychology

        ## Primary Trust Blue

        Why: blue provides emotional stability, guidance, and platform confidence without sounding clinical.

        ## Calm Teal

        Why: teal connects care, breathing space, and support without becoming overly soft or childish.

        ## Warm Neutrals

        Why: off-white and paper-like backgrounds reduce glare, feel human, and support long reading sessions.

        ## Amber Guidance

        Why: amber signals caution and attention without immediately escalating to danger.

        ## Reserved Red

        Why: red is powerful and stressful, so it should only appear where an owned risk, destructive step, or explicit warning is truly present.

        ## Role Logic

        - students need emotional regulation first
        - parents need interpretive clarity first
        - teachers need information sorting first
        - BAHA staff need severity signaling first
        """,
        "06_Typography_Mood/Typography_Mood.md": """
        # Typography Mood

        ## Typographic Emotion

        BAHA typography should feel safe to read, not stylish at the expense of comprehension.

        ## Mood by Role

        - Student: open, breathable, reassuring
        - Parent: calm, explanatory, reliable
        - Teacher: practical, organized, low-drama
        - BAHA: direct, precise, dense where necessary

        ## Mood by Age Band

        - 9-13: larger and rounder rhythm
        - 14-16: balanced, slightly more expressive
        - 17-19: more editorial and self-directed

        ## Why

        Type is a major emotional signal. If the hierarchy feels crowded, sharp, or over-designed, trust drops in sensitive flows.
        """,
        "07_Imagery/Imagery.md": """
        # Imagery

        ## Photography Use

        Photography should be used sparingly and carefully.

        ## Preferred Imagery

        - hands, books, notebooks, classrooms, parks, headphones, breathing or learning contexts
        - culturally grounded but not overly staged scenes
        - neutral everyday environments

        ## Avoid

        - stock-photo therapy clichés
        - literal sadness imagery
        - clinical hospital visual cues
        - hyper-polished influencer aesthetics

        ## Treatment

        - slightly softened contrast
        - natural light
        - calm cropping
        - supportive, not performative emotion
        """,
        "08_Motion_Style/Motion_Style.md": """
        # Motion Style

        ## Page Transition Style

        - fade-through for sibling screen changes
        - shared-axis X for linear guided progress
        - shared-axis Y for list-to-detail or case workflow movement
        - shared-axis Z for deeper entry into games or immersive content

        ## Button Press

        - 96 to 98 percent scale or subtle elevation shift
        - 120ms response

        ## Ripple

        - soft, low-opacity ripple on touch surfaces
        - reduced or removed in severe support states

        ## FAB

        - reserved
        - if used later, standard motion only

        ## Cards

        - subtle lift and shadow change on press
        - no bounce

        ## Dialogs

        - fade plus slight scale
        - no spring overshoot

        ## Bottom Sheets

        - upward slide with finger-tracked dismissal

        ## Notifications

        - banner slide and fade
        - snackbar gentle rise

        ## Charts

        - short reveal on first load only
        - no constant motion loops

        ## Game Animations

        - supportive and responsive
        - never frantic

        ## Chat Animations

        - typing indicators are soft and brief
        - message send confirms clearly without playful exaggeration
        """,
        "09_Microinteractions/Microinteractions.md": """
        # Microinteractions

        ## Button Feedback

        - quick press state
        - optional loading spinner with label retention

        ## Loading

        - shimmer for content
        - pulse for isolated indicators
        - text status for waits beyond 3 seconds

        ## Pull To Refresh

        - fluid top pull with calm resistance
        - preserve filters and scroll context

        ## Check-in Completion

        - short progress settle
        - supportive completion color
        - gentle achievement reveal if applicable

        ## Achievement Unlock

        - soft pop-in
        - warm highlight
        - no confetti

        ## Message Sent

        - quick transition from draft to sent
        - failure state should be obvious and retryable

        ## Typing Indicator

        - three-dot or subtle waveform indicator
        - short-lived and low-energy

        ## Success

        - green or calm completion cue with plain-language confirmation

        ## Failure

        - clear explanation
        - visible retry
        - no alarming motion

        ## Warnings

        - amber emphasis with brief attention shift

        ## Errors

        - red only when truly needed
        - always include the next safe action
        """,
        "10_Visual_Rules/Visual_Rules.md": """
        # Visual Rules

        ## Hierarchy

        - one primary task signal per screen
        - one dominant heading zone
        - consistent relationship between headline, body, and action

        ## Whitespace

        - treat space as emotional regulation, not waste
        - student and parent surfaces should breathe more than BAHA operations

        ## Alignment

        - align to clear grids
        - keep card internals rhythmically consistent

        ## Visual Rhythm

        - repeat spacing, corner, and shadow logic consistently
        - avoid isolated special-case styling

        ## Consistency

        - same meaning should look the same across roles unless privacy or density explicitly requires variation

        ## Readability

        - support long-form wellbeing copy
        - reduce glare and crowding

        ## Accessibility

        - meet AA contrast
        - preserve focus visibility
        - keep semantic color legible in both themes

        ## Touch Targets

        - minimum 48x48 dp
        - larger for students and support-critical actions

        ## Content Density

        - lowest density for 9-13 students
        - moderate density for parents
        - higher density for teachers
        - highest density for BAHA staff
        """,
        "11_Theme_Variations/Theme_Variations.md": """
        # Theme Variations

        ## Light

        Default brand expression with warm neutral canvases and soft shadow separation.

        ## Dark

        Controlled low-light mode with deeper charcoal surfaces, softened highlights, and non-neon semantic colors.

        ## Youth Warmth Bias

        Student surfaces bias toward warmer backgrounds, larger radii, and softer gradients.

        ## Adult Clarity Bias

        Parent and teacher surfaces increase neutrality, label clarity, and content structure.

        ## Operational Focus Bias

        BAHA surfaces emphasize borders, panel separation, dense typography, and disciplined severity accents.
        """,
        "12_Figma_References/Figma_References.md": """
        # Figma References

        ## Purpose

        This section tells the future Figma build how to express the visual language without creating screens yet.

        ## Figma Structure

        - Brand and tone boards
        - Color mood boards
        - Typography expression page
        - Illustration reference page
        - Icon family page
        - Motion reference page
        - Role expression boards
        - Age-band expression boards

        ## Frame Naming

        - `Visual / Brand`
        - `Visual / Color`
        - `Visual / Type`
        - `Visual / Role / Student 9-13`
        - `Visual / Role / BAHA Ops`

        ## Rules

        - Build mood boards before screen frames.
        - Anchor all future screen styling back to this repository.
        - Use one variable system across all visual explorations.
        """,
        "13_Flutter_References/Flutter_References.md": """
        # Flutter References

        ## Purpose

        This section maps the visual language to Flutter implementation concerns before screen-level composition.

        ## Implementation Priorities

        - theme extensions for role and age-band styling
        - typography styles for calm versus dense surfaces
        - semantic color aliases rather than raw hex use
        - motion presets for guided, dashboard, and operations transitions
        - illustration and icon wrappers that preserve accessibility labels

        ## Styling Layers

        - global primitives
        - semantic theme
        - role expression overrides
        - age-band presentation overrides
        - component-level styling wrappers

        ## Rule

        Flutter should treat this visual language as a top-level styling source, not as optional decoration after feature development.
        """,
        "Mermaid/README.md": """
        # Mermaid

        - [Brand_Architecture.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/Mermaid/Brand_Architecture.mmd)
        - [Theme_Inheritance.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/Mermaid/Theme_Inheritance.mmd)
        - [Illustration_System_Map.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/Mermaid/Illustration_System_Map.mmd)
        - [Motion_Taxonomy.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/Mermaid/Motion_Taxonomy.mmd)
        - [Audience_Expression_Map.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/16_Visual_Language/Mermaid/Audience_Expression_Map.mmd)
        """,
        "Mermaid/Brand_Architecture.mmd": """
        flowchart TD
          A["BAHA Mission"] --> B["Brand Personality"]
          A --> C["Product Boundaries"]
          B --> D["Visual Language"]
          B --> E["Brand Voice"]
          C --> F["Non-Diagnostic Expression"]
          C --> G["Privacy-Safe Expression"]
          D --> H["Color Direction"]
          D --> I["Typography Direction"]
          D --> J["Illustration Direction"]
          D --> K["Motion Direction"]
          H --> L["Role Themes"]
          I --> L
          J --> L
          K --> L
        """,
        "Mermaid/Theme_Inheritance.mmd": """
        flowchart LR
          A["Core Visual Base"] --> B["Light Theme"]
          A --> C["Dark Theme"]
          B --> D["Student Expression"]
          B --> E["Parent Expression"]
          B --> F["Teacher Expression"]
          B --> G["BAHA Expression"]
          C --> H["Dark Student"]
          C --> I["Dark Parent"]
          C --> J["Dark Teacher"]
          C --> K["Dark BAHA"]
          D --> L["9-13"]
          D --> M["14-16"]
          D --> N["17-19"]
        """,
        "Mermaid/Illustration_System_Map.mmd": """
        mindmap
          root((Illustration System))
            Characters
              Soft geometry
              Mature proportions
              Broad representation
            Emotion
              Calm
              Curious
              Reassured
              Focused
            Environment
              Warm interiors
              Learning objects
              Nature accents
            Form
              Rounded shapes
              Gentle gradients
              Soft shadows
            Limits
              No panic imagery
              No medical drama
              No infantilization
        """,
        "Mermaid/Motion_Taxonomy.mmd": """
        flowchart TD
          A["Motion System"] --> B["Route Motion"]
          A --> C["Component Motion"]
          A --> D["Feedback Motion"]
          A --> E["Specialized Motion"]
          B --> B1["Fade Through"]
          B --> B2["Shared Axis X"]
          B --> B3["Shared Axis Y"]
          B --> B4["Shared Axis Z"]
          C --> C1["Button Press"]
          C --> C2["Card Lift"]
          C --> C3["Dialog Entry"]
          C --> C4["Sheet Entry"]
          D --> D1["Success"]
          D --> D2["Warning"]
          D --> D3["Error"]
          E --> E1["Breathing Pulse"]
          E --> E2["Typing Indicator"]
          E --> E3["Achievement Reveal"]
        """,
        "Mermaid/Audience_Expression_Map.mmd": """
        flowchart TD
          A["Visual Language"] --> B["Students 9-13"]
          A --> C["Students 14-16"]
          A --> D["Students 17-19"]
          A --> E["Parents"]
          A --> F["Teachers"]
          A --> G["Counselors"]
          A --> H["Administrators"]
          B --> B1["Soft warmth"]
          C --> C1["Identity and reflection"]
          D --> D1["Autonomy and clarity"]
          E --> E1["Guidance and trust"]
          F --> F1["Pattern recognition"]
          G --> G1["Calm authority"]
          H --> H1["Operational precision"]
        """,
    }


def build_age_role_appendix() -> tuple[str, str]:
    age_table = """
    # Age and Role Appendix

    ## Students by Age Band

    | Audience | Color Emphasis | Type Mood | Illustration Mood | Motion Mood | Badge Mood |
    |---|---|---|---|---|---|
    | 9-13 | warm sky, seafoam, peach | open and rounded | friendly and guided | soft and slower | warm and playful but private |
    | 14-16 | richer blue, balanced teal | balanced and reflective | expressive and identity-safe | responsive and smooth | cleaner and more self-owned |
    | 17-19 | deeper blue, refined neutrals | editorial and self-directed | mature and understated | brisk and subtle | discreet and premium |

    ## Adults by Role

    | Audience | Color Emphasis | Type Mood | Illustration Mood | Motion Mood | Badge Mood |
    |---|---|---|---|---|---|
    | Parent | clarity blue, muted teal | calm and readable | minimal metaphor | low-noise | status-oriented |
    | Teacher | blue plus slate | practical and compact | near-minimal | brisk and functional | analytic and completion-oriented |
    | Counselor | trust blue plus deeper teal | composed and accountable | minimal empathetic metaphor | calm and steady | ownership and urgency-aware |
    | Administrator | structured blue plus graphite | dense and precise | diagram-first | efficient and restrained | state and workflow-focused |
    """

    role_detail = """
    # Role Expression Appendix

    ## Student Expression

    Student styling should always be emotionally safer than it is visually clever.

    ## Parent Expression

    Parent styling should reduce ambiguity around privacy, summaries, and next-step conversations.

    ## Teacher Expression

    Teacher styling should support interpretation and action without exposing individual-sensitive detail.

    ## Counselor Expression

    Counselor styling should balance empathy with professional confidence and operational ownership.

    ## Administrator Expression

    Administrator styling should maximize legibility, traceability, and controlled severity communication.
    """
    return age_table, role_detail


def build_mermaid_validation_targets() -> list[Path]:
    return sorted((VISUAL_ROOT / "Mermaid").glob("*.mmd"))


def validate_mermaid() -> None:
    allowed = ("flowchart", "sequenceDiagram", "stateDiagram-v2", "mindmap", "erDiagram")
    for path in build_mermaid_validation_targets():
        text = path.read_text(encoding="utf-8").strip()
        if not text.startswith(allowed):
            raise SystemExit(f"Mermaid validation failed for {path.name}")


def main() -> None:
    for relative, content in build_root_docs().items():
        write(VISUAL_ROOT / relative, content)

    for relative, content in build_section_docs().items():
        write(VISUAL_ROOT / relative, content)

    age_appendix, role_appendix = build_age_role_appendix()
    write(VISUAL_ROOT / "11_Theme_Variations" / "Age_and_Role_Appendix.md", age_appendix)
    write(VISUAL_ROOT / "13_Flutter_References" / "Role_Expression_Appendix.md", role_appendix)

    validate_mermaid()

    print(f"Generated visual language at {VISUAL_ROOT}")
    print("Core guides: 10")
    print("Mermaid diagrams: 5")


if __name__ == "__main__":
    main()
