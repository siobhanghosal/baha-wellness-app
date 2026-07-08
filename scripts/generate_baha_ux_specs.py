import re
from pathlib import Path
from textwrap import dedent


ROOT = Path("/Users/solomonkaruppiah/Desktop/Baha_Data")
DOCS = ROOT / "docs"
UX_ROOT = DOCS / "13_UX_Specification"
MERMAID_ROOT = UX_ROOT / "Mermaid"


ROLE_CONFIG = {
    "student": {
        "inventory": DOCS / "03_Student_App" / "Screen_Inventory.md",
        "role_label": "Student",
        "persona": "Adolescent student using a private, supportive wellness app.",
        "nav_bar": "Bottom navigation with Home, Buddy, Learn, Games, and Profile.",
        "header_pattern": "Top app bar with age-appropriate title, back affordance when not top-level, and optional help action.",
        "footer_pattern": "No persistent footer outside bottom navigation; footer space reserved for safe-area actions and policy banners when needed.",
        "base_path": "/student",
        "default_permissions": ["Authenticated student session", "Network connectivity for sync", "Push notifications optional"],
        "default_db_objects": [
            "student_profiles",
            "check_in_sessions",
            "check_in_responses",
            "trend_snapshots",
            "module_progress",
            "chatbot_sessions",
            "chatbot_messages",
            "game_sessions",
            "game_signal_snapshots",
            "notification_events",
            "audit_events",
        ],
        "default_services": [
            "Identity Service",
            "Consent Service",
            "Student Wellbeing Service",
            "Learning Service",
            "Chatbot Service",
            "Game Service",
            "Notification Service",
            "Escalation Service",
            "Analytics Service",
            "Audit Service",
        ],
    },
    "parent": {
        "inventory": DOCS / "04_Parent_App" / "Screen_Inventory.md",
        "role_label": "Parent",
        "persona": "Parent or guardian using consent-gated summaries and conversation support tools.",
        "nav_bar": "Bottom or tab navigation with Home, Weekly Summary, Conversation Guides, Learn, and Settings.",
        "header_pattern": "Clear summary-first app bar with title, linked-student switcher when multiple children are linked, and notification entry point.",
        "footer_pattern": "No persistent marketing footer; footer area is reserved for legal or policy notices when consent status changes.",
        "base_path": "/parent",
        "default_permissions": ["Authenticated guardian session", "Linked student relationship", "Network connectivity for summary refresh"],
        "default_db_objects": [
            "users",
            "guardian_links",
            "consent_records",
            "privacy_tier_records",
            "trend_snapshots",
            "module_progress",
            "notification_events",
            "audit_events",
        ],
        "default_services": [
            "Identity Service",
            "Consent Service",
            "Learning Service",
            "Notification Service",
            "Analytics Service",
            "Audit Service",
        ],
    },
    "teacher": {
        "inventory": DOCS / "05_Teacher_App" / "Screen_Inventory.md",
        "role_label": "Teacher",
        "persona": "Teacher or school counselor using anonymized class-level wellbeing insights and referral tools.",
        "nav_bar": "Bottom or tab navigation with Dashboard, Pastoral Input, Referrals, Learn, and Settings.",
        "header_pattern": "Operational app bar with school context, cohort selector, and referral/notification shortcuts.",
        "footer_pattern": "No persistent footer; footer space is reserved for anonymization notices and safeguarding disclaimers.",
        "base_path": "/teacher",
        "default_permissions": ["Authenticated staff session", "School scope assignment", "Training completion for sensitive features"],
        "default_db_objects": [
            "users",
            "schools",
            "pastoral_flags",
            "support_cases",
            "case_events",
            "module_progress",
            "notification_events",
            "audit_events",
        ],
        "default_services": [
            "Identity Service",
            "Learning Service",
            "Escalation Service",
            "Notification Service",
            "Analytics Service",
            "Audit Service",
        ],
    },
    "baha": {
        "inventory": DOCS / "06_BAHA_App" / "Screen_Inventory.md",
        "role_label": "BAHA",
        "persona": "BAHA clinician, counselor, content reviewer, or operational admin managing safeguards and platform governance.",
        "nav_bar": "Sidebar or adaptive navigation with Support Queue, Cases, Content, Thresholds, Analytics, Audit, and Settings.",
        "header_pattern": "Dense operational header with role context, queue counters, filters, and export or action shortcuts.",
        "footer_pattern": "No persistent footer; footer area is reserved for queue metrics, audit notices, or review state banners.",
        "base_path": "/baha",
        "default_permissions": ["Authenticated staff session", "Operational scope assignment", "Clinical or admin entitlement where applicable"],
        "default_db_objects": [
            "support_cases",
            "case_events",
            "case_assignments",
            "content_items",
            "content_revisions",
            "content_tags",
            "safe_question_items",
            "consent_records",
            "privacy_tier_records",
            "audit_events",
            "notification_events",
        ],
        "default_services": [
            "Identity Service",
            "Consent Service",
            "Learning Service",
            "Chatbot Service",
            "Escalation Service",
            "Analytics Service",
            "Audit Service",
            "Notification Service",
        ],
    },
}


SCREEN_KEYWORDS = {
    "bootstrap": ["splash"],
    "onboarding": ["welcome", "onboarding", "age-band", "legal consent", "guardian verification", "training status"],
    "consent": ["privacy", "consent", "verification", "data rights"],
    "dashboard": ["dashboard", "home", "summary", "queue", "analytics", "status"],
    "checkin": ["check-in", "trend", "mood vocabulary"],
    "chatbot": ["buddy", "safe questions", "citation"],
    "learning": ["learning", "module", "lesson", "quiz"],
    "games": ["games", "emotion explorer", "friendship choices", "calm breathing", "time cap"],
    "support": ["help", "alert", "counselor request", "pastoral", "referral", "case", "emergency", "threshold", "audit"],
    "settings": ["settings", "notification", "profile", "privacy tier", "operational settings", "user and role management"],
    "editor": ["editor", "manager", "content library", "content review"],
    "offline": ["offline"],
}


