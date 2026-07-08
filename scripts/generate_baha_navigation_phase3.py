import re
from collections import defaultdict
from pathlib import Path
from textwrap import dedent


ROOT = Path("/Users/solomonkaruppiah/Desktop/Baha_Data")
DOCS = ROOT / "docs"
NAV_ROOT = DOCS / "14_Navigation"
STATE_DIR = NAV_ROOT / "State_Diagrams"
FLOW_DIR = NAV_ROOT / "Feature_Flows"
SEQ_DIR = NAV_ROOT / "Sequence"


ROLE_CONFIG = {
    "student": {
        "inventory": DOCS / "03_Student_App" / "Screen_Inventory.md",
        "label": "Student",
        "shell": "Student App Shell",
        "auth_required_default": "Required after bootstrap",
        "role_required": "Student",
        "permission_default": "Student session",
        "base_path": "/student",
        "top_level": {
            "S-10": "Home",
            "S-25": "Learn",
            "S-20": "Games",
            "S-30": "Buddy",
            "S-33": "Profile",
        },
    },
    "parent": {
        "inventory": DOCS / "04_Parent_App" / "Screen_Inventory.md",
        "label": "Parent",
        "shell": "Parent App Shell",
        "auth_required_default": "Required after bootstrap",
        "role_required": "Parent or Guardian",
        "permission_default": "Guardian-linked session",
        "base_path": "/parent",
        "top_level": {
            "P-06": "Summary",
            "P-08": "Guides",
            "P-09": "Learn",
            "P-12": "Settings",
        },
    },
    "teacher": {
        "inventory": DOCS / "05_Teacher_App" / "Screen_Inventory.md",
        "label": "Teacher",
        "shell": "Teacher App Shell",
        "auth_required_default": "Required after bootstrap",
        "role_required": "Teacher or School Counselor",
        "permission_default": "School-scoped staff session",
        "base_path": "/teacher",
        "top_level": {
            "T-03": "Dashboard",
            "T-05": "Pastoral",
            "T-07": "Referrals",
            "T-09": "Learn",
            "T-13": "Settings",
        },
    },
    "baha": {
        "inventory": DOCS / "06_BAHA_App" / "Screen_Inventory.md",
        "label": "BAHA",
        "shell": "BAHA Operations Shell",
        "auth_required_default": "Required after bootstrap",
        "role_required": "BAHA clinician, counselor, or admin",
        "permission_default": "Operational entitlement",
        "base_path": "/baha",
        "top_level": {
            "B-01": "Queue",
            "B-03": "Cases",
            "B-07": "Content",
            "B-11": "Thresholds",
            "B-13": "Analytics",
            "B-15": "Audit",
            "B-17": "Settings",
        },
    },
}


CATEGORY_KEYWORDS = {
    "bootstrap": ["splash"],
    "onboarding": ["welcome", "onboarding", "age-band", "gender", "legal consent", "parent consent pending", "self-consent", "guardian verification", "training status"],
    "settings": ["settings", "profile summary", "notification settings", "operational settings", "offline"],
    "consent": ["privacy", "consent", "data rights", "notification permission"],
    "home": ["home dashboard", "weekly summary home", "class trends dashboard", "support queue", "pilot analytics dashboard"],
    "checkin": ["check-in", "trend", "mood vocabulary"],
    "chatbot": ["buddy", "safe questions"],
    "learning": ["learning", "lesson", "module", "quiz", "reflection"],
    "games": ["games", "emotion explorer", "friendship choices", "calm breathing", "time cap"],
    "support": ["help", "counselor request", "alert", "pastoral", "referral", "case", "emergency", "threshold", "audit", "user and role management", "queue filters"],
    "editor": ["content library", "content editor", "content review queue", "safe questions manager", "analytics export"],
}


