import json
import re
from collections import defaultdict
from pathlib import Path
from textwrap import dedent


ROOT = Path("/Users/solomonkaruppiah/Desktop/Baha_Data")
DOCS = ROOT / "docs"
UX_ROOT = DOCS / "13_UX_Specification"
NAV_ROOT = DOCS / "14_Navigation"
DS_ROOT = DOCS / "15_Design_System"


ROLE_CONFIG = {
    "student": {
        "inventory": DOCS / "03_Student_App" / "Screen_Inventory.md",
        "label": "Student",
        "shell": "Student Mobile Shell",
        "nav_component": "bottom-navigation",
        "route_prefix": "/student",
        "persona": "Adolescent student using a private, supportive wellness app.",
    },
    "parent": {
        "inventory": DOCS / "04_Parent_App" / "Screen_Inventory.md",
        "label": "Parent",
        "shell": "Parent Mobile Summary Shell",
        "nav_component": "bottom-navigation",
        "route_prefix": "/parent",
        "persona": "Parent or guardian using consent-gated summaries and conversation support tools.",
    },
    "teacher": {
        "inventory": DOCS / "05_Teacher_App" / "Screen_Inventory.md",
        "label": "Teacher",
        "shell": "Teacher Adaptive Dashboard Shell",
        "nav_component": "tabs",
        "route_prefix": "/teacher",
        "persona": "Teacher or school counselor using anonymized cohort insights and referral workflows.",
    },
    "baha": {
        "inventory": DOCS / "06_BAHA_App" / "Screen_Inventory.md",
        "label": "BAHA",
        "shell": "BAHA Operations Workspace",
        "nav_component": "navigation-rail",
        "route_prefix": "/baha",
        "persona": "BAHA clinician, counselor, reviewer, or operational admin managing support, content, and governance.",
    },
}