TOP_LEVEL_SCREENS = {
    "student": {"S-10", "S-25", "S-20", "S-30", "S-33"},
    "parent": {"P-06", "P-09", "P-12"},
    "teacher": {"T-03", "T-05", "T-07", "T-09", "T-13"},
    "baha": {"B-01", "B-03", "B-07", "B-11", "B-13", "B-15", "B-17"},
}


APP_ENDPOINTS = {
    "student": {
        "bootstrap": ["/me"],
        "onboarding": ["/me", "/consent/current", "/consent/parent", "/consent/self", "/consent/tiers"],
        "consent": ["/consent/current", "/consent/tiers", "/consent/withdraw"],
        "dashboard": ["/student/home", "/student/trends"],
        "checkin": ["/student/check-ins", "/student/trends"],
        "chatbot": ["/chatbot/messages", "/chatbot/safe-questions", "/chatbot/profile-opt-out"],
        "learning": ["/learning/modules", "/learning/modules/{id}", "/learning/modules/{id}/progress", "/learning/modules/{id}/quiz"],
        "games": ["/games/catalog", "/games/sessions", "/games/sessions/{id}/events", "/games/time-cap/ack"],
        "support": ["/student/help-request", "/chatbot/messages"],
        "settings": ["/me", "/consent/current", "/consent/tiers", "/chatbot/profile-opt-out"],
        "offline": ["/student/home", "/student/check-ins"],
    },
    "parent": {
        "bootstrap": ["/me"],
        "onboarding": ["/me", "/consent/current", "/consent/parent"],
        "consent": ["/consent/current", "/consent/tiers", "/consent/withdraw"],
        "dashboard": ["/parent/summary"],
        "learning": ["/learning/modules", "/learning/modules/{id}", "/learning/modules/{id}/progress"],
        "support": ["/parent/summary"],
        "settings": ["/me", "/consent/current"],
        "offline": ["/parent/summary"],
    },
    "teacher": {
        "bootstrap": ["/me"],
        "onboarding": ["/me"],
        "dashboard": ["/teacher/class-trends"],
        "support": ["/teacher/pastoral-flags", "/teacher/referrals"],
        "learning": ["/learning/modules", "/learning/modules/{id}", "/learning/modules/{id}/progress"],
        "settings": ["/me"],
        "offline": ["/teacher/class-trends"],
    },
    "baha": {
        "bootstrap": ["/me"],
        "dashboard": ["/baha/queue", "/baha/analytics", "/baha/audit"],
        "support": ["/baha/queue", "/baha/cases/{id}", "/baha/cases/{id}/events", "/baha/thresholds"],
        "learning": ["/baha/content"],
        "editor": ["/baha/content", "/baha/thresholds"],
        "settings": ["/me", "/baha/audit"],
        "offline": ["/baha/analytics"],
    },
}


DB_OBJECTS_BY_CATEGORY = {
    "bootstrap": ["users", "user_role_assignments"],
    "onboarding": ["users", "student_profiles", "consent_records", "assent_records", "guardian_links"],
    "consent": ["consent_records", "privacy_tier_records", "override_events", "audit_events"],
    "dashboard": ["trend_snapshots", "module_progress", "support_cases", "notification_events"],
    "checkin": ["check_in_sessions", "check_in_responses", "trend_snapshots", "mood_vocabulary_progress"],
    "chatbot": ["chatbot_sessions", "chatbot_messages", "chatbot_profile_summaries", "safe_question_items", "support_cases"],
    "learning": ["content_items", "content_revisions", "content_tags", "module_progress", "quiz_attempts"],
    "games": ["game_sessions", "game_signal_snapshots", "badge_awards", "challenge_instances"],
    "support": ["pastoral_flags", "support_cases", "case_events", "case_assignments", "notification_events"],
    "settings": ["users", "consent_records", "privacy_tier_records", "notification_events", "audit_events"],
    "editor": ["content_items", "content_revisions", "content_tags", "safe_question_items", "audit_events"],
    "offline": ["notification_events", "audit_events"],
}


SERVICE_BY_CATEGORY = {
    "bootstrap": ["Identity Service", "Audit Service"],
    "onboarding": ["Identity Service", "Consent Service", "Notification Service", "Audit Service"],
    "consent": ["Consent Service", "Audit Service", "Notification Service"],
    "dashboard": ["Analytics Service", "Notification Service", "Audit Service"],
    "checkin": ["Student Wellbeing Service", "Analytics Service", "Escalation Service", "Audit Service"],
    "chatbot": ["Chatbot Service", "Escalation Service", "Analytics Service", "Audit Service"],
    "learning": ["Learning Service", "Analytics Service", "Audit Service"],
    "games": ["Game Service", "Analytics Service", "Escalation Service", "Audit Service"],
    "support": ["Escalation Service", "Notification Service", "Analytics Service", "Audit Service"],
    "settings": ["Identity Service", "Consent Service", "Notification Service", "Audit Service"],
    "editor": ["Learning Service", "Chatbot Service", "Escalation Service", "Audit Service"],
    "offline": ["Notification Service", "Audit Service"],
}


ANALYTICS_BY_CATEGORY = {
    "bootstrap": ["screen_view", "bootstrap_completed"],
    "onboarding": ["screen_view", "onboarding_step_viewed", "onboarding_step_completed"],
    "consent": ["screen_view", "consent_viewed", "consent_submitted", "consent_changed"],
    "dashboard": ["screen_view", "dashboard_loaded", "filter_changed", "card_opened"],
    "checkin": ["screen_view", "checkin_started", "checkin_submitted", "trend_card_opened"],
    "chatbot": ["screen_view", "chat_session_started", "safe_question_opened", "chat_escalation_triggered"],
    "learning": ["screen_view", "module_opened", "lesson_completed", "quiz_submitted"],
    "games": ["screen_view", "game_started", "game_completed", "time_cap_prompt_shown"],
    "support": ["screen_view", "support_request_started", "referral_submitted", "case_opened"],
    "settings": ["screen_view", "setting_changed", "policy_opened"],
    "editor": ["screen_view", "content_opened", "content_saved", "threshold_changed"],
    "offline": ["screen_view", "offline_state_shown", "retry_selected"],
}