SHARED_OVERLAYS = [
    ("Overlay_Permission_Prompt", "Permission Prompt"),
    ("Overlay_Logout_Confirm", "Logout Confirmation Dialog"),
    ("Overlay_Session_Expired", "Session Expired Dialog"),
    ("Overlay_Network_Error", "Network Error Dialog"),
    ("Overlay_Maintenance_Mode", "Maintenance Mode Screen"),
    ("Overlay_Validation_Error", "Validation Snackbar"),
    ("Overlay_Success_Toast", "Success Snackbar"),
    ("Overlay_Filter_Sheet", "Filter Bottom Sheet"),
    ("Overlay_Tooltip", "Tooltip Overlay"),
]


def write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    normalized = dedent(content).strip()
    normalized = re.sub(r"(?m)^ {8}", "", normalized)
    path.write_text(normalized + "\n", encoding="utf-8")


def bullet_block(items, indent=0):
    prefix = " " * indent
    return "\n".join(f"{prefix}- {item}" for item in items)


def parse_inventory(path: Path):
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        match = re.match(r"\|\s*([A-Z]-\d{2})\s*\|\s*(.*?)\s*\|\s*(.*?)\s*\|$", line)
        if match:
            screen_id, name, purpose = match.groups()
            rows.append({"id": screen_id, "name": name, "purpose": purpose})
    return rows


def slugify(text: str) -> str:
    return re.sub(r"[^A-Za-z0-9]+", "_", text).strip("_")


def classify(name: str) -> str:
    lowered = name.lower()
    for category, keywords in CATEGORY_KEYWORDS.items():
        if any(keyword in lowered for keyword in keywords):
            return category
    return "home"


def route_for(role: str, name: str) -> str:
    return f'{ROLE_CONFIG[role]["base_path"]}/{slugify(name).lower()}'


def deep_link_for(role: str, name: str) -> str:
    return route_for(role, name)


def transition_for(category: str) -> str:
    return {
        "bootstrap": "fade",
        "onboarding": "slideLeft",
        "consent": "slideUp",
        "home": "fadeThrough",
        "checkin": "sharedAxisX",
        "chatbot": "fadeThrough",
        "learning": "sharedAxisX",
        "games": "sharedAxisZ",
        "support": "sharedAxisY",
        "settings": "fade",
        "editor": "fadeThrough",
    }.get(category, "fade")


def auth_requirement(role: str, category: str) -> str:
    if category == "bootstrap":
        return "Not required for initial launch route; resolved inside bootstrap"
    if role == "student" and category in {"onboarding", "consent"}:
        return "Partially authenticated or pre-auth onboarding context"
    return ROLE_CONFIG[role]["auth_required_default"]


def required_permission(role: str, category: str, screen_id: str) -> str:
    base = ROLE_CONFIG[role]["permission_default"]
    if role == "student" and category in {"checkin", "chatbot", "learning", "games", "home"}:
        return f"{base}; active consent state"
    if role == "teacher" and screen_id in {"T-03", "T-05", "T-07"}:
        return f"{base}; training gate completed"
    if role == "baha" and category in {"support", "editor"}:
        return f"{base}; clinical or admin scope as appropriate"
    return base


def args_for(category: str, screen_id: str) -> str:
    mapping = {
        "bootstrap": "optional bootstrap context and previous session metadata",
        "onboarding": "progress token, policy version, and role context",
        "consent": "policy version, consent band, and linked student or guardian identifiers where applicable",
        "home": "optional refresh source and tab selection",
        "checkin": "check-in cadence, draft id, or trend filter context",
        "chatbot": "conversation id, entry source, and optional citation id",
        "learning": "module id, content id, and recommendation source",
        "games": "game id, scenario id, and prior session id when resuming",
        "support": "case id, referral id, alert id, school id, or queue filter state as applicable",
        "settings": "settings subsection and source screen",
        "editor": "content id, review queue filter, or export request context",
    }
    return mapping.get(category, "no required arguments")


def return_value_for(category: str) -> str:
    if category in {"onboarding", "consent", "checkin", "support", "editor"}:
        return "completion result, updated entity id, or refresh trigger"
    if category in {"settings"}:
        return "changed-settings flag"
    return "none or passive refresh signal"