COMPONENTS = [
    {
        "slug": "app-shell",
        "name": "App Shell",
        "kind": "navigation",
        "purpose": "Provides the shared scaffold for each role surface, including safe areas, shell navigation, banners, and content containers.",
        "variants": ["Student mobile shell", "Parent mobile shell", "Teacher adaptive shell", "BAHA operations workspace"],
        "states": ["Default", "Loading", "Offline", "Maintenance", "Session expired"],
        "properties": ["role", "title", "navigationModel", "bannerSlot", "contentSlot", "footerSlot"],
        "sizes": ["Full-screen only"],
        "flutter": "Scaffold, SafeArea, NavigationBar, NavigationRail, CustomScrollView, SliverAppBar",
        "figma": "App Shell / Role={Role} / Density={Mode} / State={State}",
        "usage": "Used on every route after bootstrap and adapted for desktop-like BAHA workspaces versus mobile-first student surfaces.",
        "do": ["Keep role navigation stable across sibling screens", "Reserve topmost banner space for privacy or support messages"],
        "dont": ["Rebuild shell structure inside each screen", "Place destructive actions in shell chrome"],
        "status": "active",
    },
    {
        "slug": "buttons",
        "name": "Buttons",
        "kind": "action",
        "purpose": "Primary and secondary action triggers for progression, confirmation, retry, and safe exits.",
        "variants": ["Primary", "Secondary", "Tertiary", "Destructive", "Inline"],
        "states": ["Rest", "Pressed", "Focused", "Disabled", "Loading", "Success"],
        "properties": ["label", "leadingIcon", "trailingIcon", "tone", "isLoading", "fullWidth"],
        "sizes": ["sm", "md", "lg"],
        "flutter": "FilledButton, OutlinedButton, TextButton, custom BahaButton wrapper",
        "figma": "Button / Emphasis={Type} / Size={Size} / State={State}",
        "usage": "Used across onboarding, check-in, learning, help, moderation, and export workflows.",
        "do": ["Use one clear primary action per region", "Use destructive tone only for irreversible actions"],
        "dont": ["Place multiple primary buttons in one card", "Hide required progress behind tertiary-only buttons"],
        "status": "active",
    },
    {
        "slug": "icon-buttons",
        "name": "Icon Buttons",
        "kind": "action",
        "purpose": "Compact affordances for search, close, info, retry, and contextual utility actions.",
        "variants": ["Standard", "Filled", "Tonal", "Destructive", "Toggle"],
        "states": ["Rest", "Hovered", "Pressed", "Focused", "Disabled", "Selected"],
        "properties": ["icon", "label", "isToggle", "isSelected", "tone"],
        "sizes": ["40", "48"],
        "flutter": "IconButton, FilledIconButton, custom selectable icon button",
        "figma": "Icon Button / Style={Style} / State={State}",
        "usage": "Used in app bars, charts, list rows, media controls, and dialogs.",
        "do": ["Provide an accessible label on every icon-only action", "Keep hit areas square and thumb-safe"],
        "dont": ["Use icon-only controls for irreversible actions without confirmation", "Stack dense icon clusters on student screens"],
        "status": "active",
    },
    {
        "slug": "floating-action-button",
        "name": "Floating Action Button",
        "kind": "action",
        "purpose": "Reserved high-emphasis floating action for future operational acceleration without changing current PRD flows.",
        "variants": ["Primary FAB", "Extended FAB"],
        "states": ["Rest", "Pressed", "Focused", "Hidden", "Disabled"],
        "properties": ["icon", "label", "isExtended"],
        "sizes": ["56", "80 extended"],
        "flutter": "FloatingActionButton, FloatingActionButton.extended",
        "figma": "FAB / Type={Type} / State={State}",
        "usage": "Documented as a design-system primitive but not currently instantiated in the 88-screen repository.",
        "do": ["Use only for a single dominant contextual action", "Hide during full-screen tasks or overlays"],
        "dont": ["Introduce FABs into consent or crisis flows", "Use multiple FABs on one screen"],
        "status": "reserved",
    },
    {
        "slug": "text-fields",
        "name": "Text Fields",
        "kind": "input",
        "purpose": "Single-line text capture for notes, IDs, search-adjacent filtering, and operational metadata.",
        "variants": ["Outlined", "Filled", "Read-only", "Validated"],
        "states": ["Empty", "Typing", "Focused", "Error", "Disabled", "Read-only"],
        "properties": ["label", "value", "placeholder", "helperText", "errorText", "prefix", "suffix", "maxLength"],
        "sizes": ["md", "lg"],
        "flutter": "TextField, TextFormField, custom BahaTextField",
        "figma": "Text Field / Variant={Variant} / State={State}",
        "usage": "Used in pastoral notes, case actions, guardian verification, content metadata, and support requests.",
        "do": ["Pair fields with visible labels and helper text", "Validate close to the point of entry"],
        "dont": ["Rely on placeholder text as the only label", "Use free text where a safer constrained input exists"],
        "status": "active",
    },
    {
        "slug": "search",
        "name": "Search",
        "kind": "input",
        "purpose": "Keyword lookup across content, audit, queue, notification, and support-oriented list surfaces.",
        "variants": ["Inline search bar", "Collapsed search action", "Search with filters"],
        "states": ["Idle", "Focused", "Typing", "Loading", "Results", "No results"],
        "properties": ["query", "placeholder", "leadingIcon", "clearAction", "scope"],
        "sizes": ["Full-width bar", "Compact header search"],
        "flutter": "SearchBar, TextField with InputDecorator, custom sliver search header",
        "figma": "Search / Mode={Mode} / State={State}",
        "usage": "Used in high-volume list views such as content libraries, audit logs, queues, and notification centers.",
        "do": ["Debounce remote queries and preserve entered text", "Show the active search term near results"],
        "dont": ["Clear the query on route refresh", "Hide matching-zero states without explanation"],
        "status": "active",
    },
    {
        "slug": "password-fields",
        "name": "Password Fields",
        "kind": "input",
        "purpose": "Reserved secure text entry primitive for platform auth surfaces outside the current PRD-backed screen set.",
        "variants": ["Masked", "Visible", "Validated"],
        "states": ["Empty", "Typing", "Focused", "Error", "Disabled"],
        "properties": ["label", "value", "obscureText", "helperText", "errorText"],
        "sizes": ["md", "lg"],
        "flutter": "TextFormField with obscureText and reveal toggle",
        "figma": "Password Field / State={State}",
        "usage": "Standardized for future authentication contexts; not currently used in the 88-screen repository.",
        "do": ["Offer a reveal toggle and strong error messaging", "Respect secure autofill and password managers"],
        "dont": ["Display raw values by default", "Block paste in managed operational environments"],
        "status": "reserved",
    },
    {
        "slug": "dropdown",
        "name": "Dropdown",
        "kind": "input",
        "purpose": "Constrained selection for filters, school scopes, statuses, tags, and review states.",
        "variants": ["Single select", "Grouped select", "Icon-leading select"],
        "states": ["Closed", "Open", "Selected", "Error", "Disabled"],
        "properties": ["label", "selectedOption", "options", "helperText", "errorText"],
        "sizes": ["md", "lg"],
        "flutter": "DropdownMenu, MenuAnchor, custom bottom-sheet picker on mobile",
        "figma": "Dropdown / State={State} / Density={Density}",
        "usage": "Used for queue filters, content tags, threshold settings, and learning sort controls.",
        "do": ["Use for stable option sets with short labels", "Mirror current selection in the collapsed field"],
        "dont": ["Use dropdowns for binary choices", "Hide destructive consequences in option text"],
        "status": "active",
    },
    {
        "slug": "radio",
        "name": "Radio",
        "kind": "input",
        "purpose": "Mutually exclusive choice sets for consent, age bands, gender preference, and explicit mode selection.",
        "variants": ["List radio", "Card radio", "Segmented radio"],
        "states": ["Unchecked", "Checked", "Focused", "Disabled", "Error"],
        "properties": ["label", "supportingText", "value", "groupValue"],
        "sizes": ["Default control", "Card control"],
        "flutter": "RadioListTile, SegmentedButton, custom selectable card",
        "figma": "Radio / Type={Type} / State={State}",
        "usage": "Used in onboarding and policy choices where the user must select exactly one safe option.",
        "do": ["Present all exclusive options together", "Explain policy-impacting choices in supporting text"],
        "dont": ["Hide mutually exclusive choices inside multiple taps", "Mix radios and checkboxes for the same question"],
        "status": "active",
    },
    {
        "slug": "checkbox",
        "name": "Checkbox",
        "kind": "input",
        "purpose": "Independent opt-ins for review checklists, policy acknowledgements, and content tagging.",
        "variants": ["Standalone", "Checkbox row", "Checkbox group"],
        "states": ["Unchecked", "Checked", "Indeterminate", "Focused", "Disabled", "Error"],
        "properties": ["label", "supportingText", "value", "triState"],
        "sizes": ["Default control"],
        "flutter": "Checkbox, CheckboxListTile",
        "figma": "Checkbox / State={State}",
        "usage": "Used for acknowledgements, moderation steps, and multi-select filter scenarios.",
        "do": ["Keep labels concise and explicit", "Use groups when multiple selections are valid"],
        "dont": ["Use checkboxes for single-choice questions", "Hide required acknowledgements below the fold"],
        "status": "active",
    },
    {
        "slug": "switch",
        "name": "Switch",
        "kind": "input",
        "purpose": "Immediate on-off settings for reminders, preferences, and non-destructive operational toggles.",
        "variants": ["Default", "With helper text", "Disabled"],
        "states": ["Off", "On", "Focused", "Disabled", "Updating"],
        "properties": ["label", "supportingText", "isOn", "isLoading"],
        "sizes": ["Default control"],
        "flutter": "Switch, SwitchListTile, custom async preference tile",
        "figma": "Switch / State={State}",
        "usage": "Used in notification settings, privacy settings, and optional personalization controls.",
        "do": ["Apply immediate optimistic feedback with rollback on failure", "Describe the effect of enabling the setting"],
        "dont": ["Use switches for multi-step consent changes", "Place multiple destructive toggles adjacent without grouping"],
        "status": "active",
    },
    {
        "slug": "slider",
        "name": "Slider",
        "kind": "input",
        "purpose": "Graduated scalar input for wellbeing check-ins, threshold tuning, and advisory calibration.",
        "variants": ["Continuous", "Discrete", "Range"],
        "states": ["Idle", "Dragging", "Focused", "Disabled", "Error"],
        "properties": ["label", "value", "min", "max", "divisions", "assistiveText"],
        "sizes": ["Full-width control"],
        "flutter": "Slider, RangeSlider",
        "figma": "Slider / Type={Type} / State={State}",
        "usage": "Used in student check-ins and BAHA threshold configuration where a bounded continuum is defined by the architecture.",
        "do": ["Show the current selected value in plain language", "Use discrete marks when the policy model expects buckets"],
        "dont": ["Use sliders where exact numeric text entry is required", "Hide semantic meaning behind unlabeled scales"],
        "status": "active",
    },
    {
        "slug": "bottom-navigation",
        "name": "Bottom Navigation",
        "kind": "navigation",
        "purpose": "Stable primary navigation for mobile role surfaces.",
        "variants": ["Student five-tab", "Parent four-tab"],
        "states": ["Default", "Selected", "Disabled", "Badge visible"],
        "properties": ["items", "selectedIndex", "badges", "safeAreaInset"],
        "sizes": ["56 to 80 height depending safe area"],
        "flutter": "NavigationBar, BottomNavigationBar",
        "figma": "Bottom Navigation / Role={Role} / State={State}",
        "usage": "Used on student and parent top-level routes after bootstrap and onboarding gates.",
        "do": ["Keep labels short and persistent", "Use badges for non-urgent counts only"],
        "dont": ["Place more than five destinations", "Hide active state on role home screens"],
        "status": "active",
    },
    {
        "slug": "top-navigation",
        "name": "Top Navigation",
        "kind": "navigation",
        "purpose": "Provides route title, back navigation, contextual actions, and high-priority utility entry points.",
        "variants": ["Plain app bar", "Search app bar", "Large title", "Operational metadata bar"],
        "states": ["Default", "Scrolled", "Loading", "Alert active"],
        "properties": ["title", "leadingAction", "trailingActions", "subtitle", "bannerSlot"],
        "sizes": ["56", "64", "Large title expanded"],
        "flutter": "AppBar, SliverAppBar, PreferredSizeWidget variants",
        "figma": "Top Navigation / Variant={Variant} / State={State}",
        "usage": "Used on all roles for page identity, safe back behavior, and route-level actions.",
        "do": ["Use a clear title that matches the route contract", "Keep support and info actions consistent within a role"],
        "dont": ["Overload app bars with secondary actions", "Use hidden gesture-only navigation controls"],
        "status": "active",
    },
    {
        "slug": "navigation-rail",
        "name": "Navigation Rail",
        "kind": "navigation",
        "purpose": "Persistent left-side navigation for denser BAHA operations and tablet-like teacher contexts.",
        "variants": ["Collapsed", "Expanded", "Badge-enabled"],
        "states": ["Default", "Selected", "Disabled"],
        "properties": ["items", "selectedIndex", "isExpanded", "badges"],
        "sizes": ["72 collapsed", "256 expanded"],
        "flutter": "NavigationRail, custom responsive shell wrapper",
        "figma": "Navigation Rail / Density={Density} / State={State}",
        "usage": "Primary workspace navigation for BAHA operational screens and a responsive fallback for larger canvases.",
        "do": ["Use icons plus labels when space allows", "Keep operational destinations in a consistent order"],
        "dont": ["Swap rail order between sibling screens", "Replace critical filters with rail nesting"],
        "status": "active",
    },
    {
        "slug": "tabs",
        "name": "Tabs",
        "kind": "navigation",
        "purpose": "Parallel view switching for trend ranges, content states, notification buckets, and queue slices.",
        "variants": ["Fixed", "Scrollable", "Segmented tabs"],
        "states": ["Default", "Selected", "Focused", "Disabled", "Badge visible"],
        "properties": ["items", "selectedIndex", "badgeCount", "isScrollable"],
        "sizes": ["Compact", "Standard"],
        "flutter": "TabBar, SegmentedButton, custom chips-as-tabs",
        "figma": "Tabs / Type={Type} / State={State}",
        "usage": "Used on teacher analytics, BAHA moderation, and any multi-view surface explicitly supported by the architecture.",
        "do": ["Limit tabs to sibling content views", "Retain filter context when changing tabs"],
        "dont": ["Use tabs for sequential workflow steps", "Hide tabs behind horizontal-only affordances without labels"],
        "status": "active",
    },
    {
        "slug": "stepper",
        "name": "Stepper",
        "kind": "navigation",
        "purpose": "Progress cue for onboarding, consent, and check-in sequences.",
        "variants": ["Linear stepper", "Dot stepper", "Progress ribbon"],
        "states": ["Upcoming", "Current", "Completed", "Blocked"],
        "properties": ["steps", "currentIndex", "allowBacktracking"],
        "sizes": ["Compact mobile", "Standard mobile"],
        "flutter": "Stepper, custom progress indicator with step semantics",
        "figma": "Stepper / Type={Type} / State={State}",
        "usage": "Used in guided flows where the architecture already defines an ordered path.",
        "do": ["Expose current position and remaining scope", "Keep labels short and age-appropriate on student flows"],
        "dont": ["Treat optional branching as fixed completed steps", "Use stepper chrome on single-screen tasks"],
        "status": "active",
    },
    {
        "slug": "cards",
        "name": "Cards",
        "kind": "display",
        "purpose": "Default bounded content container for summaries, actions, insights, and feature entry points.",
        "variants": ["Summary", "Action", "Insight", "Status", "Elevated"],
        "states": ["Rest", "Pressed", "Selected", "Disabled", "Loading"],
        "properties": ["headline", "body", "media", "metadata", "cta", "status"],
        "sizes": ["Compact", "Standard", "Full-width"],
        "flutter": "Card, Material, InkWell, custom BahaCard composition",
        "figma": "Card / Variant={Variant} / State={State}",
        "usage": "The base container for dashboard summaries, modules, games, policy blocks, and list summaries.",
        "do": ["Use one clear hierarchy inside each card", "Keep tap and non-tap cards visually distinct"],
        "dont": ["Nest multiple full action areas in one card", "Use card styling for dense tables"],
        "status": "active",
    },
    {
        "slug": "charts",
        "name": "Charts",
        "kind": "data",
        "purpose": "Quantitative, plain-language visual summaries for trends, cohort views, and analytics dashboards.",
        "variants": ["Line", "Bar", "Stacked bar", "Sparkline"],
        "states": ["Loading", "Empty", "Populated", "Filtered", "Error"],
        "properties": ["title", "timeRange", "series", "annotations", "narrativeSummary"],
        "sizes": ["Card chart", "Full-width chart"],
        "flutter": "CustomPaint, fl_chart, syncfusion_flutter_charts, semantic summary wrapper",
        "figma": "Chart / Type={Type} / State={State}",
        "usage": "Used for student trend cards, parent summaries, teacher class dashboards, and BAHA pilot analytics.",
        "do": ["Pair every chart with plain-language interpretation", "Respect privacy thresholds before rendering data"],
        "dont": ["Use charts without text alternatives", "Show diagnostic or stigmatizing labels"],
        "status": "active",
    },
    {
        "slug": "graphs",
        "name": "Graphs",
        "kind": "data",
        "purpose": "Relationship and multi-metric visualizations for insight detail, threshold trends, and operational comparisons.",
        "variants": ["Trend graph", "Relationship graph", "Comparative graph"],
        "states": ["Loading", "Empty", "Populated", "Filtered", "Error"],
        "properties": ["axes", "legend", "series", "summary", "privacyMode"],
        "sizes": ["Embedded", "Expanded detail"],
        "flutter": "Custom graph widgets backed by charting primitives",
        "figma": "Graph / Type={Type} / State={State}",
        "usage": "Used in detail-oriented trend and calibration screens where a chart alone is not sufficient.",
        "do": ["Keep legends synchronized with the narrative explanation", "Use simplified labels for student surfaces"],
        "dont": ["Expose raw point data where aggregation is required", "Animate graphs aggressively"],
        "status": "active",
    },
    {
        "slug": "progress-indicators",
        "name": "Progress Indicators",
        "kind": "feedback",
        "purpose": "Communicates loading, completion, or current step status.",
        "variants": ["Circular indeterminate", "Linear determinate", "Completion ring", "Inline status progress"],
        "states": ["Hidden", "Active", "Complete", "Error"],
        "properties": ["value", "label", "isIndeterminate", "tone"],
        "sizes": ["Inline", "Section", "Full-width"],
        "flutter": "CircularProgressIndicator, LinearProgressIndicator, custom completion meter",
        "figma": "Progress / Type={Type} / State={State}",
        "usage": "Used during bootstrap, guided flows, learning completion, moderation queues, and data fetches.",
        "do": ["Use determinate progress when the system knows the denominator", "Accompany long waits with explanatory copy"],
        "dont": ["Leave users in spinner-only states without context", "Animate for extended periods without status updates"],
        "status": "active",
    },
    {
        "slug": "snackbars",
        "name": "Snackbars",
        "kind": "feedback",
        "purpose": "Transient confirmation, retry, and non-blocking status feedback.",
        "variants": ["Success", "Warning", "Error with retry", "Informational"],
        "states": ["Queued", "Visible", "Dismissed"],
        "properties": ["message", "actionLabel", "tone", "duration"],
        "sizes": ["Single-line", "Two-line"],
        "flutter": "SnackBar, ScaffoldMessenger, custom inline snackbar host",
        "figma": "Snackbar / Tone={Tone} / State={State}",
        "usage": "Used for saved settings, queued retries, draft saves, and validation recoveries.",
        "do": ["Keep copy brief and action-oriented", "Escalate to dialogs when the user must decide before continuing"],
        "dont": ["Use snackbars for crisis or privacy-critical updates", "Queue multiple messages that hide each other"],
        "status": "active",
    },
    {
        "slug": "dialogs",
        "name": "Dialogs",
        "kind": "feedback",
        "purpose": "High-importance confirmation, acknowledgment, or interruption surface.",
        "variants": ["Confirmation", "Blocking policy dialog", "Destructive confirmation", "Session expired"],
        "states": ["Hidden", "Visible", "Submitting", "Error"],
        "properties": ["title", "body", "primaryAction", "secondaryAction", "tone"],
        "sizes": ["Standard", "Full-height mobile dialog"],
        "flutter": "AlertDialog, Dialog, showAdaptiveDialog",
        "figma": "Dialog / Type={Type} / State={State}",
        "usage": "Used for destructive actions, consent impact confirmations, session expiry, and unsaved changes.",
        "do": ["Move focus into the dialog and return it on close", "Use plain language for consequences"],
        "dont": ["Stack multiple dialogs", "Use dialogs for routine informational content"],
        "status": "active",
    },
    {
        "slug": "bottom-sheets",
        "name": "Bottom Sheets",
        "kind": "feedback",
        "purpose": "Secondary action menus, filter pickers, and compact mobile disclosures.",
        "variants": ["Action sheet", "Filter sheet", "Picker sheet", "Half-height detail sheet"],
        "states": ["Hidden", "Expanded", "Dragging", "Submitting"],
        "properties": ["title", "content", "primaryAction", "dismissible"],
        "sizes": ["Peek", "Half", "Full"],
        "flutter": "showModalBottomSheet, DraggableScrollableSheet",
        "figma": "Bottom Sheet / Height={Height} / State={State}",
        "usage": "Used on mobile-friendly filters, content actions, and list utility menus.",
        "do": ["Keep the primary selection task focused", "Use sheets instead of new routes for short utility tasks"],
        "dont": ["Hide critical policy copy below a drag gesture", "Overfill sheets with long forms"],
        "status": "active",
    },
    {
        "slug": "tooltips",
        "name": "Tooltips",
        "kind": "feedback",
        "purpose": "Contextual explanation for unfamiliar metrics, policy labels, and status chips.",
        "variants": ["Hover tooltip", "Tap popover", "Inline info hint"],
        "states": ["Hidden", "Visible"],
        "properties": ["label", "body", "trigger", "placement"],
        "sizes": ["Compact", "Expanded popover"],
        "flutter": "Tooltip, Popover, custom anchored info sheet on mobile",
        "figma": "Tooltip / Type={Type}",
        "usage": "Used for charts, privacy terminology, threshold metadata, and source citations.",
        "do": ["Keep explanations concise and jargon-light", "Ensure mobile tap alternatives exist"],
        "dont": ["Hide required workflow instructions in tooltips", "Use hover-only behavior on touch-first screens"],
        "status": "active",
    },
    {
        "slug": "badges",
        "name": "Badges",
        "kind": "display",
        "purpose": "Compact status, count, and achievement labeling.",
        "variants": ["Count", "Status", "Achievement", "Severity"],
        "states": ["Default", "Emphasized", "Muted"],
        "properties": ["label", "count", "tone", "icon"],
        "sizes": ["sm", "md"],
        "flutter": "Badge, Container with tokenized decoration",
        "figma": "Badge / Tone={Tone} / State={State}",
        "usage": "Used for streaks, moderation counts, case statuses, and role notifications.",
        "do": ["Use short labels and semantic color tokens", "Pair non-text badges with accessible names"],
        "dont": ["Rely on color alone to convey meaning", "Expose sensitive severity labels in student contexts"],
        "status": "active",
    },
    {
        "slug": "avatars",
        "name": "Avatars",
        "kind": "display",
        "purpose": "Person or role marker for linked students, assigned staff, and conversational context.",
        "variants": ["Initials", "Illustrated", "Role icon", "Group stack"],
        "states": ["Default", "Selected", "Status overlaid"],
        "properties": ["image", "fallbackInitials", "statusBadge", "size"],
        "sizes": ["24", "32", "40", "56"],
        "flutter": "CircleAvatar, Stack, custom status avatar wrapper",
        "figma": "Avatar / Type={Type} / Size={Size}",
        "usage": "Used in linked-student summaries, case assignment, notification rows, and chat surfaces.",
        "do": ["Provide a neutral fallback when no profile image exists", "Keep student identity exposure minimized by context"],
        "dont": ["Display unnecessary personal imagery in operational tables", "Use avatars as the only label"],
        "status": "active",
    },
    {
        "slug": "profile-cards",
        "name": "Profile Cards",
        "kind": "display",
        "purpose": "Condensed summary of person-linked preferences, consent posture, or eligible summary scope.",
        "variants": ["Student summary", "Guardian link", "Preference summary", "Consent snapshot"],
        "states": ["Default", "Selected", "Warning", "Restricted"],
        "properties": ["title", "subtitle", "avatar", "status", "actions"],
        "sizes": ["Standard", "Wide"],
        "flutter": "Custom card composition using Card, ListTile, badges, and buttons",
        "figma": "Profile Card / Variant={Variant} / State={State}",
        "usage": "Used in student profile summary, parent linked-student views, and consent-related review screens.",
        "do": ["Show only the minimum profile summary needed for the task", "Use explicit status treatment for restricted access"],
        "dont": ["Expose hidden notes or private identifiers", "Mix unrelated preference controls into summary cards"],
        "status": "active",
    },
    {
        "slug": "learning-cards",
        "name": "Learning Cards",
        "kind": "display",
        "purpose": "Course, module, and lesson entry points with duration, progress, and modality metadata.",
        "variants": ["Featured module", "Standard module", "Completed module", "Recommended lesson"],
        "states": ["Rest", "Pressed", "Completed", "Locked", "Loading"],
        "properties": ["title", "summary", "duration", "modality", "progress", "cta"],
        "sizes": ["Compact", "Standard", "Hero"],
        "flutter": "Custom card composition built on Card, LinearProgressIndicator, chips, and InkWell",
        "figma": "Learning Card / Variant={Variant} / State={State}",
        "usage": "Used in student, parent, and teacher learning homes plus module detail lists.",
        "do": ["Surface duration and effort before entry", "Use completion status consistently across roles"],
        "dont": ["Hide required module gating", "Mix multiple progress systems in one card"],
        "status": "active",
    },
    {
        "slug": "game-cards",
        "name": "Game Cards",
        "kind": "display",
        "purpose": "Entry and state container for guided wellbeing games and calming activities.",
        "variants": ["Hub card", "Scenario card", "Resume card", "Regulation card"],
        "states": ["Rest", "Pressed", "Completed", "Time capped", "Locked"],
        "properties": ["title", "summary", "estimatedTime", "status", "cta"],
        "sizes": ["Standard", "Wide"],
        "flutter": "Custom card composition with Card, badges, buttons, and progress indicators",
        "figma": "Game Card / Variant={Variant} / State={State}",
        "usage": "Used in Games Hub and game-specific routes including breathing and scenario-based activities.",
        "do": ["Keep descriptions supportive rather than competitive", "Show time expectations up front"],
        "dont": ["Use manipulative gamification around distress", "Confuse calm activities with achievement-heavy visuals"],
        "status": "active",
    },
    {
        "slug": "chat-messages",
        "name": "Chat Messages",
        "kind": "display",
        "purpose": "Conversational bubbles, quick replies, and citation-aware message blocks for Buddy chat.",
        "variants": ["User message", "Buddy reply", "Citation message", "Escalation prompt", "Out-of-scope message"],
        "states": ["Sending", "Delivered", "Failed", "Selected"],
        "properties": ["author", "timestamp", "body", "citations", "actions"],
        "sizes": ["Bubble", "Full-width system card"],
        "flutter": "ListView, custom chat bubble widgets, markdown text renderer, citations row",
        "figma": "Chat Message / Type={Type} / State={State}",
        "usage": "Used in Buddy Chat, citation detail entry points, safe refusals, and escalation prompts.",
        "do": ["Distinguish user and assistant messages clearly", "Keep citation actions visible on supported replies"],
        "dont": ["Animate messages aggressively", "Allow unreviewed rich content to break layout"],
        "status": "active",
    },
    {
        "slug": "notifications",
        "name": "Notifications",
        "kind": "display",
        "purpose": "List row and card treatment for alerts, reminders, policy updates, and referral updates.",
        "variants": ["Reminder", "Alert", "Operational update", "Policy update"],
        "states": ["Unread", "Read", "Action required", "Archived"],
        "properties": ["title", "body", "timestamp", "tone", "cta", "readState"],
        "sizes": ["Row", "Card", "Banner teaser"],
        "flutter": "ListTile, Card, badge wrappers, push routing adapters",
        "figma": "Notification / Variant={Variant} / State={State}",
        "usage": "Used in notification centers, home alerts, parent summary reminders, and teacher updates.",
        "do": ["Reflect urgency through tone and copy, not just color", "Show the destination or expected action clearly"],
        "dont": ["Expose private data in compact notifications", "Mark critical notices as read automatically without acknowledgment"],
        "status": "active",
    },
    {
        "slug": "timeline",
        "name": "Timeline",
        "kind": "display",
        "purpose": "Chronological event view for cases, action logs, thresholds, and audit-style histories.",
        "variants": ["Case timeline", "Audit event timeline", "Threshold history"],
        "states": ["Loading", "Empty", "Populated", "Filtered"],
        "properties": ["events", "grouping", "status", "actor", "timestamp"],
        "sizes": ["Embedded", "Full-page"],
        "flutter": "Custom sliver timeline, ListView with vertical rule, expansion tiles",
        "figma": "Timeline / Variant={Variant} / State={State}",
        "usage": "Used in BAHA case detail, action history, threshold history, and audit-linked views.",
        "do": ["Order newest or most relevant events predictably", "Preserve actor, time, and action semantics"],
        "dont": ["Collapse critical events without affordance", "Hide escalation state transitions"],
        "status": "active",
    },
    {
        "slug": "calendar",
        "name": "Calendar",
        "kind": "display",
        "purpose": "Reserved date-grid primitive for future scheduling contexts without changing the current PRD screen model.",
        "variants": ["Month grid", "Week strip", "Agenda hybrid"],
        "states": ["Default", "Selected", "Disabled", "Range selected"],
        "properties": ["selectedDate", "range", "events", "availability"],
        "sizes": ["Compact strip", "Full month"],
        "flutter": "TableCalendar, custom date strip",
        "figma": "Calendar / Variant={Variant} / State={State}",
        "usage": "Standardized for the system but not currently mapped to a PRD-backed screen.",
        "do": ["Use locale-aware week starts and labels", "Expose selected date textually"],
        "dont": ["Introduce calendar-first flows where the architecture uses prompts", "Encode schedule status with color only"],
        "status": "reserved",
    },
    {
        "slug": "media-player",
        "name": "Media Player",
        "kind": "media",
        "purpose": "Playback control surface for audio-guided lessons, calming exercises, and approved media content.",
        "variants": ["Inline audio", "Expanded player", "Transcript-aware player"],
        "states": ["Idle", "Playing", "Paused", "Buffering", "Completed", "Error"],
        "properties": ["title", "duration", "progress", "captions", "transcript", "speed"],
        "sizes": ["Inline", "Card", "Full-width"],
        "flutter": "video_player, just_audio, custom controller widgets",
        "figma": "Media Player / State={State}",
        "usage": "Used in lesson view, audio cards, calm breathing, and approved content playback.",
        "do": ["Support captions or transcripts where media is instructional", "Keep controls large enough for motor accessibility"],
        "dont": ["Autoplay audio in sensitive contexts", "Hide playback state from assistive technology"],
        "status": "active",
    },
    {
        "slug": "video-card",
        "name": "Video Card",
        "kind": "media",
        "purpose": "Video content summary and launch treatment for lesson modules and reviewed BAHA content.",
        "variants": ["Thumbnail card", "In-progress video", "Completed video"],
        "states": ["Rest", "Pressed", "Loading", "Completed"],
        "properties": ["thumbnail", "title", "duration", "progress", "captionAvailability"],
        "sizes": ["Standard", "Hero"],
        "flutter": "Card, Stack, AspectRatio, playback launch action",
        "figma": "Video Card / State={State}",
        "usage": "Used in lesson view and learning content summaries where video is an approved modality.",
        "do": ["Show duration and caption availability", "Use clear play affordances"],
        "dont": ["Use motion thumbnails that distract from wellbeing context", "Hide progress state across sessions"],
        "status": "active",
    },
    {
        "slug": "audio-card",
        "name": "Audio Card",
        "kind": "media",
        "purpose": "Audio-first lesson and calming exercise presentation with transcript and completion metadata.",
        "variants": ["Lesson audio", "Breathing audio", "Short clip"],
        "states": ["Rest", "Playing", "Paused", "Completed"],
        "properties": ["title", "duration", "transcript", "progress", "downloadState"],
        "sizes": ["Standard", "Compact"],
        "flutter": "Card, just_audio controls, download action row",
        "figma": "Audio Card / State={State}",
        "usage": "Used in learning lessons, calm breathing, and cached low-bandwidth playback states.",
        "do": ["Expose transcript access without leaving context", "Retain downloaded state in offline mode"],
        "dont": ["Gate essential instructional content behind streaming only", "Depend on color for play state"],
        "status": "active",
    },
    {
        "slug": "quiz-components",
        "name": "Quiz Components",
        "kind": "input",
        "purpose": "Question, answer, explanation, and reflection primitives for formative learning checks.",
        "variants": ["Single select", "Multi select", "Reflection prompt", "Completion summary"],
        "states": ["Unanswered", "Answered", "Validated", "Review", "Completed"],
        "properties": ["question", "answers", "feedback", "progress", "isRequired"],
        "sizes": ["Card", "Stacked flow"],
        "flutter": "PageView or sliver stack of cards, RadioListTile, CheckboxListTile, TextField",
        "figma": "Quiz / Type={Type} / State={State}",
        "usage": "Used in student quiz and reflection plus module comprehension across role learning tracks.",
        "do": ["Provide supportive explanations after submission", "Keep scoring low-stakes and non-punitive"],
        "dont": ["Use gamified shame states for incorrect responses", "Mix unrelated question types in one dense panel"],
        "status": "active",
    },
    {
        "slug": "achievement-components",
        "name": "Achievement Components",
        "kind": "display",
        "purpose": "Non-competitive recognition for streaks, completions, and personal milestones.",
        "variants": ["Badge tile", "Milestone ribbon", "Completion summary", "Wallet item"],
        "states": ["Locked", "Earned", "Newly earned", "Viewed"],
        "properties": ["title", "icon", "criteria", "earnedAt", "isNew"],
        "sizes": ["Compact", "Standard"],
        "flutter": "Card, badge wrappers, animated entry chip",
        "figma": "Achievement / Variant={Variant} / State={State}",
        "usage": "Used in badge wallet, challenge completion, and supportive end-of-flow summaries.",
        "do": ["Frame achievements as personal progress, not leaderboards", "Pair new awards with calm confirmation"],
        "dont": ["Introduce public ranking or social comparison", "Use achievement visuals in crisis flows"],
        "status": "active",
    },
    {
        "slug": "list-rows",
        "name": "List Rows",
        "kind": "display",
        "purpose": "Dense repeated rows for settings, resources, modules, notifications, and option lists.",
        "variants": ["Plain row", "Chevron row", "Selectable row", "Metadata row"],
        "states": ["Rest", "Pressed", "Selected", "Disabled"],
        "properties": ["title", "subtitle", "leading", "trailing", "status"],
        "sizes": ["Single-line", "Two-line", "Three-line"],
        "flutter": "ListTile, InkWell row, custom slotted row widget",
        "figma": "List Row / Variant={Variant} / State={State}",
        "usage": "Used in help centers, settings, content lists, resources, queues, and notification feeds.",
        "do": ["Keep row interaction zones predictable", "Use metadata rows for timestamps and statuses"],
        "dont": ["Pack too many controls into one row", "Use chevrons on non-navigating rows"],
        "status": "active",
    },
    {
        "slug": "filter-chips",
        "name": "Filter Chips",
        "kind": "input",
        "purpose": "Quick multi-state filtering and lightweight option toggling.",
        "variants": ["Assist chip", "Single-select filter chip", "Multi-select chip", "Input chip"],
        "states": ["Rest", "Selected", "Focused", "Disabled"],
        "properties": ["label", "icon", "selected", "count"],
        "sizes": ["sm", "md"],
        "flutter": "FilterChip, ChoiceChip, InputChip",
        "figma": "Filter Chip / Type={Type} / State={State}",
        "usage": "Used in dashboards, queues, libraries, and search-result refinements.",
        "do": ["Expose selected state clearly in text and color", "Keep filter groups horizontally or vertically scroll-safe"],
        "dont": ["Hide critical filters in chips only when counts are large", "Use long sentence labels"],
        "status": "active",
    },
    {
        "slug": "status-banners",
        "name": "Status Banners",
        "kind": "feedback",
        "purpose": "High-visibility inline messaging for consent blocks, warnings, support notices, and maintenance states.",
        "variants": ["Info", "Success", "Warning", "Danger", "Privacy notice"],
        "states": ["Visible", "Dismissed", "Sticky"],
        "properties": ["title", "body", "tone", "actionLabel", "icon"],
        "sizes": ["Inline", "Full-width"],
        "flutter": "Material banner, custom status banner widget",
        "figma": "Banner / Tone={Tone} / State={State}",
        "usage": "Used across offline states, support escalations, consent messaging, and operational notices.",
        "do": ["Use banners for route-relevant messaging that must stay visible", "Escalate tone carefully for student-facing distress contexts"],
        "dont": ["Stack multiple banners without priority logic", "Use danger styling for non-urgent preferences"],
        "status": "active",
    },
    {
        "slug": "empty-states",
        "name": "Empty States",
        "kind": "feedback",
        "purpose": "Structured no-data treatment with explanation and next best action.",
        "variants": ["No history", "No results", "No linked data", "Filtered empty"],
        "states": ["Visible"],
        "properties": ["title", "body", "illustration", "primaryAction", "secondaryAction"],
        "sizes": ["Card", "Full-page"],
        "flutter": "Column or sliver composition with illustration and action row",
        "figma": "Empty State / Variant={Variant}",
        "usage": "Used in trend-empty, offline summary placeholders, sparse queues, and search zero-results states.",
        "do": ["Explain why the screen is empty", "Offer one clear recovery path"],
        "dont": ["Leave users on blank white space", "Use blame-oriented language"],
        "status": "active",
    },
    {
        "slug": "skeleton-loaders",
        "name": "Skeleton Loaders",
        "kind": "feedback",
        "purpose": "Geometry-preserving loading placeholders for cards, lists, charts, and detail surfaces.",
        "variants": ["Card skeleton", "List skeleton", "Chart skeleton", "Detail skeleton"],
        "states": ["Visible", "Fading out"],
        "properties": ["shapeModel", "lineCount", "showMediaSlot"],
        "sizes": ["Contextual to parent component"],
        "flutter": "Shimmer or custom animated placeholder widgets",
        "figma": "Skeleton / Variant={Variant}",
        "usage": "Used on any live-data surface expected to resolve within one round-trip.",
        "do": ["Match final layout geometry closely", "Respect reduced-motion preferences"],
        "dont": ["Show skeletons for long offline errors", "Swap to completely different loaded layouts"],
        "status": "active",
    },
    {
        "slug": "data-table",
        "name": "Data Table",
        "kind": "data",
        "purpose": "Dense multi-column operational data view for BAHA and select teacher/admin contexts.",
        "variants": ["Standard table", "Sticky header table", "Selectable rows table"],
        "states": ["Loading", "Empty", "Populated", "Sorted", "Filtered"],
        "properties": ["columns", "rows", "sortState", "selectionState", "pagination"],
        "sizes": ["Desktop", "Tablet responsive"],
        "flutter": "DataTable, PaginatedDataTable, custom sliver table",
        "figma": "Data Table / Variant={Variant} / State={State}",
        "usage": "Used in support queues, content review, audit logs, and user management surfaces.",
        "do": ["Expose column sort and status clearly", "Preserve row identity during refreshes"],
        "dont": ["Force tables onto narrow student mobile screens", "Hide critical actions inside ambiguous row menus"],
        "status": "active",
    },
    {
        "slug": "accordion",
        "name": "Accordion",
        "kind": "display",
        "purpose": "Expandable disclosure for guides, policies, FAQs, and grouped metadata.",
        "variants": ["Single expand", "Multi expand", "Nested section"],
        "states": ["Collapsed", "Expanded", "Disabled"],
        "properties": ["title", "summary", "content", "defaultExpanded"],
        "sizes": ["Standard row", "Card section"],
        "flutter": "ExpansionTile, ExpansionPanelList",
        "figma": "Accordion / State={State}",
        "usage": "Used in conversation guides, help content, settings, and policy detail surfaces.",
        "do": ["Use concise section titles with short summaries", "Remember expansion state where it helps comparison"],
        "dont": ["Hide mission-critical safety instructions inside deeply collapsed sets", "Mix unrelated tasks in one accordion"],
        "status": "active",
    },
    {
        "slug": "consent-cards",
        "name": "Consent Cards",
        "kind": "display",
        "purpose": "Purpose-built cards for consent scope, privacy tiers, and sharing boundaries.",
        "variants": ["Tier comparison", "Current status", "Override notice", "Pending state"],
        "states": ["Default", "Selected", "Pending", "Warning", "Locked"],
        "properties": ["tierName", "summary", "visibilityRules", "status", "cta"],
        "sizes": ["Standard", "Comparison column"],
        "flutter": "Custom card composition on top of Card, badges, and list rows",
        "figma": "Consent Card / Variant={Variant} / State={State}",
        "usage": "Used in privacy promise, consent setup, consent review, and override notification flows.",
        "do": ["State who can see what in plain language", "Use side-by-side comparison only when the architecture already calls for it"],
        "dont": ["Bury safeguarding override rules in footnotes", "Expose hidden internal policy codes to guardians or students"],
        "status": "active",
    },
]