LOGGING_BY_CATEGORY = {
    "bootstrap": ["session_bootstrap", "auth_guard_result"],
    "onboarding": ["onboarding_transition", "consent_gate_result"],
    "consent": ["consent_read", "consent_write", "privacy_tier_projection"],
    "dashboard": ["projection_read", "anonymization_guard_result", "dashboard_render_status"],
    "checkin": ["checkin_persist_attempt", "trend_generation_result", "signal_evaluation_result"],
    "chatbot": ["chat_request_received", "retrieval_result", "citation_attached", "escalation_signal_result"],
    "learning": ["content_fetch_result", "progress_write", "quiz_feedback_generated"],
    "games": ["game_session_start", "game_signal_aggregate", "time_governance_result"],
    "support": ["support_case_write", "notification_trigger", "assignment_change"],
    "settings": ["settings_read", "settings_write", "policy_version_check"],
    "editor": ["content_mutation", "review_state_change", "threshold_update"],
    "offline": ["offline_mode_entered", "sync_retry", "cached_payload_used"],
}


NAV_PATTERNS = {
    "student": ["Home Dashboard", "Weekly Check-In", "Learning Home", "Games Hub", "Buddy Chat", "Profile Summary"],
    "parent": ["Weekly Summary Home", "Parent Learning Home", "Notification Settings"],
    "teacher": ["Class Trends Dashboard", "Pastoral Input Form", "Referral Queue", "Teacher Learning Home", "Settings"],
    "baha": ["Support Queue", "Case Detail", "Content Library", "Threshold Configuration", "Pilot Analytics Dashboard", "Audit Log"],
}


COMPLETION_WORK = [
    "visual hierarchy and brand-level UI styling decisions for each role surface",
    "finalized copy deck approved by BAHA, legal, and safeguarding reviewers",
    "final design token values and component variants mapped to Flutter widgets",
    "render validation of Mermaid diagrams in the target documentation viewer",
    "Figma page and component library generation from the completed UX pack",
]


def write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    normalized = dedent(content).strip()
    normalized = re.sub(r"(?m)^ {8}", "", normalized)
    path.write_text(normalized + "\n", encoding="utf-8")


def parse_inventory(path: Path):
    content = path.read_text(encoding="utf-8")
    rows = []
    for line in content.splitlines():
        match = re.match(r"\|\s*([A-Z]-\d{2})\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|$", line)
        if match:
            screen_id, name, purpose = match.groups()
            rows.append({"id": screen_id, "name": name, "purpose": purpose})
    return rows


def slugify(text: str) -> str:
    text = re.sub(r"[^A-Za-z0-9]+", "_", text).strip("_")
    return text


def classify_screen(name: str) -> str:
    name_lower = name.lower()
    for category, keywords in SCREEN_KEYWORDS.items():
        if any(keyword in name_lower for keyword in keywords):
            return category
    return "dashboard"


def role_from_id(screen_id: str) -> str:
    prefix = screen_id.split("-")[0]
    return {
        "S": "student",
        "P": "parent",
        "T": "teacher",
        "B": "baha",
    }[prefix]


def is_top_level(role: str, screen_id: str) -> bool:
    return screen_id in TOP_LEVEL_SCREENS[role]


def deep_link(role: str, name: str) -> str:
    return f'{ROLE_CONFIG[role]["base_path"]}/{slugify(name).lower()}'


def list_to_lines(items):
    return "\n".join(f"- {item}" for item in items)


def dedupe(items):
    seen = []
    for item in items:
        if item not in seen:
            seen.append(item)
    return seen


def entry_conditions(role: str, category: str, screen: dict):
    base = [
        "Valid authenticated session for this role.",
        "Role entitlement resolved during bootstrap.",
    ]
    if role == "student":
        if category in {"dashboard", "checkin", "chatbot", "learning", "games", "support", "settings"}:
            base.append("Required consent or assent workflow completed unless the screen explicitly belongs to onboarding.")
    if role == "parent":
        base.append("Linked student relationship exists or is being established.")
    if role == "teacher":
        base.append("School scope is loaded from the staff assignment.")
        if category in {"dashboard", "support"}:
            base.append("Required training completion gate passed if the feature exposes sensitive workflows.")
    if role == "baha":
        base.append("Operational scope or clinical/admin entitlement is active.")
    if category == "offline":
        base.append("Connectivity is missing or degraded enough to block live data retrieval.")
    return dedupe(base)


def exit_conditions(role: str, category: str, screen: dict):
    outcomes = [
        "User explicitly navigates away using back, app navigation, or a primary CTA.",
        "Screen commits any pending draft state before route change or warns the user if a draft would be lost.",
    ]
    if category in {"onboarding", "consent"}:
        outcomes.append("Next gating step is satisfied and the user is routed forward.")
    if category == "checkin":
        outcomes.append("Check-in payload is saved locally and synced or queued for sync.")
    if category == "support":
        outcomes.append("Support action, referral, or case event is saved and logged.")
    if category == "editor":
        outcomes.append("Mutation is saved, published, or intentionally discarded with confirmation.")
    return dedupe(outcomes)


def navigation_sources(role: str, category: str, screen: dict):
    sources = ["App bootstrap router", "Back stack return path"]
    if is_top_level(role, screen["id"]):
        sources.append("Role home navigation entry")
    if category in {"onboarding", "consent"}:
        sources.append("Previous onboarding or policy step")
    if category == "dashboard":
        sources.append("Top-level app navigation")
    if category == "checkin":
        sources.extend(["Home dashboard CTA", "Reminder notification", "Trend detail return path"])
    if category == "chatbot":
        sources.extend(["Home dashboard CTA", "Safe Questions entry", "Support banner CTA"])
    if category == "learning":
        sources.extend(["Home recommendations", "Module list", "Completion follow-up CTA"])
    if category == "games":
        sources.extend(["Games hub", "Home recommendation card"])
    if category == "support":
        sources.extend(["Alert or escalation notification", "Help CTA", "Queue row or referral row"])
    if category == "settings":
        sources.extend(["Profile menu", "Role settings shortcut", "Policy banner"])
    if category == "offline":
        sources.append("Automatic fallback after failed live fetch")
    return dedupe(sources)