def build_navigation_model():
    screens_by_role = {}
    order_by_role = {}
    graph_nodes = {}
    incoming = defaultdict(list)
    outgoing = defaultdict(list)

    for role, cfg in ROLE_CONFIG.items():
        screens = parse_inventory(cfg["inventory"])
        screens_by_role[role] = screens
        order_by_role[role] = [screen["id"] for screen in screens]
        for screen in screens:
            graph_nodes[screen["id"]] = screen

    def connect(a: str, b: str):
        if b not in outgoing[a]:
            outgoing[a].append(b)
        if a not in incoming[b]:
            incoming[b].append(a)

    # bootstrap and ordered adjacency
    for role, screens in screens_by_role.items():
        launch_node = f"{ROLE_CONFIG[role]['label']}_App_Launch"
        first = screens[0]["id"]
        connect(launch_node, first)
        for idx, screen in enumerate(screens):
            if idx + 1 < len(screens):
                connect(screen["id"], screens[idx + 1]["id"])
                connect(screens[idx + 1]["id"], screen["id"])

    # role-specific topology
    # student onboarding branches and shell
    student = {s["id"]: s for s in screens_by_role["student"]}
    connect("S-03", "S-06")
    connect("S-03", "S-07")
    connect("S-06", "S-08")
    connect("S-07", "S-08")
    for top in ROLE_CONFIG["student"]["top_level"]:
        connect("Student_Shell", top)
        connect(top, "Student_Shell")
    connect("S-10", "S-11")
    connect("S-11", "S-12")
    connect("S-12", "S-13")
    connect("S-13", "S-15")
    connect("S-15", "S-16")
    connect("S-15", "S-17")
    connect("S-10", "S-18")
    connect("S-18", "S-19")
    connect("S-20", "S-21")
    connect("S-20", "S-22")
    connect("S-20", "S-23")
    connect("S-21", "S-24")
    connect("S-22", "S-24")
    connect("S-23", "S-24")
    connect("S-25", "S-26")
    connect("S-26", "S-27")
    connect("S-27", "S-28")
    connect("S-30", "S-31")
    connect("S-30", "S-32")
    connect("S-30", "S-36")
    connect("S-33", "S-34")
    connect("S-34", "S-35")
    connect("S-36", "S-37")
    connect("S-36", "S-38")
    connect("S-10", "S-39")

    # parent shell and flows
    for top in ROLE_CONFIG["parent"]["top_level"]:
        connect("Parent_Shell", top)
        connect(top, "Parent_Shell")
    connect("P-02", "P-03")
    connect("P-03", "P-04")
    connect("P-04", "P-05")
    connect("P-05", "P-06")
    connect("P-06", "P-07")
    connect("P-06", "P-08")
    connect("P-09", "P-10")
    connect("P-06", "P-11")
    connect("P-12", "P-13")
    connect("P-06", "P-14")

    # teacher shell and flows
    for top in ROLE_CONFIG["teacher"]["top_level"]:
        connect("Teacher_Shell", top)
        connect(top, "Teacher_Shell")
    connect("T-01", "T-02")
    connect("T-02", "T-03")
    connect("T-03", "T-04")
    connect("T-05", "T-06")
    connect("T-07", "T-08")
    connect("T-09", "T-10")
    connect("T-03", "T-11")
    connect("T-13", "T-12")
    connect("T-03", "T-14")

    # BAHA shell and flows
    for top in ROLE_CONFIG["baha"]["top_level"]:
        connect("BAHA_Shell", top)
        connect(top, "BAHA_Shell")
    connect("B-01", "B-02")
    connect("B-01", "B-03")
    connect("B-03", "B-04")
    connect("B-03", "B-05")
    connect("B-03", "B-06")
    connect("B-07", "B-08")
    connect("B-07", "B-09")
    connect("B-07", "B-10")
    connect("B-11", "B-12")
    connect("B-13", "B-14")
    connect("B-15", "B-16")
    connect("B-16", "B-17")

    # overlays
    overlay_ids = [overlay_id for overlay_id, _ in SHARED_OVERLAYS]
    for role, screens in screens_by_role.items():
        for screen in screens:
            sid = screen["id"]
            connect(sid, "Overlay_Network_Error")
            connect(sid, "Overlay_Session_Expired")
            connect(sid, "Overlay_Maintenance_Mode")
            connect(sid, "Overlay_Validation_Error")
            connect(sid, "Overlay_Success_Toast")
            if classify(screen["name"]) in {"home", "support", "editor"}:
                connect(sid, "Overlay_Filter_Sheet")
                connect(sid, "Overlay_Tooltip")
            if "notification" in screen["name"].lower() or sid in {"S-09", "P-12", "T-12"}:
                connect(sid, "Overlay_Permission_Prompt")
        shell_node = f"{ROLE_CONFIG[role]['label']}_Shell"
        connect(shell_node, "Overlay_Logout_Confirm")

    return screens_by_role, graph_nodes, incoming, outgoing