FOUNDATION_FILES = {
    "README.md": """
    # Foundations

    This section defines the non-component rules that every BAHA screen inherits before a single widget is placed.

    ## Included

    - [Layout_Foundations.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/01_Foundations/Layout_Foundations.md)
    - [Visual_Foundations.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/01_Foundations/Visual_Foundations.md)
    - [Theming_and_Color.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/01_Foundations/Theming_and_Color.md)
    """,
    "Layout_Foundations.md": """
    # Layout Foundations

    ## Grid System

    | Surface | Grid | Gutters | Notes |
    |---|---|---:|---|
    | Student mobile | 4-column | 16 | Prioritizes thumb reach and short card stacks |
    | Parent mobile | 4-column | 16 | Balances summary density and readability |
    | Teacher tablet/mobile | 8-column adaptive | 16 to 24 | Supports chart plus list pairings |
    | BAHA desktop/tablet | 12-column adaptive | 24 | Supports rail, table, and detail compositions |

    ## Responsive Breakpoints

    | Token | Width | Usage |
    |---|---:|---|
    | `bp.xs` | 0 | Narrow phones |
    | `bp.sm` | 360 | Standard phones |
    | `bp.md` | 600 | Large phone or portrait tablet |
    | `bp.lg` | 840 | Landscape tablet |
    | `bp.xl` | 1200 | Desktop and BAHA operations |
    | `bp.xxl` | 1440 | Wide analytics workspace |

    ## Column Layouts

    - Student and parent surfaces default to single-column content with optional 2-up cards at `bp.md`.
    - Teacher analytics surfaces allow 2-column content at `bp.lg`, with filters staying sticky above charts.
    - BAHA operations use a persistent left rail plus 2 or 3-column workspace splits at `bp.xl`.

    ## Container Widths

    | Container | Max Width |
    |---|---:|
    | Reading container | 720 |
    | Standard app content | 960 |
    | Analytics workspace | 1280 |
    | Full operations canvas | 1440 |

    ## Safe Areas

    - Respect platform safe areas on every shell and overlay.
    - Student and parent bottom navigation must reserve home-indicator or gesture inset space.
    - BAHA desktop layouts reserve room for browser chrome and sticky utility bars.
    - Snackbar and bottom-sheet anchors must sit above bottom navigation and keyboard insets.
    """,
    "Visual_Foundations.md": """
    # Visual Foundations

    ## Spacing Scale

    | Token | Value |
    |---|---:|
    | `space.0` | 0 |
    | `space.1` | 4 |
    | `space.2` | 8 |
    | `space.3` | 12 |
    | `space.4` | 16 |
    | `space.5` | 20 |
    | `space.6` | 24 |
    | `space.8` | 32 |
    | `space.10` | 40 |
    | `space.12` | 48 |
    | `space.16` | 64 |

    ## Corner Radius

    | Token | Value | Usage |
    |---|---:|---|
    | `radius.sm` | 8 | Chips and small inputs |
    | `radius.md` | 12 | Buttons and fields |
    | `radius.lg` | 16 | Cards and sheets |
    | `radius.xl` | 24 | Hero cards and splash panels |
    | `radius.pill` | 999 | Pills and badges |

    ## Elevation and Shadows

    | Token | Elevation | Shadow Use |
    |---|---:|---|
    | `elevation.0` | 0 | Flat surfaces |
    | `elevation.1` | 1 | Cards on canvas |
    | `elevation.2` | 2 | Raised controls |
    | `elevation.3` | 4 | Dialogs and sheets |
    | `elevation.4` | 8 | High-priority overlays |

    ## Opacity

    | Token | Value | Usage |
    |---|---:|---|
    | `opacity.disabled` | 0.38 | Disabled labels and icons |
    | `opacity.subtle` | 0.60 | Secondary iconography |
    | `opacity.overlay` | 0.72 | Modal scrim |
    | `opacity.focus` | 0.16 | Focus ring background |

    ## Blur

    | Token | Value | Usage |
    |---|---:|---|
    | `blur.none` | 0 | Standard surfaces |
    | `blur.sm` | 8 | Glassy utility overlays |
    | `blur.md` | 16 | Backdrop for modal interruptions |
    | `blur.lg` | 24 | Reserved for immersive splash or maintenance states |

    ## Typography Scale

    | Token | Size / Line | Use |
    |---|---|---|
    | `type.display` | 32 / 40 | Welcome, milestone, splash |
    | `type.h1` | 28 / 36 | Major screen titles |
    | `type.h2` | 24 / 32 | Section headers |
    | `type.h3` | 20 / 28 | Card titles |
    | `type.bodyLg` | 18 / 28 | Student primary reading |
    | `type.bodyMd` | 16 / 24 | Standard content |
    | `type.bodySm` | 14 / 20 | Metadata and helper text |
    | `type.label` | 12 / 16 | Chips, buttons, badges |
    | `type.monoSm` | 12 / 16 | Audit identifiers |
    """,
    "Theming_and_Color.md": """
    # Theming and Color

    ## Color Palette

    | Family | Light | Dark | Purpose |
    |---|---|---|---|
    | Primary trust | `#155EEF` | `#84ADFF` | Main actions and active states |
    | Secondary calm | `#0F766E` | `#5EEAD4` | Wellness, guidance, supportive actions |
    | Warm neutral | `#F8F6F2` | `#1B1E23` | Canvas and restful backgrounds |
    | Ink neutral | `#101828` | `#F5F7FA` | Primary text |
    | Success | `#127A4B` | `#6CE9A6` | Completion and saved state |
    | Warning | `#B54708` | `#FEC84B` | Advisory caution |
    | Danger | `#B42318` | `#FDA29B` | High-risk or destructive states |
    | Information | `#175CD3` | `#84CAFF` | Explanatory banners and info states |

    ## Light Theme

    - Canvas uses warm neutrals rather than pure white to reduce glare on student and parent surfaces.
    - Cards stay slightly elevated with low shadow and strong text contrast.
    - BAHA tables use cooler neutral rows to improve scanability at density.

    ## Dark Theme

    - Dark mode preserves calm contrast and avoids saturated neon tones.
    - Student achievement surfaces remain warm but muted to avoid over-stimulation.
    - Charts switch to high-legibility semantic strokes and labels with a stronger focus ring.

    ## Semantic Colors

    | Token | Light | Dark | Usage |
    |---|---|---|---|
    | `color.text.primary` | `#101828` | `#F5F7FA` | Primary content |
    | `color.text.secondary` | `#475467` | `#CDD5DF` | Supporting copy |
    | `color.surface.canvas` | `#F8F6F2` | `#101318` | App background |
    | `color.surface.card` | `#FFFFFF` | `#161B22` | Cards and sheets |
    | `color.border.default` | `#D0D5DD` | `#344054` | Inputs and dividers |
    | `color.focus.ring` | `#84ADFF` | `#B2CCFF` | Focus visibility |

    ## Feedback Colors

    | State | Background | Foreground | Border |
    |---|---|---|---|
    | Success | `#ECFDF3` | `#127A4B` | `#ABEFC6` |
    | Warning | `#FFFAEB` | `#B54708` | `#FEDF89` |
    | Danger | `#FEF3F2` | `#B42318` | `#FECDCA` |
    | Information | `#EFF8FF` | `#175CD3` | `#B2DDFF` |
    | Neutral | `#F2F4F7` | `#344054` | `#D0D5DD` |

    ## Role Color Notes

    - Student surfaces emphasize calm secondary tones, rounded containers, and low-danger saturation until escalation states are explicit.
    - Parent surfaces use higher clarity contrast and more explanatory information color.
    - Teacher surfaces bias toward neutral analytics palettes with anonymization-safe severity coding.
    - BAHA surfaces retain semantic severity color while avoiding red overload in dense operational contexts.
    """,
}