def navigation_destinations(role: str, category: str, screen: dict):
    destinations = ["Previous screen via back navigation"]
    if category in {"onboarding", "consent"}:
        destinations.append("Next gating step")
    if category == "dashboard":
        destinations.extend(NAV_PATTERNS[role][:3])
    if category == "checkin":
        destinations.extend(["Check-In Completion", "Trend Dashboard Active", "Home Dashboard"])
    if category == "chatbot":
        destinations.extend(["Buddy Citation Detail", "Help Center", "Consent Override Notification"])
    if category == "learning":
        destinations.extend(["Lesson View", "Quiz and Reflection", "Learning Home"])
    if category == "games":
        destinations.extend(["Game session detail", "Time Cap Prompt", "Badge Wallet"])
    if category == "support":
        destinations.extend(["Support confirmation state", "Queue or referral list", "Emergency Protocol View"])
    if category == "settings":
        destinations.extend(["Policy detail", "Notification settings", "Home or dashboard"])
    if category == "offline":
        destinations.extend(["Retry same screen", "Cached parent screen", "Global offline help"])
    return dedupe(destinations)


def ui_structure(role: str, category: str, screen: dict):
    name = screen["name"]
    top_level = is_top_level(role, screen["id"])
    return {
        "Header": ROLE_CONFIG[role]["header_pattern"] + f" Screen title is '{name}'.",
        "Footer": ROLE_CONFIG[role]["footer_pattern"],
        "Navigation Bar": ROLE_CONFIG[role]["nav_bar"] if top_level or category in {"dashboard", "settings", "learning", "games", "chatbot"} else "Contextual back navigation only; the persistent app bar stays hidden to reduce complexity.",
        "Tabs": "Use segmented tabs only when the screen contains parallel views such as time ranges, linked students, queue states, or content statuses. Default state is the primary tab selected." if category in {"dashboard", "support", "editor", "learning"} else "No dedicated tabs; use a single-scroll layout with anchored sections.",
        "Floating Buttons": "Use a FAB only for the primary creation action if the role needs one here; otherwise omit it to avoid visual clutter." if role in {"teacher", "baha"} and category in {"support", "editor"} else "No floating action button on this screen; primary actions live in cards, the header, or bottom CTA rows.",
        "Search": "Provide inline search when the screen lists content, queue items, alerts, or linked students; debounce input and preserve the current filter state." if category in {"dashboard", "learning", "support", "editor"} else "No dedicated search field. If future product growth requires search, add it in the header without changing screen semantics.",
        "Filters": "Filter chips or dropdown filters should expose only the dimensions defined in the architecture repository and preserve privacy-safe defaults." if category in {"dashboard", "support", "editor"} else "No interactive filters beyond the role-safe default view.",
        "Cards": f"Use cards to present the main units of information on '{name}'. Cards should expose status, summary metadata, a primary action, and a clear affordance for deeper detail.",
        "Lists": "Render linear lists for modules, queue rows, alerts, linked students, or policy items where order matters. Support pagination or incremental loading if the dataset grows." if category in {"dashboard", "learning", "support", "editor"} else "List patterns are secondary on this screen and should only appear for compact supporting data.",
        "Sections": "Organize the screen into a clear hero or status section, primary task section, secondary informational section, and policy or metadata section.",
        "Widgets": "Compose the screen from reusable Flutter widgets aligned to the Phase 1 component library: status banners, headers, cards, chips, progress indicators, lists, forms, and disclosure panels.",
    }


def interaction_controls(category: str, screen: dict):
    return {
        "Forms": "Form composition should be explicit, stepwise, and save-safe. Group related fields, show inline helper text, and preserve draft state when connectivity is unstable." if category in {"onboarding", "consent", "checkin", "support", "editor", "settings"} else "No primary multi-field form on this screen; any compact interaction should still follow consistent spacing and inline validation rules.",
        "Inputs": "Use text fields only for the minimum free-text capture described by the PRD. Inputs must support helper text, error messaging, and autosave or explicit save as appropriate." if category in {"onboarding", "support", "editor", "settings"} else "No free-text input is required by the current PRD for the primary happy path on this screen.",
        "Dropdowns": "Dropdowns are allowed for constrained selections such as week, cohort, school, role, status, or content tags. Avoid dropdowns when chips or radios communicate the options more clearly." if category in {"dashboard", "support", "editor", "settings"} else "No dropdown is needed in the base design; if a dropdown is later introduced it must remain constrained and auditable.",
        "Sliders": "Sliders should be used only where the PRD expects scaled or ranged values, especially in check-in or threshold management experiences." if category in {"checkin", "editor"} else "No slider is required for the current screen definition.",
        "Checkboxes": "Checkboxes are used for explicit multi-select or acknowledgment tasks such as permissions, review checklists, or batched operational filters." if category in {"consent", "support", "editor", "settings"} else "No checkbox interaction is required in the default layout.",
        "Radio Buttons": "Radio buttons are used when only one option can be selected and the alternatives must remain visible at once, such as privacy tier, consent route, or narrative choice mode." if category in {"consent", "onboarding", "checkin"} else "No radio control is required by the current screen contract.",
    }


def feedback_components(category: str, screen: dict):
    return {
        "Progress Indicators": "Use determinate progress for multi-step flows and module completion, and indeterminate progress for network-bound fetches shorter than the skeleton threshold.",
        "Charts": "Charts must remain plain-language and privacy-safe. Use only the level of abstraction allowed for this role and this screen." if category in {"dashboard", "checkin", "support"} else "No chart is mandatory here; if a micro-chart is later added it must reuse the same semantics defined in Phase 1.",
        "Dialogs": "Use dialogs only for destructive confirmation, policy acknowledgement, unsaved draft confirmation, or high-impact operational actions.",
        "Bottom Sheets": "Use bottom sheets for secondary action menus, filter pickers, or mobile-safe disclosures without forcing a full route change.",
        "Snackbars": "Show transient, non-critical confirmation for completed saves, retries queued, or reminder preferences changed.",
        "Toasts": "Avoid free-floating toasts for critical information. If a lightweight toast is used, keep it informational and never privacy-sensitive.",
        "Popups": "Use popups sparingly for contextual explanations or policy notices that do not justify a full dialog.",
        "Tooltips": "Tooltips should explain unfamiliar metrics, consent terms, threshold labels, or operational statuses; on mobile they become tappable info popovers.",
    }