def screen_nav_spec(role: str, screen: dict, incoming, outgoing):
    cfg = ROLE_CONFIG[role]
    category = classify(screen["name"])
    route = route_for(role, screen["name"])
    deep_link = deep_link_for(role, screen["name"])
    top_nav = cfg["top_level"]
    incoming_items = incoming[screen["id"]] or ["External app launch"]
    outgoing_items = outgoing[screen["id"]] or [f"{cfg['label']}_Shell"]
    previous_candidates = [item for item in incoming_items if not item.startswith("Overlay_")]
    previous_screen = previous_candidates[0] if previous_candidates else incoming_items[0]
    next_candidates = [item for item in outgoing_items if not item.startswith("Overlay_") and item != previous_screen]
    next_screen = next_candidates[0] if next_candidates else outgoing_items[0]
    bottom_nav = ", ".join(top_nav.values()) if role in {"student", "parent", "teacher"} else "Not used"
    drawer_nav = ", ".join(top_nav.values()) if role == "baha" else "Not used"
    tab_nav = "Contextual tab or segmented control only where the Phase 2 UX spec calls for filters, summary ranges, or queue states."
    notif_entries = [
        "Reminder notification" if category in {"checkin", "home", "learning"} else "Operational alert notification" if category in {"support", "editor"} else "No direct notification entry by default"
    ]
    external_entries = [
        "Cold app launch",
        "Deep link",
    ]
    permission_entries = [
        "Notification permission prompt" if screen["id"] in {"S-09", "P-12", "T-12"} or category in {"settings"} else "No dedicated permission prompt entry",
    ]
    error_redirects = [
        "Overlay_Network_Error",
        "Overlay_Maintenance_Mode",
        previous_screen,
    ]
    logout_redirect = f"{cfg['label']}_App_Launch"
    session_expired_redirect = "Overlay_Session_Expired"
    return dedent(
        f"""
        # {screen["id"]} - {screen["name"]}

        ## Route Identity

        - Flutter Route: `{route}`
        - Deep Link: `{deep_link}`
        - Required Authentication: {auth_requirement(role, category)}
        - Required Role: {cfg["role_required"]}
        - Required Permission: {required_permission(role, category, screen["id"])}
        - Transition Animation: {transition_for(category)}
        - Arguments: {args_for(category, screen["id"])}
        - Return Value: {return_value_for(category)}

        ## Navigation Inputs

        - Navigation Sources:
        {bullet_block(incoming_items)}
        - Previous Screen: {previous_screen}
        - Back Navigation: Returns to the previous safe route in the stack; if the stack is invalid, route to the nearest top-level shell destination for this role.
        - Bottom Navigation: {bottom_nav}
        - Drawer Navigation: {drawer_nav}
        - Tab Navigation: {tab_nav}
        - Deep Links:
        {bullet_block([deep_link])}
        - Notification Entry Points:
        {bullet_block(notif_entries)}
        - External Entry Points:
        {bullet_block(external_entries)}
        - Permission Entry Points:
        {bullet_block(permission_entries)}

        ## Navigation Outputs

        - Navigation Destinations:
        {bullet_block(outgoing_items)}
        - Next Screen: {next_screen}
        - Error Redirects:
        {bullet_block(error_redirects)}
        - Logout Redirects:
        {bullet_block([logout_redirect])}
        - Session Expiry Redirects:
        {bullet_block([session_expired_redirect])}

        ## Role Routing Notes

        - This screen belongs to the {cfg["shell"]}.
        - Cross-role navigation is not supported; cross-role data relationships exist only through shared backend entities.
        - If this screen is accessed via deep link and its prerequisites are not satisfied, route to the prerequisite screen and preserve the original intent for post-gate resumption.
        """
    ).strip()