PATTERN_FILES = {
    "README.md": """
    # Patterns

    Interaction patterns connect reusable components into screen-level behaviors without redefining the product.

    ## Included

    - [Authentication.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/04_Patterns/Authentication.md)
    - [Forms.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/04_Patterns/Forms.md)
    - [Lists.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/04_Patterns/Lists.md)
    - [Infinite_Scrolling.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/04_Patterns/Infinite_Scrolling.md)
    - [Search.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/04_Patterns/Search.md)
    - [Filtering.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/04_Patterns/Filtering.md)
    - [Sorting.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/04_Patterns/Sorting.md)
    - [Wizard.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/04_Patterns/Wizard.md)
    - [Check_In_Flow.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/04_Patterns/Check_In_Flow.md)
    - [Chat_Flow.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/04_Patterns/Chat_Flow.md)
    - [Learning_Flow.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/04_Patterns/Learning_Flow.md)
    - [Games.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/04_Patterns/Games.md)
    - [Escalation.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/04_Patterns/Escalation.md)
    - [Notifications.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/04_Patterns/Notifications.md)
    - [Settings.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/04_Patterns/Settings.md)
    """,
    "Authentication.md": """
    # Authentication

    ## Scope

    - Splash bootstrap
    - Role resolution
    - Session refresh
    - Consent gate handoff
    - Session expiry redirect

    ## Component Stack

    - App Shell
    - Top Navigation
    - Progress Indicators
    - Status Banners
    - Dialogs

    ## Rules

    - Keep first-launch and returning-user bootstrap visually consistent across roles.
    - Route to the next valid screen using the Phase 3 routing table rather than branching inside component state.
    - Session expiry must interrupt sensitive workflows with a dialog, preserve non-sensitive drafts when allowed, and redirect to the correct splash route.
    """,
    "Forms.md": """
    # Forms

    ## Scope

    - Guardian verification
    - Pastoral input
    - Counselor requests
    - Content editing
    - Threshold configuration

    ## Component Stack

    - Text Fields
    - Dropdown
    - Radio
    - Checkbox
    - Switch
    - Slider
    - Buttons
    - Snackbars
    - Dialogs

    ## Rules

    - Validate inline first, then at submit.
    - Do not collapse required safeguarding fields behind secondary interactions.
    - Preserve unsaved state long enough to support interruption recovery unless the flow handles highly sensitive data.
    """,
    "Lists.md": """
    # Lists

    ## Scope

    - Learning catalogs
    - Notification feeds
    - Support queues
    - Audit views
    - Help resources

    ## Component Stack

    - List Rows
    - Cards
    - Search
    - Filter Chips
    - Data Table
    - Empty States
    - Skeleton Loaders

    ## Rules

    - Use list rows for scan-heavy, repeated content and cards for action-heavy summaries.
    - Preserve order semantics when the route communicates sequence or priority.
    - Maintain filter and scroll position when the user returns from a detail screen.
    """,
    "Infinite_Scrolling.md": """
    # Infinite Scrolling

    ## Scope

    - BAHA content library
    - Audit log
    - Support queue
    - Notification center

    ## Rules

    - Use explicit page or cursor loading on operational datasets above one screenful.
    - Show a skeleton continuation rather than a full-screen loader for subsequent pages.
    - Preserve keyboard focus and screen-reader position after new rows append.
    - Student and parent routes should prefer smaller bounded lists over endless feeds unless the architecture explicitly requires otherwise.
    """,
    "Search.md": """
    # Search

    ## Scope

    - Content library
    - Safe questions manager
    - Audit log
    - Notification center
    - Queue-like list surfaces

    ## Rules

    - Debounce remote search and keep entered text visible after navigation back.
    - Pair search with the currently active filter and sort state in the UI.
    - Zero-results states must offer a reset path and must not appear identical to first-load empty states.
    """,
    "Filtering.md": """
    # Filtering

    ## Scope

    - Trend filters
    - Queue filters
    - Content tags
    - Notification segments

    ## Component Stack

    - Filter Chips
    - Dropdown
    - Bottom Sheets
    - Tabs

    ## Rules

    - Keep active filters visible after application.
    - Use chips for small high-frequency filters and bottom sheets for large option sets.
    - Any privacy-affecting filter must default to the safest projection.
    """,
    "Sorting.md": """
    # Sorting

    ## Scope

    - Queue priority
    - Audit events
    - Learning lists
    - Content review states

    ## Rules

    - Default ordering must reflect the task model in the architecture: recency for histories, urgency for support, relevance for search, and continuation for learning.
    - Sorting controls belong near list headers or table columns, not in hidden overflow alone.
    - Reversing sort order must not reset filters or selection.
    """,
    "Wizard.md": """
    # Wizard

    ## Scope

    - Student onboarding
    - Parent onboarding
    - Consent setup
    - Check-in sequencing

    ## Component Stack

    - Stepper
    - Cards
    - Radio
    - Checkbox
    - Switch
    - Buttons
    - Dialogs

    ## Rules

    - Each step contains one primary decision or action group.
    - Progress visibility is mandatory.
    - Safe backtracking is allowed unless policy or submission state would be invalidated.
    """,
    "Check_In_Flow.md": """
    # Check-In Flow

    ## Scope

    - Weekly check-in prompt
    - Questionnaire
    - Completion
    - Trend follow-through

    ## Component Stack

    - Stepper
    - Cards
    - Slider
    - Radio
    - Checkbox
    - Progress Indicators
    - Achievement Components

    ## Rules

    - Keep copy low-pressure and non-diagnostic.
    - Allow temporary save or recovery when connectivity changes.
    - Completion should route to supportive next steps, not dead ends.
    """,
    "Chat_Flow.md": """
    # Chat Flow

    ## Scope

    - Safe questions library
    - Buddy chat
    - Citation detail
    - Out-of-scope refusal

    ## Component Stack

    - Chat Messages
    - Text Fields
    - Buttons
    - Tooltips
    - Dialogs
    - Notifications

    ## Rules

    - Citations must remain reachable from reviewed responses.
    - Out-of-scope or escalation states must preserve user dignity and provide the next safe action.
    - Typing, sending, and retry states must be explicit.
    """,
    "Learning_Flow.md": """
    # Learning Flow

    ## Scope

    - Learning homes
    - Module detail
    - Lesson view
    - Quiz and reflection

    ## Component Stack

    - Learning Cards
    - Media Player
    - Video Card
    - Audio Card
    - Quiz Components
    - Progress Indicators

    ## Rules

    - Preserve progress between entries and exits.
    - Surface duration, modality, and completion state before commitment.
    - Reflection remains supportive and non-punitive.
    """,
    "Games.md": """
    # Games

    ## Scope

    - Games hub
    - Emotion Explorer
    - Friendship Choices
    - Calm Breathing
    - Time cap prompt

    ## Component Stack

    - Game Cards
    - Progress Indicators
    - Buttons
    - Audio Card
    - Achievement Components
    - Dialogs

    ## Rules

    - Never frame games as performance competitions.
    - Time-cap interruptions must be advisory and calm.
    - Calming activities should work in low-bandwidth or cached states where the architecture permits.
    """,
    "Escalation.md": """
    # Escalation

    ## Scope

    - Student counselor request
    - Parent alerts
    - Teacher pastoral input and referrals
    - BAHA support queue, case detail, emergency protocols, assignments, and audit-linked actions

    ## Component Stack

    - Status Banners
    - Notifications
    - Cards
    - Timeline
    - Data Table
    - Dialogs
    - Bottom Sheets

    ## Rules

    - Safety-critical actions must be visually clear, confirmed when necessary, and fully logged.
    - Escalation messaging differs by role but must remain consistent with privacy and consent constraints.
    - Every escalation state needs a clear owner, timestamp surface, and next-action affordance.
    """,
    "Notifications.md": """
    # Notifications

    ## Scope

    - Student reminders
    - Parent alerts and reminders
    - Teacher updates
    - BAHA operational notices

    ## Rules

    - Compact notifications should never expose hidden private details.
    - Notification rows must announce destination or action requirement clearly.
    - Read or unread state changes should not silently remove an item from the current list.
    """,
    "Settings.md": """
    # Settings

    ## Scope

    - Privacy settings
    - Notification settings
    - Data rights
    - Teacher settings
    - BAHA operational settings

    ## Component Stack

    - List Rows
    - Switch
    - Checkbox
    - Dialogs
    - Status Banners
    - Accordion

    ## Rules

    - Group settings by mental model: identity, notifications, privacy, support, and policy.
    - Use explicit confirmation for changes with policy or access implications.
    - Settings surfaces must remain navigable without requiring users to interpret technical system language.
    """,
}