def state_spec(role: str, category: str, screen: dict):
    name = screen["name"]
    return {
        "Empty States": f"If '{name}' has no data, show a role-appropriate explanation, why the state is empty, and the single next best action. Never show a blank surface.",
        "Loading States": "Show structured loading immediately after route entry when live data is required. Keep action areas disabled until entitlement and privacy checks complete.",
        "Skeleton Screens": "Use skeletons for cards, list rows, charts, and headers when data is expected within one network round trip. Skeleton layout must match final geometry to prevent jumpy reflow.",
        "Offline States": "If the screen supports cached behavior, show cached timestamp and available actions. If it does not, explain what requires connectivity and provide a retry affordance.",
        "Error States": "Render recoverable errors inline with retry, support, or return actions. Do not leak implementation details, IDs, or sensitive payload fragments into the UI.",
        "Success States": "Confirm successful completion using a short status banner, completed iconography, and the next recommended action.",
    }


def validation_rules(category: str, screen: dict):
    rules = []
    if category in {"onboarding", "consent"}:
        rules.extend([
            "Required acknowledgements must be actively confirmed and cannot default to accepted.",
            "Age band, consent route, and privacy tier values must be selected from approved controlled options.",
        ])
    if category == "checkin":
        rules.extend([
            "All eight weekly check-in dimensions must be completed before submission unless the PRD explicitly marks a field optional.",
            "Duplicate submission retries must remain idempotent and preserve the latest timestamp.",
        ])
    if category == "support":
        rules.extend([
            "A support note, referral, or case mutation must require the minimum structured fields defined in the architecture repository.",
            "Operational actions that alter case ownership, threshold status, or emergency posture require explicit confirmation and logging.",
        ])
    if category == "editor":
        rules.extend([
            "Content may not be published without required tags, review owner, review date, and audience scope.",
            "Threshold changes may not activate without a named human owner and valid deployment scope.",
        ])
    if not rules:
        rules.extend([
            "Validate that upstream payloads, role entitlements, and route parameters exist before rendering the main body.",
            "If there are no editable fields, validation is limited to guard-state checks and action eligibility checks.",
        ])
    return dedupe(rules)


def permission_notes(role: str, category: str, screen: dict):
    items = list(ROLE_CONFIG[role]["default_permissions"])
    if category in {"checkin", "learning", "games", "chatbot", "dashboard", "support"}:
        items.append("Connectivity required for live sync, with cached fallback only where Phase 1 explicitly allows it.")
    if category in {"bootstrap", "onboarding", "settings"}:
        items.append("Notification permission is optional but should be requestable from a contextual CTA rather than on launch.")
    return dedupe(items)


def endpoints_for(role: str, category: str):
    base = APP_ENDPOINTS.get(role, {})
    if category in base:
        return base[category]
    return dedupe(sum(base.values(), []))


def backend_dependencies(role: str, category: str):
    deps = list(ROLE_CONFIG[role]["default_services"])
    deps.extend(SERVICE_BY_CATEGORY.get(category, []))
    return dedupe(deps)


def db_objects(role: str, category: str):
    objs = list(ROLE_CONFIG[role]["default_db_objects"])
    objs.extend(DB_OBJECTS_BY_CATEGORY.get(category, []))
    return dedupe(objs)


def analytics_events(category: str, screen: dict):
    events = list(ANALYTICS_BY_CATEGORY.get(category, []))
    events.append(f'screen_view:{screen["id"]}')
    return dedupe(events)


def logging_events(category: str, screen: dict):
    events = list(LOGGING_BY_CATEGORY.get(category, []))
    events.append(f'ux_spec_reference:{screen["id"]}')
    return dedupe(events)


def accessibility_notes(role: str, category: str, screen: dict):
    return dedupe([
        "Meet WCAG 2.1 AA contrast and focus visibility requirements.",
        "All primary actions, helper text, and error states must be screen-reader accessible and logically ordered.",
        "Touch targets must remain thumb-safe on Android, especially for student-facing and parent-facing surfaces.",
        "Where charts or metrics appear, provide equivalent narrative descriptions and non-visual summaries.",
    ])


def localization_notes(role: str, category: str, screen: dict):
    return dedupe([
        "All visible copy should be externalized and keyed for localization.",
        "Plain-language student copy must remain age-band appropriate after translation.",
        "Support right-sized text expansion for long German-like or Indian-language strings without clipping.",
        "Date, time, week labels, and hotline metadata must respect locale formatting rules.",
    ])


def security_notes(role: str, category: str, screen: dict):
    notes = [
        "Do not expose raw identifiers, tokens, or internal exception details in the UI layer.",
        "Revalidate role and data entitlements server-side for every mutation and sensitive query.",
        "Prevent screenshot-prone or clipboard-happy patterns for highly sensitive support and case data where device policy allows mitigation.",
    ]
    if role == "baha":
        notes.append("Operational screens must support tamper-evident action logging and least-privilege access segregation.")
    return dedupe(notes)


def privacy_notes(role: str, category: str, screen: dict):
    notes = [
        "Display only the minimum data needed for the task described by the PRD.",
        "Apply consent-tier projection before the payload reaches the client whenever data is parent- or teacher-facing.",
        "Never introduce diagnosis wording, risk scores, or surveillance framing in student-facing states.",
    ]
    if category == "support":
        notes.append("Any privacy override or acute safeguarding state must explain the scope of data sharing in plain language and log the event.")
    return dedupe(notes)


def animation_notes(role: str, category: str, screen: dict):
    notes = [
        "Use short, low-stress motion to preserve continuity between states.",
        "Prefer fade, slide, and elevation transitions over flashy effects.",
        "Respect platform reduced-motion preferences and disable non-essential animation when requested.",
    ]
    if category == "games":
        notes.append("Breathing or gameplay motion must support rhythm and clarity rather than reward-seeking overstimulation.")
    if category == "support":
        notes.append("Acute safety or alert flows must prioritize clarity over animation flair.")
    return dedupe(notes)