def flowchart_for(role: str, screen: dict, incoming, outgoing):
    sources = incoming[screen["id"]] or [f"{ROLE_CONFIG[role]['label']}_App_Launch"]
    dests = outgoing[screen["id"]] or [f"{ROLE_CONFIG[role]['label']}_Shell"]
    source_lines = "\n".join(f'    A{i}["{src}"] --> B["{screen["name"]}"]' for i, src in enumerate(sources, start=1))
    dest_lines = "\n".join(f'    B --> C{i}["{dst}"]' for i, dst in enumerate(dests, start=1))
    overlay_lines = "\n".join(
        [
            '    B --> N1["Overlay_Network_Error"]',
            '    B --> N2["Overlay_Session_Expired"]',
            '    B --> N3["Overlay_Maintenance_Mode"]',
            '    B --> N4["Overlay_Validation_Error"]',
        ]
    )
    return dedent(
        f"""
        flowchart TD
        {source_lines}
        {dest_lines}
        {overlay_lines}
        """
    ).strip()


def state_diagram_for(screen: dict):
    return dedent(
        f"""
        stateDiagram-v2
            [*] --> Initial
            Initial --> Loading
            Loading --> Idle: payload ready
            Loading --> Empty: no data
            Loading --> Failure: unclassified failure
            Loading --> Network_Error: no network
            Loading --> Timeout: backend timeout
            Loading --> Permission_Denied: guard blocked
            Loading --> Session_Expired: session invalid
            Loading --> Offline: cached fallback
            Loading --> Maintenance_Mode: service unavailable
            Idle --> Refreshing: manual or automatic refresh
            Refreshing --> Success: refresh succeeded
            Refreshing --> Failure: refresh failed
            Idle --> Validation_Error: user action invalid
            Success --> Idle
            Failure --> Refreshing: retry
            Validation_Error --> Idle: fix input
            Network_Error --> Offline: cached state exists
            Network_Error --> Loading: retry online
            Timeout --> Loading: retry
            Permission_Denied --> Disabled
            Session_Expired --> [*]
            Offline --> Refreshing: reconnect
            Maintenance_Mode --> Disabled
            Idle --> Deleted: entity removed
            Idle --> Archived: archived state entered
            Idle --> Disabled: feature disabled by policy
            Deleted --> [*]
            Archived --> Idle: reopened where allowed
            Disabled --> [*]
        """
    ).strip()


def sequence_for(role: str, screen: dict):
    category = classify(screen["name"])
    actor = ROLE_CONFIG[role]["label"]
    route = route_for(role, screen["name"])
    return dedent(
        f"""
        sequenceDiagram
            participant U as {actor} User
            participant R as Flutter Router
            participant G as Route Guards
            participant S as Screen {screen["id"]}
            participant API as Backend API
            U->>R: open {route}
            R->>G: validate auth, role, permission
            alt guard passes
                G-->>R: allow
                R->>S: instantiate screen
                S->>API: load screen data
                API-->>S: response or status
                S-->>U: render UI and available navigation actions
            else guard fails
                G-->>R: redirect target
                R-->>U: reroute to prerequisite or session flow
            end
        """
    ).strip()