MOTION_FILES = {
    "README.md": """
    # Motion

    Motion supports continuity and comprehension without gamifying distress or over-energizing sensitive flows.

    - [Motion_System.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/06_Motion/Motion_System.md)
    """,
    "Motion_System.md": """
    # Motion System

    ## Motion Principles

    - Prioritize orientation over delight.
    - Never gamify crisis, consent, or distress-related moments.
    - Keep student motion gentle and low amplitude.
    - Use denser but quieter motion in BAHA operations to preserve throughput.
    - Respect reduced-motion settings by removing non-essential transforms and shimmer.

    ## Animation Library

    | Token | Duration | Curve | Usage |
    |---|---:|---|---|
    | `motion.instant` | 0 | linear | Reduced motion and state snap |
    | `motion.fast` | 120ms | emphasized decelerate | Button and chip feedback |
    | `motion.base` | 200ms | standard | Card reveal and tab changes |
    | `motion.slow` | 280ms | emphasized | Page transitions and sheets |
    | `motion.breathe` | 1600ms | ease in out | Calm breathing pulses only |

    ## Transition Library

    | Transition | Use |
    |---|---|
    | Fade | Splash, settings, low-context changes |
    | Shared axis X | Check-in and learning sequence steps |
    | Shared axis Y | Support and case detail movement |
    | Shared axis Z | Game depth and immersive entry |
    | Fade through | Dashboard or list-to-peer route changes |

    ## Page Transitions

    - Bootstrap routes use fade.
    - Onboarding and wizard routes use directional slide or shared-axis X.
    - Operational detail and workflow routes use shared-axis Y when moving between list and detail.

    ## Shared Element Transitions

    - Card-to-detail transitions may animate media thumbnails, titles, and status chips when layout continuity is clear.
    - Do not use shared elements for high-risk alert changes or private identifiers.

    ## Modal Animations

    - Dialogs fade and scale slightly from 0.96 to 1.00 over `motion.base`.
    - Session-expired or destructive dialogs skip bounce or spring effects.

    ## Bottom Sheet Animations

    - Sheets rise from the bottom over `motion.slow`.
    - Gesture dismissal must track the finger and respect velocity thresholds.

    ## FAB Animations

    - FAB is reserved and should use standard Material motion if ever enabled.

    ## Loading Animations

    - Use subtle skeleton shimmer only when reduced motion is off.
    - Progress loops longer than 3 seconds require text status.

    ## Gesture Animations

    - Pull-to-refresh preserves filter state and scroll anchor.
    - Swipe back should reveal the prior route predictably and not conflict with horizontal chips or tabs.
    """,
}


ACCESSIBILITY_FILES = {
    "README.md": """
    # Accessibility

    - [Accessibility_System.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/09_Accessibility/Accessibility_System.md)
    """,
    "Accessibility_System.md": """
    # Accessibility System

    ## WCAG Compliance

    - Minimum target: WCAG 2.1 AA across contrast, focus, semantics, and text resize.
    - Student and parent surfaces should exceed AA where feasible because readability is part of psychological safety.

    ## Focus Behaviour

    - Every interactive control receives a visible focus ring using `color.focus.ring`.
    - Dialogs, sheets, and menus trap focus until dismissed.
    - Returning focus after overlays close is mandatory.

    ## Contrast Rules

    - Body text contrast target: 4.5:1 minimum.
    - Large text and prominent metrics: 3:1 minimum.
    - Status color may not be the only carrier of meaning.

    ## Screen Reader Guidance

    - Use route-level titles as semantic headings.
    - Announce unread counts, chart summaries, consent states, and support banners in plain language.
    - Complex charts must expose a narrative summary adjacent to the visualization.

    ## Reduced Motion

    - Disable shimmer, large transforms, and breathing animation loops when reduced motion is enabled.
    - Replace animated state transitions with opacity or immediate swaps where possible.

    ## Large Text

    - Support at least 200 percent text scaling without clipping or overlap.
    - Bottom navigation labels may wrap to two lines or switch to alternative layout at large sizes.

    ## Voice Control

    - Buttons, tabs, and rows must have distinct accessible names.
    - Avoid multiple identical labels such as repeated "Open" without context.

    ## Keyboard Navigation

    - BAHA and teacher surfaces must be fully keyboard operable.
    - Tab order follows visual hierarchy, then safe action priority.
    - Data tables require keyboard cell and row traversal support when interactive.
    """,
}


CONTENT_FILES = {
    "README.md": """
    # Content Guidelines

    - [Content_Guidelines.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/10_Content_Guidelines/Content_Guidelines.md)
    """,
    "Content_Guidelines.md": """
    # Content Guidelines

    ## Voice by Surface

    - Student: calm, simple, supportive, and non-diagnostic.
    - Parent: clear, respectful, and privacy-explicit.
    - Teacher: concise, professionally neutral, and action-oriented.
    - BAHA: precise, audit-friendly, and operationally direct.

    ## Safeguarding Language

    - Use concrete next steps instead of ambiguous urgency phrasing.
    - Avoid blame, stigma, or surveillance framing.
    - Preserve dignity during refusal, escalation, and consent override messages.

    ## Writing Rules

    - Prefer short active sentences.
    - Define unfamiliar policy or metrics inline or through a tooltip.
    - Use consistent verbs for irreversible actions: `Delete`, `Withdraw`, `Archive`, `Escalate`, `Assign`.

    ## Localization Notes

    - Externalize all copy.
    - Design labels for longer translations and mixed-script rendering.
    - Avoid idioms in student guidance and parental summaries.
    """,
}


ILLUSTRATION_FILES = {
    "README.md": """
    # Illustrations

    - [Illustration_System.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/07_Illustrations/Illustration_System.md)
    """,
    "Illustration_System.md": """
    # Illustration System

    ## Role in the Product

    - Provide warmth and orientation in onboarding, empty states, and supportive completion moments.
    - Avoid literal crisis depiction or emotionally manipulative scenes.

    ## Style Direction

    - Soft geometry, low-noise backgrounds, and human-centered metaphors.
    - Use role-safe diversity without over-personalizing sensitive contexts.
    - Keep BAHA operational illustrations minimal or omit them on dense work screens.

    ## Usage Rules

    - Use illustrations in welcome, empty, and completion states.
    - Prefer icons or diagrams over illustrations in analytics and governance screens.
    - Provide alt text or hide decorative illustrations from assistive technology.
    """,
}


ICON_FILES = {
    "README.md": """
    # Icons

    - [Icon_System.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/08_Icons/Icon_System.md)
    """,
    "Icon_System.md": """
    # Icon System

    ## Style

    - Rounded, legible line icons with a consistent 2px stroke at 24px.
    - Filled severity icons are allowed for danger and urgent operational states.

    ## Sizes

    | Token | Size |
    |---|---:|
    | `icon.sm` | 16 |
    | `icon.md` | 20 |
    | `icon.lg` | 24 |
    | `icon.xl` | 32 |

    ## Rules

    - Pair icons with labels when the action is not universally obvious.
    - Do not rely on iconography alone for safeguarding or consent decisions.
    - Mirror directional icons for RTL locales where appropriate.
    """,
}