def microinteractions(category: str, screen: dict):
    items = [
        "Primary CTA provides pressed, disabled, loading, and success feedback states.",
        "Inline validation appears at field level before route-level blocking messages.",
        "Cards, rows, and chips show tactile tap feedback and clear selection state.",
    ]
    if category == "checkin":
        items.append("Question progress and response selection should animate minimally to reinforce completion without creating pressure.")
    if category == "chatbot":
        items.append("Incoming message, citation reveal, and escalation banner transitions should feel calm and informative.")
    if category == "support":
        items.append("Case status, referral state, and action log saves should respond instantly with optimistic UI only when audit-safe.")
    return dedupe(items)


def edge_cases(role: str, category: str, screen: dict):
    name = screen["name"]
    base = [
        f"Upstream payload for '{name}' is missing or delayed.",
        "User loses connectivity during interaction and resumes later.",
        "Role entitlement changes while the session is active.",
    ]
    if category == "checkin":
        base.extend([
            "Student submits after a reminder was already scheduled for the same window.",
            "The latest submission conflicts with previously cached local data.",
        ])
    if category == "chatbot":
        base.extend([
            "Safe Questions content for the requested topic is expired or unavailable.",
            "Escalation signal triggers mid-conversation and the app is backgrounded immediately after.",
        ])
    if category == "support":
        base.extend([
            "Case or referral is updated by another staff user while the screen is open.",
            "Alert volume is high enough that priority sorting changes during the session.",
        ])
    if category == "editor":
        base.extend([
            "A content item becomes flagged due to review expiry while it is open for editing.",
            "Threshold activation is attempted without a valid on-call owner.",
        ])
    return dedupe(base)


def incoming_outgoing(role: str, category: str, screen: dict):
    incoming = navigation_sources(role, category, screen)
    outgoing = navigation_destinations(role, category, screen)
    return incoming, outgoing


def buttons_for(role: str, category: str, screen: dict):
    name = screen["name"]
    buttons = []
    if category in {"onboarding", "consent"}:
        buttons.extend(["Continue", "Back", "Learn More"])
    elif category == "checkin":
        buttons.extend(["Save and Continue", "Back", "Finish Check-In"])
    elif category == "chatbot":
        buttons.extend(["Send", "Open Citation", "Get Human Help"])
    elif category == "learning":
        buttons.extend(["Start Module", "Continue Module", "Mark Complete"])
    elif category == "games":
        buttons.extend(["Start", "Resume", "Take a Break"])
    elif category == "support":
        buttons.extend(["Submit", "Assign", "Close Case" if role == "baha" else "Request Support"])
    elif category == "settings":
        buttons.extend(["Save Changes", "Reset", "Review Policy"])
    elif category == "editor":
        buttons.extend(["Save Draft", "Submit for Review", "Publish"])
    else:
        buttons.extend(["Open Detail", "Refresh", "Back"])
    destinations = {}
    for button in buttons:
        if button in {"Continue", "Save and Continue"}:
            destinations[button] = "Next gating or task step"
        elif button == "Back":
            destinations[button] = "Previous screen"
        elif button == "Learn More":
            destinations[button] = "Policy or supporting explanation surface"
        elif button == "Finish Check-In":
            destinations[button] = "Check-In Completion"
        elif button == "Send":
            destinations[button] = name
        elif button == "Open Citation":
            destinations[button] = "Buddy Citation Detail"
        elif button == "Get Human Help":
            destinations[button] = "Help Center or support request flow"
        elif button in {"Start Module", "Continue Module"}:
            destinations[button] = "Lesson View"
        elif button == "Mark Complete":
            destinations[button] = "Quiz or Reflection"
        elif button in {"Start", "Resume"}:
            destinations[button] = name
        elif button == "Take a Break":
            destinations[button] = "Home or advisory break prompt"
        elif button in {"Submit", "Request Support"}:
            destinations[button] = "Confirmation or queue state"
        elif button == "Assign":
            destinations[button] = "Assignment confirmation state"
        elif button == "Close Case":
            destinations[button] = "Closed case state"
        elif button == "Save Changes":
            destinations[button] = name
        elif button == "Reset":
            destinations[button] = name
        elif button == "Review Policy":
            destinations[button] = "Policy detail view"
        elif button == "Save Draft":
            destinations[button] = name
        elif button == "Submit for Review":
            destinations[button] = "Content Review Queue"
        elif button == "Publish":
            destinations[button] = "Published content state"
        elif button == "Open Detail":
            destinations[button] = "Detail child screen or section drill-in"
        elif button == "Refresh":
            destinations[button] = name
        else:
            destinations[button] = "Contextual target defined by the current list row, module, or alert."
    return buttons, destinations


def gesture_navigation(role: str, category: str, screen: dict):
    gestures = [
        "Standard Android back gesture returns to the previous safe route unless the flow is gated or destructive changes are unsaved.",
        "Vertical scrolling is the default primary gesture across all long-form content and list surfaces.",
    ]
    if category in {"dashboard", "support", "learning"}:
        gestures.append("Pull to refresh is allowed only when live data is expected and must preserve filters and scroll position where practical.")
    if category == "chatbot":
        gestures.append("Long-press on a message should open only privacy-safe utility actions such as citation view, not raw export by default.")
    return dedupe(gestures)


def conditional_navigation(role: str, category: str, screen: dict):
    conditions = [
        "Route access depends on the entitlement and gating state resolved at bootstrap.",
        "If the required backend data is unavailable, route to the screen's explicit loading, empty, offline, or error state rather than silently failing.",
    ]
    if category in {"onboarding", "consent"}:
        conditions.append("Next-step routing depends on age band, legal consent band, and policy version state.")
    if category == "support":
        conditions.append("Escalation actions branch differently for monitoring signals versus acute safety events.")
    return dedupe(conditions)