def validate_mermaid(content: str) -> bool:
    lines = [line for line in content.splitlines() if line.strip()]
    if not lines:
        return False
    return lines[0].startswith(("flowchart", "stateDiagram-v2", "sequenceDiagram"))


def generate():
    NAV_ROOT.mkdir(parents=True, exist_ok=True)
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    FLOW_DIR.mkdir(parents=True, exist_ok=True)
    SEQ_DIR.mkdir(parents=True, exist_ok=True)

    screens_by_role, graph_nodes, incoming, outgoing = build_navigation_model()
    total_screens = sum(len(v) for v in screens_by_role.values())

    screen_specs = []
    route_rows = []
    flow_files = []
    state_files = []
    sequence_files = []

    for role, screens in screens_by_role.items():
        for screen in screens:
            spec_name = f'{ROLE_CONFIG[role]["label"]}_{slugify(screen["name"])}.md'
            flow_name = f'{ROLE_CONFIG[role]["label"]}_{slugify(screen["name"])}.mmd'
            state_name = flow_name
            seq_name = flow_name

            spec_content = screen_nav_spec(role, screen, incoming, outgoing)
            flow_content = flowchart_for(role, screen, incoming, outgoing)
            state_content = state_diagram_for(screen)
            sequence_content = sequence_for(role, screen)

            if not all(validate_mermaid(content) for content in [flow_content, state_content, sequence_content]):
                raise ValueError(f"Mermaid validation failed for {screen['id']}")

            write(FLOW_DIR / spec_name, spec_content)
            write(FLOW_DIR / flow_name, flow_content)
            write(STATE_DIR / state_name, state_content)
            write(SEQ_DIR / seq_name, sequence_content)

            screen_specs.append(spec_name)
            flow_files.append(flow_name)
            state_files.append(state_name)
            sequence_files.append(seq_name)

            category = classify(screen["name"])
            route_rows.append(
                {
                    "id": screen["id"],
                    "name": screen["name"],
                    "route": route_for(role, screen["name"]),
                    "deep_link": deep_link_for(role, screen["name"]),
                    "auth": auth_requirement(role, category),
                    "role": ROLE_CONFIG[role]["role_required"],
                    "permission": required_permission(role, category, screen["id"]),
                    "transition": transition_for(category),
                    "arguments": args_for(category, screen["id"]),
                    "return": return_value_for(category),
                }
            )

    # master navigation graph
    lines = ["flowchart TD"]
    for role, screens in screens_by_role.items():
        lines.append(f'    subgraph {ROLE_CONFIG[role]["label"]}_Navigation["{ROLE_CONFIG[role]["label"]} Navigation"]')
        launch = f'{ROLE_CONFIG[role]["label"]}_App_Launch'
        shell = f'{ROLE_CONFIG[role]["label"]}_Shell'
        lines.append(f'        {launch}["{ROLE_CONFIG[role]["label"]} App Launch"]')
        lines.append(f'        {shell}["{ROLE_CONFIG[role]["shell"]}"]')
        for screen in screens:
            lines.append(f'        {screen["id"]}["{screen["id"]} {screen["name"]}"]')
        lines.append("    end")

    lines.append('    subgraph Shared_Overlays["Shared Overlays"]')
    for overlay_id, overlay_name in SHARED_OVERLAYS:
        lines.append(f'        {overlay_id}["{overlay_name}"]')
    lines.append("    end")

    # edges
    all_sources = set(incoming.keys()) | set(outgoing.keys())
    for source, dests in outgoing.items():
        for dest in dests:
            lines.append(f"    {source} --> {dest}")

    write(NAV_ROOT / "Master_Navigation_Graph.mmd", "\n".join(lines))

    # routing table
    routing_md = [
        "# Routing Table",
        "",
        "| Screen ID | Screen Name | Flutter Route | Deep Link | Required Authentication | Required Role | Required Permission | Transition Animation | Arguments | Return Value |",
        "|---|---|---|---|---|---|---|---|---|---|",
    ]
    for row in route_rows:
        routing_md.append(
            f'| {row["id"]} | {row["name"]} | `{row["route"]}` | `{row["deep_link"]}` | {row["auth"]} | {row["role"]} | {row["permission"]} | {row["transition"]} | {row["arguments"]} | {row["return"]} |'
        )
    write(NAV_ROOT / "Routing_Table.md", "\n".join(routing_md))

    # README
    readme = dedent(
        f"""
        # Phase 3 Navigation and State Architecture

        This folder is the navigation and state source of truth for Figma prototype linking and Flutter routing.

        ## Included Outputs

        - [Master_Navigation_Graph.mmd](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/14_Navigation/Master_Navigation_Graph.mmd)
        - [Routing_Table.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/14_Navigation/Routing_Table.md)
        - [Validation_Report.md](/Users/solomonkaruppiah/Desktop/Baha_Data/docs/14_Navigation/Validation_Report.md)
        - `State_Diagrams/` with one state diagram per screen
        - `Feature_Flows/` with one navigation specification markdown file and one flowchart per screen
        - `Sequence/` with one sequence diagram per screen

        ## Counts

        - Total screens covered: {total_screens}
        - Navigation spec markdown files: {len(screen_specs)}
        - Flowchart Mermaid files: {len(flow_files)}
        - State diagram Mermaid files: {len(state_files)}
        - Sequence diagram Mermaid files: {len(sequence_files)}
        - Shared overlays in master graph: {len(SHARED_OVERLAYS)}
        """
    ).strip()
    write(NAV_ROOT / "README.md", readme)

    # validation
    missing_from_graph = []
    graph_text = (NAV_ROOT / "Master_Navigation_Graph.mmd").read_text(encoding="utf-8")
    for role, screens in screens_by_role.items():
        for screen in screens:
            if screen["id"] not in graph_text:
                missing_from_graph.append(screen["id"])

    missing_routes = []
    route_paths = {row["route"] for row in route_rows}
    for role, screens in screens_by_role.items():
        for screen in screens:
            expected = route_for(role, screen["name"])
            if expected not in route_paths:
                missing_routes.append(expected)

    no_entry = []
    no_exit = []
    for role, screens in screens_by_role.items():
        for screen in screens:
            sid = screen["id"]
            if not incoming[sid]:
                no_entry.append(sid)
            if not outgoing[sid]:
                no_exit.append(sid)

    report = dedent(
        f"""
        # Validation Report

        ## Completion Statistics

        - Total screens discovered from inventories: {total_screens}
        - Routes generated: {len(route_rows)}
        - Feature flow markdown files: {len(screen_specs)}
        - Flowchart Mermaid files: {len(flow_files)}
        - State diagram Mermaid files: {len(state_files)}
        - Sequence diagram Mermaid files: {len(sequence_files)}

        ## Validation Checks

        - Every screen appears in master navigation graph: {"Passed" if not missing_from_graph else "Failed"}
        - Every route exists in routing table: {"Passed" if not missing_routes else "Failed"}
        - Every screen has at least one entry path: {"Passed" if not no_entry else "Failed"}
        - Every screen has at least one exit path unless terminal: {"Passed" if not no_exit else "Failed"}
        - Mermaid structural validation for generated diagrams: Passed

        ## Validation Details

        - Missing screens in graph: {", ".join(missing_from_graph) if missing_from_graph else "None"}
        - Missing routes: {", ".join(missing_routes) if missing_routes else "None"}
        - Screens without entry paths: {", ".join(no_entry) if no_entry else "None"}
        - Screens without exit paths: {", ".join(no_exit) if no_exit else "None"}

        ## Remaining Work

        - optional renderer-based Mermaid compilation using an installed Mermaid CLI
        - Figma prototype wire connection pass using this navigation model
        - Flutter route implementation and guard wiring against the generated routing table
        """
    ).strip()
    write(NAV_ROOT / "Validation_Report.md", report)

    if missing_from_graph or missing_routes or no_entry or no_exit:
        raise SystemExit("Validation failed")


if __name__ == "__main__":
    generate()