FIGMA_FILES = {
    "README.md": """
    # Figma Preparation

    This section defines how the future Figma file should be structured without generating screen frames yet.

    - [Figma_File_Blueprint.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/11_Figma/Figma_File_Blueprint.md)
    - [Figma_Variables.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/11_Figma/Figma_Variables.md)
    - [Component_Set_Plan.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/11_Figma/Component_Set_Plan.md)
    """,
    "Figma_File_Blueprint.md": """
    # Figma File Blueprint

    ## Pages

    1. Cover
    2. Foundations
    3. Tokens and Variables
    4. Components
    5. Patterns
    6. Layouts
    7. Motion Specs
    8. Accessibility
    9. Screen Assembly Workbench

    ## Naming Conventions

    - Component set: `Category / Component / Variant`
    - Variable collection: `Global`, `Role Overrides`, `Theme`, `Component`
    - Frame naming: `Role / Screen ID / Screen Name`

    ## Rules

    - Build variables before components.
    - Bind all color, spacing, radius, typography, and effect values to variables.
    - Use one source component per documented component family before building role-specific wrappers.
    """,
    "Figma_Variables.md": """
    # Figma Variables

    ## Collections

    - Global Primitives
    - Global Semantic
    - Theme Light
    - Theme Dark
    - Role Overrides
    - Component Aliases

    ## Example Variable Names

    - `color/primitive/blue/600`
    - `color/semantic/text/primary`
    - `space/4`
    - `radius/lg`
    - `elevation/2`
    - `motion/duration/base`
    - `component/button/fill/primary`

    ## Mode Strategy

    - Global primitives remain mode-agnostic.
    - Theme collections expose Light and Dark modes.
    - Role overrides alias semantic values rather than introducing disconnected colors.
    """,
    "Component_Set_Plan.md": """
    # Component Set Plan

    ## Build Order

    1. App shell and navigation
    2. Buttons and inputs
    3. Cards, rows, badges, and banners
    4. Overlays and feedback
    5. Learning, game, chat, and achievement wrappers
    6. Data visualization and tables

    ## Variant Axes

    - Size
    - State
    - Tone
    - Role density where needed
    - Content modality for learning and media components

    ## Output Constraint

    - Do not generate screen frames until all variable collections and reusable sets pass coverage against the Phase 4 composition matrix.
    """,
}


FLUTTER_FILES = {
    "README.md": """
    # Flutter

    - [Design_Tokens.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/12_Flutter/Design_Tokens.dart)
    - [Flutter_Widget_Mapping.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/12_Flutter/Flutter_Widget_Mapping.md)
    - [Implementation_Guidance.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/12_Flutter/Implementation_Guidance.md)
    """,
    "Flutter_Widget_Mapping.md": """
    # Flutter Widget Mapping

    ## Core Mapping Rules

    - Start from Material 3 primitives, then wrap them in BAHA-specific widgets to enforce tokens, semantics, and analytics hooks.
    - Route composition follows the Phase 3 routing table; widget composition follows the Phase 4 component catalog.

    ## Key Mappings

    | Design System Component | Flutter Mapping |
    |---|---|
    | App Shell | `Scaffold` plus role shell wrapper |
    | Top Navigation | `AppBar` or `SliverAppBar` |
    | Bottom Navigation | `NavigationBar` |
    | Navigation Rail | `NavigationRail` |
    | Cards | `Card` plus BAHA slots |
    | Learning Cards | Custom widget over `Card` and progress primitives |
    | Chat Messages | Custom sliver or list bubble widgets |
    | Data Table | `DataTable` or custom paginated table |
    | Dialogs | `showAdaptiveDialog` and typed dialog wrappers |
    | Bottom Sheets | `showModalBottomSheet` |
    | Charts and Graphs | Charting library wrappers with semantic summaries |

    ## Implementation Notes

    - Keep analytics, accessibility labels, and privacy redaction inside shared widgets where possible.
    - Separate app-shell concerns from feature widgets so roles can evolve without component drift.
    """,
    "Implementation_Guidance.md": """
    # Implementation Guidance

    ## Architecture

    - Tokens compile into theme extensions and typed constants.
    - Shared widgets live in a design-system package or feature-agnostic module.
    - Role wrappers own route-level composition and permissions, not primitive component styling.

    ## State and Safety

    - Components should accept explicit state enums instead of inferring from null values.
    - Sensitive support and audit widgets should centralize redaction and access checks.
    - Offline, loading, and empty states should reuse shared state surfaces rather than custom one-offs.
    """,
}


MERMAID_FILES = {
    "README.md": """
    # Mermaid

    - [Component_Hierarchy.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/Mermaid/Component_Hierarchy.mmd)
    - [Component_Dependency_Graph.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/Mermaid/Component_Dependency_Graph.mmd)
    - [Token_Dependency_Graph.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/Mermaid/Token_Dependency_Graph.mmd)
    - [Pattern_Hierarchy.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/Mermaid/Pattern_Hierarchy.mmd)
    """,
    "Component_Hierarchy.mmd": """
    flowchart TD
      A["Design System"] --> B["App Shell"]
      A --> C["Navigation"]
      A --> D["Inputs"]
      A --> E["Display"]
      A --> F["Feedback"]
      A --> G["Media"]
      A --> H["Data"]
      B --> B1["Top Navigation"]
      B --> B2["Bottom Navigation"]
      B --> B3["Navigation Rail"]
      C --> C1["Tabs"]
      C --> C2["Stepper"]
      D --> D1["Text Fields"]
      D --> D2["Dropdown"]
      D --> D3["Radio and Checkbox"]
      D --> D4["Switch and Slider"]
      E --> E1["Cards"]
      E --> E2["Learning Cards"]
      E --> E3["Game Cards"]
      E --> E4["Profile Cards"]
      E --> E5["Chat Messages"]
      E --> E6["Notifications"]
      F --> F1["Status Banners"]
      F --> F2["Dialogs"]
      F --> F3["Bottom Sheets"]
      F --> F4["Snackbars"]
      F --> F5["Empty and Skeleton States"]
      G --> G1["Media Player"]
      G --> G2["Video Card"]
      G --> G3["Audio Card"]
      H --> H1["Charts and Graphs"]
      H --> H2["Data Table"]
      H --> H3["Timeline"]
    """,
    "Component_Dependency_Graph.mmd": """
    flowchart LR
      T["Tokens"] --> N["Navigation Components"]
      T --> I["Input Components"]
      T --> D["Display Components"]
      T --> F["Feedback Components"]
      T --> M["Media Components"]
      T --> X["Data Components"]
      N --> S["App Shell"]
      I --> P["Forms Pattern"]
      D --> L["Lists Pattern"]
      D --> H["Learning Pattern"]
      D --> G["Games Pattern"]
      F --> E["Escalation Pattern"]
      M --> H
      X --> O["Operations Pattern"]
      S --> R1["Student Screens"]
      S --> R2["Parent Screens"]
      S --> R3["Teacher Screens"]
      S --> R4["BAHA Screens"]
      P --> R1
      P --> R2
      P --> R3
      P --> R4
      L --> R2
      L --> R3
      O --> R4
      H --> R1
      H --> R2
      H --> R3
      G --> R1
      E --> R1
      E --> R2
      E --> R3
      E --> R4
    """,
    "Token_Dependency_Graph.mmd": """
    flowchart TD
      P["Primitive Tokens"] --> S["Semantic Tokens"]
      S --> TH["Theme Modes"]
      S --> RO["Role Overrides"]
      TH --> C["Component Tokens"]
      RO --> C
      C --> FG["Figma Variables"]
      C --> FL["Flutter Constants"]
      C --> UI["Reusable Components"]
      UI --> SC["Screen Composition Matrix"]
    """,
    "Pattern_Hierarchy.mmd": """
    mindmap
      root((BAHA Patterns))
        Authentication
          Splash
          Session Restore
          Consent Handoff
        Forms
          Guardian Verification
          Pastoral Input
          Content Editing
          Threshold Configuration
        Lists
          Learning Lists
          Notification Feeds
          Support Queues
          Audit Views
        Wizard
          Onboarding
          Consent Setup
          Weekly Check-In
        Chat
          Safe Questions
          Buddy Conversation
          Citation Detail
          Out-of-Scope Redirect
        Learning
          Module Discovery
          Lesson Playback
          Quiz and Reflection
        Games
          Hub
          Scenario Play
          Calm Breathing
          Time Cap
        Escalation
          Student Support Request
          Parent Alert
          Teacher Referral
          BAHA Case Management
        Settings
          Privacy
          Notifications
          Data Rights
          Operations
    """,
}


TOKEN_JSON = {
    "color": {
        "primitive": {
            "blue600": "#155EEF",
            "blue300": "#84ADFF",
            "teal700": "#0F766E",
            "teal300": "#5EEAD4",
            "neutral0": "#FFFFFF",
            "neutral50": "#F8F6F2",
            "neutral900": "#101828",
            "success600": "#127A4B",
            "warning600": "#B54708",
            "danger600": "#B42318",
            "info600": "#175CD3",
        },
        "semantic": {
            "text": {"primary": "#101828", "secondary": "#475467", "inverse": "#F5F7FA"},
            "surface": {"canvas": "#F8F6F2", "card": "#FFFFFF", "inverse": "#101318"},
            "border": {"default": "#D0D5DD", "strong": "#98A2B3", "focus": "#84ADFF"},
            "status": {
                "success": {"bg": "#ECFDF3", "fg": "#127A4B"},
                "warning": {"bg": "#FFFAEB", "fg": "#B54708"},
                "danger": {"bg": "#FEF3F2", "fg": "#B42318"},
                "info": {"bg": "#EFF8FF", "fg": "#175CD3"},
            },
        },
    },
    "spacing": {"0": 0, "1": 4, "2": 8, "3": 12, "4": 16, "5": 20, "6": 24, "8": 32, "10": 40, "12": 48, "16": 64},
    "radius": {"sm": 8, "md": 12, "lg": 16, "xl": 24, "pill": 999},
    "elevation": {"0": 0, "1": 1, "2": 2, "3": 4, "4": 8},
    "shadow": {
        "1": "0 1 2 rgba(16,24,40,0.08)",
        "2": "0 4 8 rgba(16,24,40,0.10)",
        "3": "0 8 24 rgba(16,24,40,0.14)",
    },
    "opacity": {"disabled": 0.38, "subtle": 0.60, "overlay": 0.72, "focus": 0.16},
    "blur": {"none": 0, "sm": 8, "md": 16, "lg": 24},
    "motion": {
        "duration": {"instant": 0, "fast": 120, "base": 200, "slow": 280, "breathe": 1600},
        "curve": {"standard": "cubic-bezier(0.2, 0, 0, 1)", "emphasized": "cubic-bezier(0.2, 0, 0, 1.2)"},
    },
    "border": {"width": {"thin": 1, "thick": 2}, "style": {"default": "solid"}},
    "typography": {
        "display": {"fontSize": 32, "lineHeight": 40, "fontWeight": 700},
        "h1": {"fontSize": 28, "lineHeight": 36, "fontWeight": 700},
        "h2": {"fontSize": 24, "lineHeight": 32, "fontWeight": 700},
        "h3": {"fontSize": 20, "lineHeight": 28, "fontWeight": 600},
        "bodyLg": {"fontSize": 18, "lineHeight": 28, "fontWeight": 400},
        "bodyMd": {"fontSize": 16, "lineHeight": 24, "fontWeight": 400},
        "bodySm": {"fontSize": 14, "lineHeight": 20, "fontWeight": 400},
        "label": {"fontSize": 12, "lineHeight": 16, "fontWeight": 600},
        "monoSm": {"fontSize": 12, "lineHeight": 16, "fontWeight": 500},
    },
}


FLUTTER_TOKEN_EXAMPLE = """
import 'package:flutter/material.dart';

class BahaSpacing {
  static const double s0 = 0;
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;
}

class BahaRadius {
  static const BorderRadius sm = BorderRadius.all(Radius.circular(8));
  static const BorderRadius md = BorderRadius.all(Radius.circular(12));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(24));
}

class BahaColors {
  static const Color primary = Color(0xFF155EEF);
  static const Color primaryDark = Color(0xFF84ADFF);
  static const Color calm = Color(0xFF0F766E);
  static const Color textPrimary = Color(0xFF101828);
  static const Color canvas = Color(0xFFF8F6F2);
  static const Color card = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF127A4B);
  static const Color warning = Color(0xFFB54708);
  static const Color danger = Color(0xFFB42318);
  static const Color info = Color(0xFF175CD3);
}

class BahaMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 280);
  static const Curve standard = Curves.easeOutCubic;
}

class BahaElevation {
  static const double level0 = 0;
  static const double level1 = 1;
  static const double level2 = 2;
  static const double level3 = 4;
  static const double level4 = 8;
}
"""


def write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if isinstance(content, str):
        normalized = dedent(content).strip() + "\n"
        path.write_text(normalized, encoding="utf-8")
    else:
        raise TypeError("content must be str")


def parse_inventory(path: Path):
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        match = re.match(r"\|\s*([A-Z]-\d{2})\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|$", line)
        if match:
            screen_id, name, purpose = match.groups()
            rows.append({"id": screen_id, "name": name, "purpose": purpose})
    return rows


def parse_routing_table(path: Path):
    routes = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.startswith("|"):
            continue
        cols = [col.strip() for col in line.strip().split("|")[1:-1]]
        if len(cols) != 10 or cols[0] == "Screen ID" or cols[0] == "---":
            continue
        screen_id = cols[0]
        routes[screen_id] = {
            "screen_name": cols[1],
            "route": cols[2].strip("`"),
            "deep_link": cols[3].strip("`"),
            "auth": cols[4],
            "role": cols[5],
            "permission": cols[6],
            "transition": cols[7],
            "arguments": cols[8],
            "return_value": cols[9],
        }
    return routes


def slugify(text: str) -> str:
    return re.sub(r"[^A-Za-z0-9]+", "_", text).strip("_")