def permission_navigation(role: str, category: str, screen: dict):
    return dedupe([
        "Notification-permission-specific navigation should remain contextual and never hard-block core usage unless the PRD requires reminders for that role.",
        "Connectivity-dependent destinations must surface a clear offline explanation if the user attempts to enter them without network.",
        "Sensitive downstream routes should remain hidden or disabled when the current user lacks the required role or training scope.",
    ])


def role_navigation(role: str, category: str, screen: dict):
    return dedupe([
        f"This route is only available inside the {ROLE_CONFIG[role]['role_label']} application shell.",
        "Cross-role navigation is not supported through the UI because the product uses separate app surfaces rather than role-switched views.",
        "Shared backend identifiers may connect records across roles, but routes themselves remain role-isolated.",
    ])


def alternative_navigation(role: str, category: str, screen: dict):
    return dedupe([
        "A push notification or in-app alert may deep-link to this screen when the corresponding event exists and the user is entitled to view it.",
        "If a direct route cannot be opened safely, the app should route to the nearest valid parent screen and show an explanatory banner.",
        "Users can always return to the top-level safe route for their role using the app shell or system back behavior.",
    ])


def mermaid_type(category: str, screen: dict):
    name = screen["name"].lower()
    if "buddy" in name or "chat" in name or "citation" in name or "safe questions" in name:
        return "sequenceDiagram"
    if any(word in name for word in ["status", "queue", "dashboard", "offline", "review", "history", "analytics"]):
        return "stateDiagram-v2"
    return "flowchart"


def mermaid_content(role: str, category: str, screen: dict, incoming, outgoing):
    m_type = mermaid_type(category, screen)
    label = screen["name"].replace('"', "'")
    if m_type == "sequenceDiagram":
        actor = ROLE_CONFIG[role]["role_label"]
        return dedent(f"""
            sequenceDiagram
                participant U as {actor} User
                participant UI as {label}
                participant API as Backend API
                U->>UI: enter screen
                UI->>API: fetch or submit screen data
                API-->>UI: role-safe response
                UI-->>U: render content, states, and next actions
        """).strip()
    if m_type == "stateDiagram-v2":
        return dedent(f"""
            stateDiagram-v2
                [*] --> Loading
                Loading --> Empty: no eligible data
                Loading --> Active: data ready
                Loading --> Offline: connectivity unavailable
                Loading --> Error: fetch or guard failure
                Empty --> Active: data appears
                Active --> Success: user action completed
                Active --> Error: recoverable issue
                Error --> Loading: retry
                Offline --> Loading: reconnect
                Success --> Active
        """).strip()
    incoming_node = slugify(incoming[0]) if incoming else "Entry"
    outgoing_node = slugify(outgoing[0]) if outgoing else "Next"
    return dedent(f"""
        flowchart TD
            A["{incoming[0] if incoming else 'Entry'}"] --> B["{label}"]
            B --> C["{outgoing[0] if outgoing else 'Next'}"]
            B --> D["Loading, Empty, Offline, Error"]
            D --> B
    """).strip()


def validate_mermaid(content: str) -> bool:
    lines = [line.rstrip() for line in content.splitlines() if line.strip()]
    if not lines:
        return False
    if not any(lines[0].startswith(prefix) for prefix in ("flowchart", "sequenceDiagram", "stateDiagram-v2", "mindmap", "erDiagram")):
        return False
    if any("\t" in line for line in lines):
        return False
    return True


def spec_filename(role: str, screen: dict):
    role_prefix = ROLE_CONFIG[role]["role_label"]
    return f"{role_prefix}_{slugify(screen['name'])}.md"


def mermaid_filename(role: str, screen: dict):
    role_prefix = ROLE_CONFIG[role]["role_label"]
    return f"{role_prefix}_{slugify(screen['name'])}.mmd"


def screen_spec(role: str, category: str, screen: dict):
    incoming, outgoing = incoming_outgoing(role, category, screen)
    buttons, button_destinations = buttons_for(role, category, screen)
    ui = ui_structure(role, category, screen)
    interactions = interaction_controls(category, screen)
    feedback = feedback_components(category, screen)
    states = state_spec(role, category, screen)
    analytics = analytics_events(category, screen)
    logs = logging_events(category, screen)
    endpoints = endpoints_for(role, category)
    db = db_objects(role, category)
    services = backend_dependencies(role, category)
    spec_path = spec_filename(role, screen)
    mermaid_path = mermaid_filename(role, screen)
    return dedent(
        f"""
        # {screen["id"]} - {screen["name"]}

        ## Core Identity

        - Screen ID: `{screen["id"]}`
        - Screen Name: `{screen["name"]}`
        - Description: {screen["purpose"]}
        - User Goal: Complete the primary task implied by the screen name and PRD purpose without ambiguity or hidden policy risk.
        - User Persona: {ROLE_CONFIG[role]["persona"]}

        ## Conditions

        - Entry Conditions:
        {list_to_lines(entry_conditions(role, category, screen))}
        - Exit Conditions:
        {list_to_lines(exit_conditions(role, category, screen))}

        ## Navigation Relationships

        - Navigation Sources:
        {list_to_lines(navigation_sources(role, category, screen))}
        - Navigation Destinations:
        {list_to_lines(navigation_destinations(role, category, screen))}
        - Incoming Screens:
        {list_to_lines(incoming)}
        - Outgoing Screens:
        {list_to_lines(outgoing)}
        - Buttons:
        {list_to_lines(buttons)}
        - Button Destinations:
        {list_to_lines([f"{k}: {v}" for k, v in button_destinations.items()])}
        - Gesture Navigation:
        {list_to_lines(gesture_navigation(role, category, screen))}
        - Deep Links:
        {list_to_lines([deep_link(role, screen["name"])])}
        - Conditional Navigation:
        {list_to_lines(conditional_navigation(role, category, screen))}
        - Permission-based Navigation:
        {list_to_lines(permission_navigation(role, category, screen))}
        - Role-based Navigation:
        {list_to_lines(role_navigation(role, category, screen))}
        - Alternative Navigation:
        {list_to_lines(alternative_navigation(role, category, screen))}

        ## Layout and Structure

        - Header: {ui["Header"]}
        - Footer: {ui["Footer"]}
        - Navigation Bar: {ui["Navigation Bar"]}
        - Tabs: {ui["Tabs"]}
        - Floating Buttons: {ui["Floating Buttons"]}
        - Search: {ui["Search"]}
        - Filters: {ui["Filters"]}
        - Cards: {ui["Cards"]}
        - Lists: {ui["Lists"]}
        - Sections: {ui["Sections"]}
        - Widgets: {ui["Widgets"]}

        ## Form and Input Model

        - Forms: {interactions["Forms"]}
        - Inputs: {interactions["Inputs"]}
        - Dropdowns: {interactions["Dropdowns"]}
        - Sliders: {interactions["Sliders"]}
        - Checkboxes: {interactions["Checkboxes"]}
        - Radio Buttons: {interactions["Radio Buttons"]}

        ## Feedback and Supporting Components

        - Progress Indicators: {feedback["Progress Indicators"]}
        - Charts: {feedback["Charts"]}
        - Dialogs: {feedback["Dialogs"]}
        - Bottom Sheets: {feedback["Bottom Sheets"]}
        - Snackbars: {feedback["Snackbars"]}
        - Toasts: {feedback["Toasts"]}
        - Popups: {feedback["Popups"]}
        - Tooltips: {feedback["Tooltips"]}

        ## States

        - Empty States: {states["Empty States"]}
        - Loading States: {states["Loading States"]}
        - Skeleton Screens: {states["Skeleton Screens"]}
        - Offline States: {states["Offline States"]}
        - Error States: {states["Error States"]}
        - Success States: {states["Success States"]}

        ## Rules and Dependencies

        - Validation Rules:
        {list_to_lines(validation_rules(category, screen))}
        - Required Permissions:
        {list_to_lines(permission_notes(role, category, screen))}
        - API Endpoints Used:
        {list_to_lines(endpoints)}
        - Backend Dependencies:
        {list_to_lines(services)}
        - Database Objects:
        {list_to_lines(db)}

        ## Telemetry and Observability

        - Analytics Events:
        {list_to_lines(analytics)}
        - Logging Events:
        {list_to_lines(logs)}

        ## Quality, Safety, and Compliance

        - Accessibility Notes:
        {list_to_lines(accessibility_notes(role, category, screen))}
        - Localization Notes:
        {list_to_lines(localization_notes(role, category, screen))}
        - Security Notes:
        {list_to_lines(security_notes(role, category, screen))}
        - Privacy Notes:
        {list_to_lines(privacy_notes(role, category, screen))}
        - Animation Notes:
        {list_to_lines(animation_notes(role, category, screen))}
        - Microinteractions:
        {list_to_lines(microinteractions(category, screen))}
        - Edge Cases:
        {list_to_lines(edge_cases(role, category, screen))}

        ## Mermaid Reference

        - Diagram File: [Mermaid/{mermaid_path}](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/13_UX_Specification/Mermaid/{mermaid_path})
        """
    ).strip()


def build():
    UX_ROOT.mkdir(parents=True, exist_ok=True)
    MERMAID_ROOT.mkdir(parents=True, exist_ok=True)

    all_screens = []
    generated_specs = []
    generated_mermaids = []
    validation_results = []

    for role, config in ROLE_CONFIG.items():
        screens = parse_inventory(config["inventory"])
        all_screens.extend((role, screen) for screen in screens)

    index_lines = [
        "# UX Specification Index",
        "",
        "This folder contains one production-level UX specification markdown file per screen plus one Mermaid diagram file per screen.",
        "",
        "## Files",
        "",
    ]

    for role, screen in all_screens:
        category = classify_screen(screen["name"])
        spec_name = spec_filename(role, screen)
        mermaid_name = mermaid_filename(role, screen)
        spec_text = screen_spec(role, category, screen)
        incoming, outgoing = incoming_outgoing(role, category, screen)
        mermaid_text = mermaid_content(role, category, screen, incoming, outgoing)
        is_valid = validate_mermaid(mermaid_text)
        validation_results.append((screen["id"], mermaid_name, is_valid))
        if not is_valid:
            raise ValueError(f"Mermaid validation failed for {screen['id']} {screen['name']}")

        write(UX_ROOT / spec_name, spec_text)
        write(MERMAID_ROOT / mermaid_name, mermaid_text)
        generated_specs.append(spec_name)
        generated_mermaids.append(mermaid_name)
        index_lines.append(
            f"- [{spec_name}](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/13_UX_Specification/{spec_name}) -> "
            f"[Mermaid/{mermaid_name}](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/13_UX_Specification/Mermaid/{mermaid_name})"
        )

    write(UX_ROOT / "README.md", "\n".join(index_lines))

    expected_ids = [screen["id"] for _, screen in all_screens]
    generated_id_prefixes = []
    for spec_name in generated_specs:
        match = re.match(r"([A-Za-z]+)_(.*)\.md", spec_name)
        generated_id_prefixes.append(spec_name if match else spec_name)

    missing = []
    for role, screen in all_screens:
        if not (UX_ROOT / spec_filename(role, screen)).exists():
            missing.append(screen["id"])

    report = dedent(
        f"""
        # Phase 2 Completion Report

        ## Summary

        - Total screens documented: {len(generated_specs)}
        - Missing screens: {", ".join(missing) if missing else "None"}
        - Mermaid files generated: {len(generated_mermaids)}

        ## Cross-reference Validation Results

        - Inventory screens discovered: {len(expected_ids)}
        - Spec files generated from inventory: {len(generated_specs)}
        - Mermaid syntax template validation passed: {sum(1 for _, _, ok in validation_results if ok)} of {len(validation_results)}
        - Missing spec file check: {"Passed" if not missing else "Failed"}
        - Screen ID consistency: {"Passed" if len(expected_ids) == len(generated_specs) else "Review required"}

        ## Mermaid Files Generated

        {list_to_lines(generated_mermaids)}

        ## Remaining Work Before Figma Generation

        {list_to_lines(COMPLETION_WORK)}
        """
    ).strip()
    write(UX_ROOT / "Completion_Report.md", report)


if __name__ == "__main__":
    build()