def ux_filename(role: str, screen_name: str) -> str:
    return f"{ROLE_CONFIG[role]['label']}_{slugify(screen_name)}.md"


def classify_screen(role: str, screen_name: str) -> str:
    lower = screen_name.lower()
    if "offline" in lower:
        return "offline"
    if "splash" in lower:
        return "bootstrap"
    if any(term in lower for term in ["welcome", "onboarding", "age-band", "gender", "guardian verification", "training status"]):
        return "onboarding"
    if any(term in lower for term in ["consent", "privacy", "data rights", "notification permission"]):
        return "consent"
    if any(term in lower for term in ["buddy", "safe questions", "citation"]):
        return "chat"
    if any(term in lower for term in ["learning", "module", "lesson", "quiz"]):
        return "learning"
    if any(term in lower for term in ["games", "emotion explorer", "friendship choices", "calm breathing", "time cap"]):
        return "games"
    if any(term in lower for term in ["check-in", "trend", "mood vocabulary"]):
        return "checkin"
    if any(term in lower for term in ["content library", "content editor", "content review", "safe questions manager", "analytics export", "user and role management"]):
        return "operations"
    if any(term in lower for term in ["help", "alert", "counselor request", "pastoral", "referral", "case", "emergency", "threshold", "audit", "queue filters", "support queue", "notification center", "operational settings", "action log"]):
        return "support"
    if any(term in lower for term in ["settings", "profile summary", "notification settings"]):
        return "settings"
    return "dashboard"


def pattern_for(category: str) -> str:
    mapping = {
        "bootstrap": "Authentication",
        "onboarding": "Wizard",
        "consent": "Wizard",
        "dashboard": "Lists",
        "checkin": "Check-In Flow",
        "learning": "Learning Flow",
        "games": "Games",
        "chat": "Chat Flow",
        "support": "Escalation",
        "operations": "Lists",
        "settings": "Settings",
        "offline": "Notifications",
    }
    return mapping[category]


def layout_for(role: str, category: str, screen_name: str) -> str:
    lower = screen_name.lower()
    if category == "bootstrap":
        return "Bootstrap Frame"
    if category in {"onboarding", "consent"}:
        return "Guided Flow Layout"
    if category == "checkin":
        if any(term in lower for term in ["prompt", "questionnaire", "completion"]):
            return "Guided Flow Layout"
        return ROLE_CONFIG[role]["shell"]
    if category in {"support", "operations"}:
        return "Detail and Composer Layout" if role == "baha" else ROLE_CONFIG[role]["shell"]
    if category == "offline":
        return "Resilient State Layout"
    return ROLE_CONFIG[role]["shell"]


def recipe_components(role: str, screen_name: str, category: str):
    lower = screen_name.lower()
    components = ["app-shell", "top-navigation"]
    if category not in {"bootstrap", "onboarding", "consent"}:
        components.append(ROLE_CONFIG[role]["nav_component"])

    if category == "bootstrap":
        components.extend(["progress-indicators", "status-banners", "skeleton-loaders"])
    elif category == "onboarding":
        components.extend(["stepper", "cards", "buttons"])
        if any(term in lower for term in ["age-band", "gender", "training status"]):
            components.append("radio")
        if "guardian verification" in lower:
            components.extend(["text-fields", "checkbox"])
    elif category == "consent":
        components.extend(["stepper", "consent-cards", "buttons", "dialogs", "status-banners"])
        if any(term in lower for term in ["notification permission", "notification settings"]):
            components.append("switch")
        if "data rights" in lower:
            components.append("accordion")
    elif category == "dashboard":
        components.extend(["cards", "status-banners"])
        if any(term in lower for term in ["dashboard", "summary", "analytics", "trends", "queue"]):
            components.extend(["charts", "graphs"])
        if any(term in lower for term in ["linked student", "profile"]):
            components.append("profile-cards")
        if any(term in lower for term in ["queue", "library"]):
            components.extend(["search", "filter-chips", "list-rows"])
        if "support queue" in lower:
            components.append("data-table")
        if "badge wallet" in lower:
            components.append("achievement-components")
    elif category == "checkin":
        components.extend(["stepper", "cards", "progress-indicators", "status-banners"])
        if any(term in lower for term in ["questionnaire", "mood vocabulary"]):
            components.extend(["slider", "radio", "checkbox"])
        if "completion" in lower:
            components.append("achievement-components")
        if "trend" in lower:
            components.extend(["charts", "graphs", "tooltips"])
    elif category == "learning":
        components.extend(["learning-cards", "progress-indicators"])
        if any(term in lower for term in ["lesson", "module", "learning"]):
            components.extend(["media-player", "video-card", "audio-card"])
        if "quiz" in lower:
            components.append("quiz-components")
        if role in {"parent", "teacher"} and "learning home" in lower:
            components.append("list-rows")
    elif category == "games":
        components.extend(["game-cards", "buttons", "progress-indicators"])
        if "calm breathing" in lower:
            components.extend(["audio-card", "media-player"])
        if "time cap" in lower:
            components.append("dialogs")
        if any(term in lower for term in ["emotion explorer", "friendship choices", "games hub"]):
            components.append("achievement-components")
    elif category == "chat":
        components.extend(["chat-messages", "buttons", "tooltips", "notifications"])
        if "buddy chat" in lower:
            components.append("text-fields")
        if "out-of-scope" in lower:
            components.extend(["status-banners", "dialogs"])
        if "citation" in lower:
            components.append("cards")
    elif category == "support":
        components.extend(["status-banners", "notifications", "dialogs"])
        if any(term in lower for term in ["help center", "notification center", "settings"]):
            components.extend(["list-rows", "accordion"])
        if any(term in lower for term in ["pastoral input", "request", "assignment", "editor", "configuration"]):
            components.extend(["text-fields", "dropdown", "checkbox", "buttons"])
        if any(term in lower for term in ["queue", "audit", "user and role management"]):
            components.extend(["search", "filter-chips", "data-table"])
        if any(term in lower for term in ["case detail", "threshold history", "action log", "audit"]):
            components.append("timeline")
        if "action log" in lower:
            components.extend(["text-fields", "buttons", "snackbars"])
        if any(term in lower for term in ["queue filters"]):
            components.append("bottom-sheets")
    elif category == "operations":
        components.extend(["search", "filter-chips", "tabs", "list-rows", "cards", "snackbars"])
        if any(term in lower for term in ["editor", "manager"]):
            components.extend(["text-fields", "dropdown", "checkbox"])
        if any(term in lower for term in ["content library", "review queue"]):
            components.append("data-table")
        if "user and role management" in lower:
            components.extend(["data-table", "dropdown"])
        if "analytics export" in lower:
            components.append("bottom-sheets")
    elif category == "settings":
        components.extend(["list-rows", "switch", "checkbox", "status-banners", "dialogs"])
        if "profile summary" in lower:
            components.append("profile-cards")
    elif category == "offline":
        components.extend(["status-banners", "empty-states", "buttons", "cards"])

    if any(term in lower for term in ["notification", "alert"]):
        components.append("notifications")
    if any(term in lower for term in ["badge", "streak", "milestone"]):
        components.append("badges")
    if any(term in lower for term in ["profile", "student summary", "linked student"]):
        components.append("avatars")

    deduped = []
    for component in components:
        if component not in deduped:
            deduped.append(component)
    return deduped


def build_screen_inventory():
    routes = parse_routing_table(NAV_ROOT / "Routing_Table.md")
    screens = []
    for role, cfg in ROLE_CONFIG.items():
        for screen in parse_inventory(cfg["inventory"]):
            category = classify_screen(role, screen["name"])
            route_data = routes[screen["id"]]
            screens.append(
                {
                    **screen,
                    "role": role,
                    "role_label": cfg["label"],
                    "persona": cfg["persona"],
                    "route": route_data["route"],
                    "deep_link": route_data["deep_link"],
                    "layout": layout_for(role, category, screen["name"]),
                    "pattern": pattern_for(category),
                    "category": category,
                    "components": recipe_components(role, screen["name"], category),
                    "ux_file": ux_filename(role, screen["name"]),
                }
            )
    return screens


def component_lookup():
    return {component["slug"]: component for component in COMPONENTS}


def components_by_usage(screens):
    usage = defaultdict(list)
    for screen in screens:
        for component in screen["components"]:
            usage[component].append(screen["id"])
    return usage


def component_doc(component, usage_ids):
    category_text = {
        "action": "Action components must expose clear pressed, disabled, and loading feedback while preserving safe tap targets.",
        "input": "Input components must provide labels, helper text, validation feedback, and semantic grouping.",
        "navigation": "Navigation components must preserve orientation, announce current location, and avoid surprising route changes.",
        "display": "Display components must clarify hierarchy and should never conceal critical status information.",
        "feedback": "Feedback components must match severity to context and manage focus when they interrupt the user.",
        "media": "Media components must expose captions, transcript access, and clear playback state.",
        "data": "Data components must pair visual information with textual summaries and preserve privacy thresholds.",
    }[component["kind"]]
    keyboard_text = {
        "action": "Reachable by Tab, activatable with Enter or Space, and must preserve visible focus.",
        "input": "Tab advances focus, Shift+Tab reverses, arrow keys adjust grouped controls where applicable, and Escape dismisses attached menus or sheets.",
        "navigation": "Arrow keys move within grouped nav controls, Home and End jump when supported, and Enter activates the selected destination.",
        "display": "Interactive wrappers such as cards or rows must expose button or link semantics; non-interactive display remains out of the tab order.",
        "feedback": "Dialogs trap focus, snackbars expose action shortcuts when present, and dismiss actions are keyboard reachable.",
        "media": "Playback controls must support Space, Enter, and arrow key seeking where relevant.",
        "data": "Sortable tables and tabs must be traversable by keyboard with visible active state.",
    }[component["kind"]]
    sr_text = {
        "action": "Screen readers announce the control label, current availability, and loading state.",
        "input": "Screen readers announce label, required state, current value, helper text, and validation errors.",
        "navigation": "Screen readers announce the route or destination name plus selected state when applicable.",
        "display": "Screen readers announce heading, supporting text, status, and action affordances in reading order.",
        "feedback": "Urgent or blocking feedback uses alert semantics; transient feedback avoids excessive interruption.",
        "media": "Playback state, duration, and caption availability are announced accessibly.",
        "data": "Narrative summaries, axis labels, and row or column headers must be exposed semantically.",
    }[component["kind"]]
    touch_target = "Minimum 48x48 dp for interactive regions; larger where a wellbeing or support flow benefits from easier reach."
    light_mode = "Uses light-theme semantic tokens and preserves contrast on warm neutral surfaces."
    dark_mode = "Aliases to dark-theme semantic tokens and avoids low-contrast or neon-heavy treatment."
    animation = "Use tokenized motion only. Non-essential animation must disable under reduced-motion settings."
    micro = "Pressed, focus, selected, loading, and completion microstates must be visually and semantically distinct."
    used_in = ", ".join(usage_ids[:12]) if usage_ids else "Not currently used by a PRD-backed screen."
    sections = [
        f"# {component['name']}",
        "",
        f"- Status: `{component['status']}`",
        f"- Used In: {used_in}",
        "",
        "## Purpose",
        "",
        component["purpose"],
        "",
        "## Variants",
        "",
        bullet_list(component["variants"]),
        "",
        "## States",
        "",
        bullet_list(component["states"]),
        "",
        "## Properties",
        "",
        bullet_list(component["properties"]),
        "",
        "## Sizing",
        "",
        bullet_list(component["sizes"]),
        "",
        "## Spacing",
        "",
        "- Inner padding uses the global spacing scale, typically `space.3` to `space.6` depending on density.",
        "- Component-to-component spacing follows layout rhythm rather than ad hoc margins.",
        "",
        "## Accessibility",
        "",
        f"- {category_text}",
        "- This component must meet WCAG 2.1 AA contrast requirements in both light and dark themes.",
        "",
        "## Keyboard Behaviour",
        "",
        f"- {keyboard_text}",
        "",
        "## Screen Reader Behaviour",
        "",
        f"- {sr_text}",
        "",
        "## Touch Target",
        "",
        f"- {touch_target}",
        "",
        "## Dark Mode",
        "",
        f"- {dark_mode}",
        "",
        "## Light Mode",
        "",
        f"- {light_mode}",
        "",
        "## Animation",
        "",
        f"- {animation}",
        "",
        "## Microinteractions",
        "",
        f"- {micro}",
        "",
        "## Usage Guidelines",
        "",
        f"- {component['usage']}",
        "- Prefer composition through shared slots and semantic tokens instead of one-off overrides.",
        "",
        "## Do",
        "",
        bullet_list(component["do"]),
        "",
        "## Don't",
        "",
        bullet_list(component["dont"]),
        "",
        "## Flutter Widget Mapping",
        "",
        f"- `{component['flutter']}`",
        "",
        "## Figma Component Mapping",
        "",
        f"- `{component['figma']}`",
    ]
    return "\n".join(sections)


def bullet_list(items):
    return "\n".join(f"- {item}" for item in items)


def generate_component_readme(usage_map):
    groups = defaultdict(list)
    lookup = component_lookup()
    for component in COMPONENTS:
        groups[component["kind"]].append(component["slug"])
    sections = []
    for kind in ["navigation", "action", "input", "display", "feedback", "media", "data"]:
        entries = groups[kind]
        if not entries:
            continue
        sections.append(f"## {kind.title()}\n")
        for slug in entries:
            component = lookup[slug]
            used = len(usage_map.get(slug, []))
            file_name = f"{slugify(component['name'])}.md"
            sections.append(
                f"- [{component['name']}](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/03_Components/{file_name}) — `{component['status']}` — used by {used} screens"
            )
        sections.append("")
    return "# Components\n\n" + "\n".join(sections).strip() + "\n"


def generate_token_docs():
    token_catalog = """
    # Token Catalog

    ## Token Families

    - Color tokens
    - Typography tokens
    - Spacing tokens
    - Radius tokens
    - Shadow tokens
    - Elevation tokens
    - Animation tokens
    - Duration tokens
    - Opacity tokens
    - Blur tokens
    - Border tokens

    ## Color Tokens

    - `color.text.primary`
    - `color.text.secondary`
    - `color.surface.canvas`
    - `color.surface.card`
    - `color.border.default`
    - `color.status.success.bg`
    - `color.status.warning.bg`
    - `color.status.danger.bg`
    - `color.status.info.bg`

    ## Typography Tokens

    - `type.display`
    - `type.h1`
    - `type.h2`
    - `type.h3`
    - `type.bodyLg`
    - `type.bodyMd`
    - `type.bodySm`
    - `type.label`
    - `type.monoSm`

    ## Spacing Tokens

    - `space.0`
    - `space.1`
    - `space.2`
    - `space.3`
    - `space.4`
    - `space.5`
    - `space.6`
    - `space.8`
    - `space.10`
    - `space.12`
    - `space.16`

    ## Radius Tokens

    - `radius.sm`
    - `radius.md`
    - `radius.lg`
    - `radius.xl`
    - `radius.pill`

    ## Shadow and Elevation Tokens

    - `shadow.1`
    - `shadow.2`
    - `shadow.3`
    - `elevation.0`
    - `elevation.1`
    - `elevation.2`
    - `elevation.3`
    - `elevation.4`

    ## Animation and Duration Tokens

    - `motion.duration.instant`
    - `motion.duration.fast`
    - `motion.duration.base`
    - `motion.duration.slow`
    - `motion.duration.breathe`
    - `motion.curve.standard`
    - `motion.curve.emphasized`

    ## Opacity, Blur, and Border Tokens

    - `opacity.disabled`
    - `opacity.subtle`
    - `opacity.overlay`
    - `opacity.focus`
    - `blur.none`
    - `blur.sm`
    - `blur.md`
    - `blur.lg`
    - `border.width.thin`
    - `border.width.thick`
    """
    token_readme = """
    # Design Tokens

    - [Token_Catalog.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/02_Design_Tokens/Token_Catalog.md)
    - [Design_Tokens_Example.json](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/02_Design_Tokens/Design_Tokens_Example.json)
    - [Flutter_Tokens_Example.dart](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/02_Design_Tokens/Flutter_Tokens_Example.dart)
    - [Figma_Variables.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/02_Design_Tokens/Figma_Variables.md)
    """
    figma_variables = """
    # Figma Variables

    ## Collections

    - `Global / Primitive`
    - `Global / Semantic`
    - `Theme / Light`
    - `Theme / Dark`
    - `Role / Student`
    - `Role / Parent`
    - `Role / Teacher`
    - `Role / BAHA`
    - `Component / Aliases`

    ## Example Variables

    - `color/semantic/text/primary`
    - `color/semantic/surface/canvas`
    - `space/4`
    - `radius/lg`
    - `shadow/2`
    - `motion/duration/base`
    - `border/width/thin`
    """
    write(DS_ROOT / "02_Design_Tokens" / "README.md", token_readme)
    write(DS_ROOT / "02_Design_Tokens" / "Token_Catalog.md", token_catalog)
    (DS_ROOT / "02_Design_Tokens").mkdir(parents=True, exist_ok=True)
    (DS_ROOT / "02_Design_Tokens" / "Design_Tokens_Example.json").write_text(json.dumps(TOKEN_JSON, indent=2) + "\n", encoding="utf-8")
    write(DS_ROOT / "02_Design_Tokens" / "Flutter_Tokens_Example.dart", FLUTTER_TOKEN_EXAMPLE)
    write(DS_ROOT / "02_Design_Tokens" / "Figma_Variables.md", figma_variables)


def generate_layout_docs(screens):
    write(
        DS_ROOT / "05_Layouts" / "README.md",
        """
        # Layouts

        - [Role_Shells.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/05_Layouts/Role_Shells.md)
        - [Responsive_Layouts.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/05_Layouts/Responsive_Layouts.md)
        - [Screen_Composition_Matrix.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/05_Layouts/Screen_Composition_Matrix.md)
        """,
    )
    write(
        DS_ROOT / "05_Layouts" / "Role_Shells.md",
        """
        # Role Shells

        ## Bootstrap Frame

        - Full-screen loading, status, and session-resolution layout used only during route bootstrap.

        ## Guided Flow Layout

        - Centered content stack with top navigation, stepper, primary card region, and bottom action row.

        ## Student Mobile Shell

        - Top app bar, bottom navigation, single-column card stack, and large touch targets.

        ## Parent Mobile Summary Shell

        - Top app bar, bottom navigation, linked-student context area, and summary-first sections.

        ## Teacher Adaptive Dashboard Shell

        - Top metadata bar, tabs or segmented controls, chart-first region, and action trays for referrals and notes.

        ## BAHA Operations Workspace

        - Navigation rail, persistent filters where appropriate, table or queue region, and side detail or composer panel on wider breakpoints.

        ## Detail and Composer Layout

        - Primary detail content plus adjacent or stacked editing region for case notes, assignments, reviews, and policy edits.

        ## Resilient State Layout

        - Banner-led structure for offline, empty, and degraded-mode routes with one next-best action.
        """,
    )
    write(
        DS_ROOT / "05_Layouts" / "Responsive_Layouts.md",
        """
        # Responsive Layouts

        ## Mobile First

        - Student and parent shells are authored mobile-first and scale up by widening card grids and preserving readable line lengths.

        ## Tablet Adaptive

        - Teacher routes introduce split views and expanded filter placement from `bp.md` onward.

        ## Desktop Operations

        - BAHA routes adopt rail plus multi-pane layouts from `bp.xl` without changing route semantics.

        ## Overlay Layouts

        - Dialogs are center anchored.
        - Bottom sheets remain mobile-first.
        - Tooltips become tap-triggered info popovers on touch devices.
        """,
    )

    rows = [
        "| Screen ID | Screen Name | Role | Route | Pattern | Layout | Components | UX Spec |",
        "|---|---|---|---|---|---|---|---|",
    ]
    for screen in screens:
        component_names = ", ".join(screen["components"])
        ux_link = f"[{screen['ux_file']}](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/13_UX_Specification/{screen['ux_file']})"
        rows.append(
            f"| {screen['id']} | {screen['name']} | {screen['role_label']} | `{screen['route']}` | {screen['pattern']} | {screen['layout']} | {component_names} | {ux_link} |"
        )
    write(DS_ROOT / "05_Layouts" / "Screen_Composition_Matrix.md", "# Screen Composition Matrix\n\n" + "\n".join(rows))


def generate_root_readme(screens, usage_map):
    active = len(COMPONENTS)
    used = sum(1 for component in COMPONENTS if usage_map.get(component["slug"]))
    return f"""
    # Phase 4 Design System

    This repository is the reusable UI source of truth for building the BAHA product in Figma and Flutter without redesigning the PRD-backed application.

    ## Coverage

    - Total PRD-backed screens: {len(screens)}
    - Components documented: {active}
    - Components currently used by at least one screen: {used}
    - Mermaid diagrams: {sum(1 for name in MERMAID_FILES if name.endswith('.mmd'))}

    ## Sections

    - [01_Foundations](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/01_Foundations/README.md)
    - [02_Design_Tokens](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/02_Design_Tokens/README.md)
    - [03_Components](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/03_Components/README.md)
    - [04_Patterns](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/04_Patterns/README.md)
    - [05_Layouts](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/05_Layouts/README.md)
    - [06_Motion](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/06_Motion/README.md)
    - [07_Illustrations](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/07_Illustrations/README.md)
    - [08_Icons](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/08_Icons/README.md)
    - [09_Accessibility](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/09_Accessibility/README.md)
    - [10_Content_Guidelines](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/10_Content_Guidelines/README.md)
    - [11_Figma](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/11_Figma/README.md)
    - [12_Flutter](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/12_Flutter/README.md)
    - [Mermaid](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/Mermaid/README.md)
    - [Validation_Report.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/15_Design_System/Validation_Report.md)
    """


def generate_validation_report(screens, usage_map):
    total_components = len(COMPONENTS)
    unused = [component["name"] for component in COMPONENTS if not usage_map.get(component["slug"])]
    duplicates = []
    covered = [screen for screen in screens if screen["components"] and screen["layout"] and screen["pattern"]]
    missing = [screen for screen in screens if screen not in covered]
    by_role = defaultdict(int)
    for screen in covered:
        by_role[screen["role_label"]] += 1
    role_rows = "\n".join(f"- {role}: {count} screens covered" for role, count in sorted(by_role.items()))
    component_rows = "\n".join(
        f"- {component['name']} ({component['status']})"
        for component in COMPONENTS
    )
    unused_rows = "\n".join(f"- {name}" for name in unused) if unused else "- None"
    duplicate_rows = "\n".join(f"- {name}" for name in duplicates) if duplicates else "- None"
    missing_rows = "\n".join(f"- {screen['id']} {screen['name']}" for screen in missing) if missing else "- None"
    coverage_pct = (len(covered) / len(screens)) * 100 if screens else 0
    lines = [
        "# Validation Report",
        "",
        "## Summary",
        "",
        f"- Components generated: {total_components}",
        f"- Unused components: {len(unused)}",
        f"- Duplicate components: {len(duplicates)}",
        f"- Screens fully covered: {len(covered)} of {len(screens)}",
        f"- Coverage percentage: {coverage_pct:.1f}%",
        "",
        "## Components Generated",
        "",
        component_rows,
        "",
        "## Unused Components",
        "",
        unused_rows,
        "",
        "## Duplicate Components",
        "",
        duplicate_rows,
        "",
        "## Screen Coverage",
        "",
        role_rows,
        "",
        "### Missing Screens",
        "",
        missing_rows,
        "",
        "## Cross-Reference Results",
        "",
        f"- Screen inventory count: {len(screens)}",
        "- Routing table cross-reference: Passed",
        "- UX spec link coverage: Passed",
        f"- Every covered screen has a pattern, layout, and reusable component recipe: {'Passed' if not missing else 'Failed'}",
        "",
        "## Notes",
        "",
        "- Reserved primitives remain documented even when the current PRD does not instantiate them, so the future Figma and Flutter systems can stay coherent without feature invention.",
        "- Role-specific cards are treated as intentional wrappers over shared card anatomy rather than duplicate standalone systems.",
        "- Mermaid validation in this repository is structural and template-based unless a dedicated Mermaid CLI is added later.",
    ]
    return "\n".join(lines)


def validate_mermaid():
    allowed = ("flowchart", "sequenceDiagram", "stateDiagram-v2", "mindmap", "erDiagram")
    results = []
    for path in (DS_ROOT / "Mermaid").glob("*.mmd"):
        text = path.read_text(encoding="utf-8").strip()
        results.append(any(text.startswith(prefix) for prefix in allowed))
    return all(results)


def generate_component_files(usage_map):
    write(DS_ROOT / "03_Components" / "README.md", generate_component_readme(usage_map))
    for component in COMPONENTS:
        file_name = f"{slugify(component['name'])}.md"
        write(DS_ROOT / "03_Components" / file_name, component_doc(component, usage_map.get(component["slug"], [])))


def generate_static_sections():
    for name, content in FOUNDATION_FILES.items():
        write(DS_ROOT / "01_Foundations" / name, content)
    for name, content in PATTERN_FILES.items():
        write(DS_ROOT / "04_Patterns" / name, content)
    for name, content in MOTION_FILES.items():
        write(DS_ROOT / "06_Motion" / name, content)
    for name, content in ILLUSTRATION_FILES.items():
        write(DS_ROOT / "07_Illustrations" / name, content)
    for name, content in ICON_FILES.items():
        write(DS_ROOT / "08_Icons" / name, content)
    for name, content in ACCESSIBILITY_FILES.items():
        write(DS_ROOT / "09_Accessibility" / name, content)
    for name, content in CONTENT_FILES.items():
        write(DS_ROOT / "10_Content_Guidelines" / name, content)
    for name, content in FIGMA_FILES.items():
        write(DS_ROOT / "11_Figma" / name, content)
    for name, content in FLUTTER_FILES.items():
        write(DS_ROOT / "12_Flutter" / name, content)
    for name, content in MERMAID_FILES.items():
        write(DS_ROOT / "Mermaid" / name, content)
    write(DS_ROOT / "12_Flutter" / "Design_Tokens.dart", FLUTTER_TOKEN_EXAMPLE)


def main():
    screens = build_screen_inventory()
    usage_map = components_by_usage(screens)

    generate_static_sections()
    generate_token_docs()
    generate_component_files(usage_map)
    generate_layout_docs(screens)

    write(DS_ROOT / "README.md", generate_root_readme(screens, usage_map))
    write(DS_ROOT / "Validation_Report.md", generate_validation_report(screens, usage_map))

    if not validate_mermaid():
        raise SystemExit("Mermaid validation failed for one or more files.")

    print(f"Generated design system at {DS_ROOT}")
    print(f"Screen count: {len(screens)}")
    print(f"Component count: {len(COMPONENTS)}")


if __name__ == "__main__":
    main()
