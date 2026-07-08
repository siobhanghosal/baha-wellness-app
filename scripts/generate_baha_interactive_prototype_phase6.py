import json
import re
from pathlib import Path
from textwrap import dedent


ROOT = Path("/Users/solomonkaruppiah/Desktop/Baha_Data")
DOCS = ROOT / "docs"
APP_ROOT = ROOT


ROLE_ALIASES = {
    "Student": "student",
    "Parent": "parent",
    "Teacher": "teacher",
    "BAHA": "baha",
}


ROLE_SWITCHER = [
    {"id": "student", "label": "Student", "description": "Adolescent wellness companion"},
    {"id": "parent", "label": "Parent", "description": "Consent and weekly summaries"},
    {"id": "teacher", "label": "Teacher", "description": "Class trends and referrals"},
    {"id": "baha", "label": "Counselor / BAHA", "description": "Operations, queues, and analytics"},
]


TOP_NAV = {
    "student": [
        {"label": "Home", "route": "/student/home_dashboard"},
        {"label": "Buddy", "route": "/student/buddy_chat"},
        {"label": "Learn", "route": "/student/learning_home"},
        {"label": "Games", "route": "/student/games_hub"},
        {"label": "Profile", "route": "/student/profile_summary"},
    ],
    "parent": [
        {"label": "Summary", "route": "/parent/weekly_summary_home"},
        {"label": "Guides", "route": "/parent/conversation_guide_detail"},
        {"label": "Learn", "route": "/parent/parent_learning_home"},
        {"label": "Settings", "route": "/parent/notification_settings"},
    ],
    "teacher": [
        {"label": "Dashboard", "route": "/teacher/class_trends_dashboard"},
        {"label": "Referrals", "route": "/teacher/referral_queue"},
        {"label": "Learn", "route": "/teacher/teacher_learning_home"},
        {"label": "Settings", "route": "/teacher/settings"},
    ],
    "baha": [
        {"label": "Queue", "route": "/baha/support_queue"},
        {"label": "Content", "route": "/baha/content_library"},
        {"label": "Analytics", "route": "/baha/pilot_analytics_dashboard"},
        {"label": "Audit", "route": "/baha/audit_log"},
        {"label": "Settings", "route": "/baha/operational_settings"},
    ],
}


DEFAULT_ROUTES = {
    "student": "/student/splash",
    "parent": "/parent/splash",
    "teacher": "/teacher/splash",
    "baha": "/baha/splash",
    "counselor": "/baha/splash",
}


def write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(dedent(content).strip() + "\n", encoding="utf-8")


def parse_matrix():
    matrix = DOCS / "15_Design_System" / "05_Layouts" / "Screen_Composition_Matrix.md"
    rows = []
    for line in matrix.read_text(encoding="utf-8").splitlines():
        if not line.startswith("| "):
            continue
        cols = [c.strip() for c in line.split("|")[1:-1]]
        if cols[0] in {"Screen ID", "---"}:
            continue
        if len(cols) != 8:
            continue
        screen_id, name, role_label, route, pattern, layout, components, ux = cols
        role = ROLE_ALIASES[role_label]
        rows.append(
            {
                "id": screen_id,
                "name": name,
                "role": role,
                "roleLabel": role_label,
                "route": route.strip("`"),
                "pattern": pattern,
                "layout": layout,
                "components": [item.strip() for item in components.split(",")],
                "slug": route.strip("`").split("/")[-1],
            }
        )
    return rows


def parse_routing():
    table = DOCS / "14_Navigation" / "Routing_Table.md"
    route_map = {}
    for line in table.read_text(encoding="utf-8").splitlines():
        if not line.startswith("|"):
            continue
        cols = [c.strip() for c in line.strip().split("|")[1:-1]]
        if len(cols) != 10 or cols[0] == "Screen ID" or cols[0] == "---":
            continue
        route_map[cols[0]] = {
            "deepLink": cols[3].strip("`"),
            "transition": cols[7],
            "auth": cols[4],
            "permission": cols[6],
        }
    return route_map


def enrich_screens():
    matrix_rows = parse_matrix()
    routing = parse_routing()
    by_role = {}
    for row in matrix_rows:
        row.update(routing[row["id"]])
        by_role.setdefault(row["role"], []).append(row)
    for role, items in by_role.items():
        items.sort(key=lambda item: item["route"])
        ordered = sorted(items, key=lambda item: item["id"])
        for index, item in enumerate(ordered):
            item["previousRoute"] = ordered[index - 1]["route"] if index > 0 else DEFAULT_ROUTES[role]
            item["nextRoute"] = ordered[index + 1]["route"] if index + 1 < len(ordered) else ordered[0]["route"]
            item["isTopLevel"] = item["route"] in {nav["route"] for nav in TOP_NAV[role]}
    return matrix_rows


def build_mock_data():
    return {
        "shared": {
            "languages": ["en-IN", "hi-IN"],
            "ageGroups": ["9-13", "14-16", "17-19"],
            "themes": ["light", "dark"],
        },
        "student": {
            "profile": {
                "name": "Aarav N.",
                "ageGroup": "14-16",
                "streak": 6,
                "energy": "Steady",
                "consentTier": "Guardian summary enabled",
                "focusTheme": "Managing school stress",
            },
            "moodHistory": [
                {"week": "Week 1", "mood": 3, "sleep": 6, "stress": 4, "energy": 3},
                {"week": "Week 2", "mood": 4, "sleep": 7, "stress": 3, "energy": 4},
                {"week": "Week 3", "mood": 3, "sleep": 6, "stress": 5, "energy": 3},
                {"week": "Week 4", "mood": 4, "sleep": 7, "stress": 3, "energy": 4},
            ],
            "modules": [
                {"id": "mod-1", "title": "Stress and Study Balance", "duration": "8 min", "progress": 72, "format": "interactive lesson"},
                {"id": "mod-2", "title": "Sleep That Helps Your Mood", "duration": "6 min", "progress": 40, "format": "audio + reflection"},
                {"id": "mod-3", "title": "Asking for Help Early", "duration": "5 min", "progress": 0, "format": "cards + quiz"},
            ],
            "games": [
                {"id": "game-1", "title": "Emotion Explorer", "duration": "4 min", "status": "Ready"},
                {"id": "game-2", "title": "Friendship Choices", "duration": "5 min", "status": "Resume"},
                {"id": "game-3", "title": "Calm Breathing", "duration": "3 min", "status": "Quick start"},
            ],
            "chat": [
                {"id": "m1", "author": "buddy", "text": "You handled a heavy week. Want to unpack stress, sleep, or school pressure first?", "citation": "BAHA Safe Questions v2.3"},
                {"id": "m2", "author": "user", "text": "School pressure."},
                {"id": "m3", "author": "buddy", "text": "We can look at one thing you can control today, one thing you can ask help with, and one thing to pause for now.", "citation": "Cognitive coping tip reviewed 2026-06"},
            ],
            "notifications": [
                {"id": "sn1", "title": "Weekly check-in ready", "body": "Take 2 minutes to update your mood and energy.", "tone": "info", "time": "Today, 7:30 AM"},
                {"id": "sn2", "title": "New learning recommendation", "body": "A short sleep lesson matches your recent trend.", "tone": "success", "time": "Yesterday"},
            ],
            "achievements": [
                {"id": "a1", "title": "6-week reflection streak", "status": "earned"},
                {"id": "a2", "title": "First calm session", "status": "earned"},
                {"id": "a3", "title": "Support seeker", "status": "locked"},
            ],
            "safeQuestions": [
                {"id": "q1", "title": "Why does stress feel physical?", "tag": "stress"},
                {"id": "q2", "title": "How do I ask an adult for help?", "tag": "support"},
                {"id": "q3", "title": "Does sleep change how I think?", "tag": "sleep"},
            ],
            "challenges": [
                {"id": "c1", "title": "Phone-free 20 minutes before sleep", "status": "in-progress"},
                {"id": "c2", "title": "3-day hydration check", "status": "available"},
            ],
        },
        "parent": {
            "guardian": {"name": "Meera N.", "relationship": "Mother", "consent": "Active", "privacyTier": "Weekly summaries only"},
            "linkedStudents": [
                {"id": "child-1", "name": "Aarav N.", "summaryStatus": "Available", "focusTheme": "School stress improving"},
            ],
            "summary": {
                "headline": "Aarav showed steadier sleep and slightly lower stress this week.",
                "sleepTrend": 7,
                "moodTrend": 4,
                "guideTheme": "Supportive conversations about exams",
            },
            "guides": [
                {"id": "g1", "title": "Talking about pressure without judgment", "duration": "4 min"},
                {"id": "g2", "title": "What summary trends do and do not mean", "duration": "3 min"},
            ],
            "modules": [
                {"id": "pm1", "title": "Adolescent wellbeing basics", "progress": 84, "duration": "9 min"},
                {"id": "pm2", "title": "What consent tiers mean", "progress": 35, "duration": "6 min"},
            ],
            "notifications": [
                {"id": "pn1", "title": "Weekly summary available", "body": "A new wellbeing summary is ready to review.", "tone": "info", "time": "Today"},
                {"id": "pn2", "title": "Privacy tier updated", "body": "Summary access remains within approved boundaries.", "tone": "warning", "time": "2 days ago"},
            ],
        },
        "teacher": {
            "teacher": {"name": "Riya Thomas", "school": "Greenfield Public School", "training": "Completed"},
            "classTrends": [
                {"theme": "Sleep", "score": 67},
                {"theme": "Stress", "score": 58},
                {"theme": "Energy", "score": 72},
                {"theme": "Help seeking", "score": 49},
            ],
            "referrals": [
                {"id": "r1", "studentCode": "GF-11-A-24", "status": "In review", "submitted": "Today, 11:20 AM"},
                {"id": "r2", "studentCode": "GF-10-C-03", "status": "Closed", "submitted": "Yesterday"},
            ],
            "pastoralNotes": [
                {"id": "p1", "title": "Observed exam-related withdrawal", "status": "Draft"},
                {"id": "p2", "title": "Attendance and peer concerns", "status": "Submitted"},
            ],
            "modules": [
                {"id": "tm1", "title": "Reading anonymized wellbeing trends", "progress": 100, "duration": "7 min"},
                {"id": "tm2", "title": "Pastoral referrals: do and don't", "progress": 68, "duration": "5 min"},
            ],
            "notifications": [
                {"id": "tn1", "title": "Referral updated", "body": "One referral changed status to In review.", "tone": "info", "time": "Today"},
                {"id": "tn2", "title": "Policy update", "body": "Pastoral note retention guidance updated.", "tone": "warning", "time": "This week"},
            ],
        },
        "baha": {
            "operator": {"name": "Dr. Kavya Rao", "role": "Clinical Reviewer", "queueCount": 18},
            "queue": [
                {"id": "case-101", "studentCode": "GF-11-A-24", "severity": "High", "status": "New", "source": "Student help request"},
                {"id": "case-102", "studentCode": "GF-10-C-03", "severity": "Medium", "status": "Assigned", "source": "Teacher referral"},
                {"id": "case-103", "studentCode": "LM-09-B-11", "severity": "Monitoring", "status": "Awaiting follow-up", "source": "Trend threshold"},
            ],
            "caseTimeline": [
                {"time": "09:10", "event": "Student requested human support"},
                {"time": "09:18", "event": "Queue priority set to High"},
                {"time": "09:27", "event": "Clinical reviewer assigned"},
                {"time": "09:41", "event": "Guardian contact decision pending"},
            ],
            "analytics": [
                {"metric": "Weekly active students", "value": "1,284"},
                {"metric": "Check-in completion", "value": "78%"},
                {"metric": "Cases escalated", "value": "26"},
                {"metric": "Learning completion", "value": "64%"},
            ],
            "content": [
                {"id": "ct-1", "title": "Sleep lesson for exams", "status": "Published"},
                {"id": "ct-2", "title": "When Buddy should hand off", "status": "Review"},
                {"id": "ct-3", "title": "Safe Questions on body image", "status": "Flagged"},
            ],
            "audit": [
                {"id": "au-1", "actor": "Dr. Kavya Rao", "action": "Viewed case detail", "time": "Today, 09:42"},
                {"id": "au-2", "actor": "System", "action": "Threshold rule triggered", "time": "Today, 09:18"},
            ],
            "notifications": [
                {"id": "bn1", "title": "High-priority case added", "body": "Queue priority requires review within SLA.", "tone": "danger", "time": "Now"},
                {"id": "bn2", "title": "Content review due", "body": "One Safe Questions item is past review date.", "tone": "warning", "time": "Today"},
            ],
            "users": [
                {"id": "u1", "name": "Dr. Kavya Rao", "scope": "Clinical reviewer"},
                {"id": "u2", "name": "Arjun Patel", "scope": "Operations admin"},
            ],
        },
    }


TRANSLATIONS = {
    "en-IN": {
        "launch": "Launch prototype",
        "developerPanel": "Developer Panel",
        "theme": "Theme",
        "language": "Language",
        "network": "Network",
        "demoMode": "Demo mode",
        "reset": "Reset prototype",
        "back": "Back",
        "next": "Next",
    },
    "hi-IN": {
        "launch": "प्रोटोटाइप खोलें",
        "developerPanel": "डेवलपर पैनल",
        "theme": "थीम",
        "language": "भाषा",
        "network": "नेटवर्क",
        "demoMode": "डेमो मोड",
        "reset": "रीसेट करें",
        "back": "वापस",
        "next": "आगे",
    },
}


PACKAGE_JSON = {
    "name": "baha-prototype",
    "version": "0.1.0",
    "private": True,
    "scripts": {
        "dev": "next dev",
        "build": "next build",
        "start": "next start",
        "typecheck": "tsc --noEmit"
    },
    "dependencies": {
        "@hookform/resolvers": "^3.9.0",
        "@tanstack/react-query": "^5.59.20",
        "class-variance-authority": "^0.7.1",
        "clsx": "^2.1.1",
        "framer-motion": "^11.11.17",
        "lucide-react": "^0.454.0",
        "msw": "^2.6.4",
        "next": "^15.0.3",
        "react": "^18.3.1",
        "react-dom": "^18.3.1",
        "react-hook-form": "^7.53.1",
        "tailwind-merge": "^2.5.4",
        "zod": "^3.23.8"
    },
    "devDependencies": {
        "@types/node": "^22.8.1",
        "@types/react": "^18.3.3",
        "@types/react-dom": "^18.3.0",
        "autoprefixer": "^10.4.20",
        "postcss": "^8.4.47",
        "tailwindcss": "^3.4.14",
        "typescript": "^5.6.3"
    }
}


def build_files(screens):
    screens_json = json.dumps(screens, indent=2)
    mock_json = json.dumps(build_mock_data(), indent=2)
    translations_json = json.dumps(TRANSLATIONS, indent=2, ensure_ascii=False)
    role_switcher_json = json.dumps(ROLE_SWITCHER, indent=2)
    top_nav_json = json.dumps(TOP_NAV, indent=2)
    default_routes_json = json.dumps(DEFAULT_ROUTES, indent=2)
    files = {
        "package.json": json.dumps(PACKAGE_JSON, indent=2),
        "tsconfig.json": """
        {
          "compilerOptions": {
            "target": "ES2022",
            "lib": ["dom", "dom.iterable", "es2022"],
            "allowJs": false,
            "skipLibCheck": true,
            "strict": false,
            "noEmit": true,
            "module": "esnext",
            "moduleResolution": "bundler",
            "resolveJsonModule": true,
            "isolatedModules": true,
            "jsx": "preserve",
            "incremental": true,
            "baseUrl": ".",
            "paths": {
              "@/*": ["./*"]
            }
          },
          "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
          "exclude": ["node_modules"]
        }
        """,
        "next-env.d.ts": """
        /// <reference types="next" />
        /// <reference types="next/image-types/global" />
        """,
        "next.config.ts": """
        import type { NextConfig } from "next";

        const nextConfig: NextConfig = {
          reactStrictMode: true,
        };

        export default nextConfig;
        """,
        "postcss.config.js": """
        module.exports = {
          plugins: {
            tailwindcss: {},
            autoprefixer: {},
          },
        };
        """,
        "tailwind.config.ts": """
        import type { Config } from "tailwindcss";

        const config: Config = {
          content: [
            "./app/**/*.{ts,tsx}",
            "./components/**/*.{ts,tsx}",
            "./apps/**/*.{ts,tsx}",
            "./hooks/**/*.{ts,tsx}",
            "./lib/**/*.{ts,tsx}"
          ],
          darkMode: ["class", '[data-theme="dark"]'],
          theme: {
            extend: {
              colors: {
                canvas: "var(--color-canvas)",
                card: "var(--color-card)",
                ink: "var(--color-ink)",
                muted: "var(--color-muted)",
                line: "var(--color-line)",
                primary: "var(--color-primary)",
                support: "var(--color-support)",
                success: "var(--color-success)",
                warning: "var(--color-warning)",
                danger: "var(--color-danger)",
                info: "var(--color-info)"
              },
              borderRadius: {
                xl2: "1.5rem"
              },
              boxShadow: {
                calm: "0 8px 30px rgba(16,24,40,0.08)",
                float: "0 18px 60px rgba(21,94,239,0.18)"
              },
              fontFamily: {
                display: ["ui-rounded", "SF Pro Rounded", "Nunito Sans", "system-ui", "sans-serif"],
                body: ["Inter", "Segoe UI", "Arial", "sans-serif"],
                mono: ["ui-monospace", "SFMono-Regular", "monospace"]
              }
            },
          },
          plugins: [],
        };

        export default config;
        """,
        "components.json": """
        {
          "$schema": "https://ui.shadcn.com/schema.json",
          "style": "default",
          "rsc": true,
          "tsx": true,
          "tailwind": {
            "config": "tailwind.config.ts",
            "css": "app/globals.css",
            "baseColor": "slate",
            "cssVariables": true
          },
          "aliases": {
            "components": "@/components",
            "utils": "@/lib/utils",
            "ui": "@/components/ui"
          }
        }
        """,
        "app/globals.css": """
        @tailwind base;
        @tailwind components;
        @tailwind utilities;

        :root {
          --color-canvas: #f8f6f2;
          --color-card: #ffffff;
          --color-ink: #101828;
          --color-muted: #475467;
          --color-line: #d0d5dd;
          --color-primary: #155eef;
          --color-support: #0f766e;
          --color-success: #127a4b;
          --color-warning: #b54708;
          --color-danger: #b42318;
          --color-info: #175cd3;
          --color-role-accent: #7c9a92;
        }

        [data-theme="dark"] {
          --color-canvas: #101318;
          --color-card: #161b22;
          --color-ink: #f5f7fa;
          --color-muted: #cdd5df;
          --color-line: #344054;
          --color-primary: #84adff;
          --color-support: #5eead4;
          --color-success: #6ce9a6;
          --color-warning: #fec84b;
          --color-danger: #fda29b;
          --color-info: #84caff;
          --color-role-accent: #8bb8ff;
        }

        [data-role="student"][data-age-group="9-13"] {
          --color-role-accent: #f7b267;
        }

        [data-role="student"][data-age-group="14-16"] {
          --color-role-accent: #8aa7ff;
        }

        [data-role="student"][data-age-group="17-19"] {
          --color-role-accent: #7b83ff;
        }

        [data-role="parent"] {
          --color-role-accent: #7c9a92;
        }

        [data-role="teacher"] {
          --color-role-accent: #4b5563;
        }

        [data-role="baha"], [data-role="counselor"] {
          --color-role-accent: #344054;
        }

        html, body {
          min-height: 100%;
          background: radial-gradient(circle at top, rgba(21, 94, 239, 0.09), transparent 34%), var(--color-canvas);
          color: var(--color-ink);
        }

        body {
          font-family: Inter, "Segoe UI", Arial, sans-serif;
        }

        * {
          border-color: var(--color-line);
        }

        .scrollbar-none::-webkit-scrollbar {
          display: none;
        }
        """,
        "lib/utils.ts": """
        import { type ClassValue, clsx } from "clsx";
        import { twMerge } from "tailwind-merge";

        export function cn(...inputs: ClassValue[]) {
          return twMerge(clsx(inputs));
        }

        export function titleCase(value: string) {
          return value.replace(/_/g, " ").replace(/\\b\\w/g, (match) => match.toUpperCase());
        }
        """,
        "mock-data/generated/screens.json": screens_json,
        "mock-data/json/prototype-data.json": mock_json,
        "mock-data/json/translations.json": translations_json,
        "apps/student/config.ts": f"export const studentNav = {json.dumps(TOP_NAV['student'], indent=2)} as const;\n",
        "apps/parent/config.ts": f"export const parentNav = {json.dumps(TOP_NAV['parent'], indent=2)} as const;\n",
        "apps/teacher/config.ts": f"export const teacherNav = {json.dumps(TOP_NAV['teacher'], indent=2)} as const;\n",
        "apps/counselor/config.ts": f"export const counselorNav = {json.dumps(TOP_NAV['baha'], indent=2)} as const;\n",
        "lib/prototype-config.ts": f"""
        export const roleSwitcher = {role_switcher_json} as const;
        export const topNav = {top_nav_json} as const;
        export const defaultRoutes = {default_routes_json} as const;
        """,
        "lib/screen-registry.ts": """
        import screens from "@/mock-data/generated/screens.json";

        export type PrototypeRole = "student" | "parent" | "teacher" | "baha" | "counselor";

        export type ScreenMeta = {
          id: string;
          name: string;
          role: "student" | "parent" | "teacher" | "baha";
          roleLabel: string;
          route: string;
          pattern: string;
          layout: string;
          components: string[];
          slug: string;
          deepLink: string;
          transition: string;
          auth: string;
          permission: string;
          previousRoute: string;
          nextRoute: string;
          isTopLevel: boolean;
        };

        export const screenRegistry = screens as ScreenMeta[];

        export function canonicalRole(role: string): PrototypeRole {
          if (role === "counselor") return "baha";
          return role as PrototypeRole;
        }

        export function getRoleScreens(role: string) {
          const canonical = canonicalRole(role);
          return screenRegistry.filter((screen) => screen.role === canonical);
        }

        export function getScreenBySlug(role: string, slug: string) {
          const canonical = canonicalRole(role);
          return screenRegistry.find((screen) => screen.role === canonical && screen.slug === slug);
        }

        export function getScreenByRoute(route: string) {
          return screenRegistry.find((screen) => screen.route === route);
        }
        """,
        "lib/api.ts": """
        export async function fetchJson<T>(input: string): Promise<T> {
          const response = await fetch(input, { cache: "no-store" });
          if (!response.ok) {
            throw new Error(`Failed request: ${response.status}`);
          }
          return response.json();
        }
        """,
        "lib/prototype-store.tsx": """
        "use client";

        import { createContext, useContext, useEffect, useMemo, useState } from "react";
        import { defaultRoutes } from "@/lib/prototype-config";

        type ThemeMode = "light" | "dark";
        type NetworkMode = "online" | "offline";
        type AgeGroup = "9-13" | "14-16" | "17-19";
        type RoleMode = "student" | "parent" | "teacher" | "baha";
        type DemoMode = "baseline" | "seeded";
        type Language = "en-IN" | "hi-IN";

        type PrototypeState = {
          role: RoleMode;
          ageGroup: AgeGroup;
          theme: ThemeMode;
          network: NetworkMode;
          demoMode: DemoMode;
          language: Language;
          setRole: (value: RoleMode) => void;
          setAgeGroup: (value: AgeGroup) => void;
          setTheme: (value: ThemeMode) => void;
          setNetwork: (value: NetworkMode) => void;
          setDemoMode: (value: DemoMode) => void;
          setLanguage: (value: Language) => void;
          reset: () => void;
        };

        const STORAGE_KEY = "baha-prototype-settings";

        const PrototypeContext = createContext<PrototypeState | null>(null);

        export function PrototypeProvider({ children }: { children: React.ReactNode }) {
          const [role, setRole] = useState<RoleMode>("student");
          const [ageGroup, setAgeGroup] = useState<AgeGroup>("14-16");
          const [theme, setTheme] = useState<ThemeMode>("light");
          const [network, setNetwork] = useState<NetworkMode>("online");
          const [demoMode, setDemoMode] = useState<DemoMode>("seeded");
          const [language, setLanguage] = useState<Language>("en-IN");

          useEffect(() => {
            const raw = localStorage.getItem(STORAGE_KEY);
            if (!raw) return;
            try {
              const parsed = JSON.parse(raw);
              setRole(parsed.role ?? "student");
              setAgeGroup(parsed.ageGroup ?? "14-16");
              setTheme(parsed.theme ?? "light");
              setNetwork(parsed.network ?? "online");
              setDemoMode(parsed.demoMode ?? "seeded");
              setLanguage(parsed.language ?? "en-IN");
            } catch {}
          }, []);

          useEffect(() => {
            localStorage.setItem(STORAGE_KEY, JSON.stringify({ role, ageGroup, theme, network, demoMode, language }));
            document.documentElement.dataset.theme = theme;
            document.documentElement.dataset.role = role;
            document.documentElement.dataset.ageGroup = ageGroup;
          }, [role, ageGroup, theme, network, demoMode, language]);

          const value = useMemo(
            () => ({
              role,
              ageGroup,
              theme,
              network,
              demoMode,
              language,
              setRole,
              setAgeGroup,
              setTheme,
              setNetwork,
              setDemoMode,
              setLanguage,
              reset: () => {
                setRole("student");
                setAgeGroup("14-16");
                setTheme("light");
                setNetwork("online");
                setDemoMode("seeded");
                setLanguage("en-IN");
                localStorage.removeItem(STORAGE_KEY);
              },
            }),
            [role, ageGroup, theme, network, demoMode, language],
          );

          return <PrototypeContext.Provider value={value}>{children}</PrototypeContext.Provider>;
        }

        export function usePrototypeSettings() {
          const context = useContext(PrototypeContext);
          if (!context) throw new Error("usePrototypeSettings must be used within PrototypeProvider");
          return context;
        }

        export { defaultRoutes };
        """,
        "lib/query-provider.tsx": """
        "use client";

        import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
        import { useState } from "react";

        export function PrototypeQueryProvider({ children }: { children: React.ReactNode }) {
          const [client] = useState(() => new QueryClient());
          return <QueryClientProvider client={client}>{children}</QueryClientProvider>;
        }
        """,
        "lib/init-mocks.ts": """
        let started = false;

        export async function initMocks() {
          if (started || typeof window === "undefined") return;
          const { worker } = await import("@/mock-data/msw/browser");
          await worker.start({ onUnhandledRequest: "bypass" });
          started = true;
        }
        """,
        "mock-data/msw/browser.ts": """
        import { setupWorker } from "msw/browser";
        import { handlers } from "@/mock-data/msw/handlers";

        export const worker = setupWorker(...handlers);
        """,
        "mock-data/msw/handlers.ts": """
        import { http, HttpResponse } from "msw";
        import prototypeData from "@/mock-data/json/prototype-data.json";
        import screens from "@/mock-data/generated/screens.json";
        import translations from "@/mock-data/json/translations.json";

        const wait = (ms = 220) => new Promise((resolve) => setTimeout(resolve, ms));

        export const handlers = [
          http.get("/prototype-api/screens", async () => {
            await wait();
            return HttpResponse.json(screens);
          }),
          http.get("/prototype-api/role-data", async ({ request }) => {
            await wait();
            const url = new URL(request.url);
            const role = url.searchParams.get("role") || "student";
            const canonical = role === "counselor" ? "baha" : role;
            return HttpResponse.json((prototypeData as Record<string, unknown>)[canonical]);
          }),
          http.get("/prototype-api/translations", async () => {
            await wait(80);
            return HttpResponse.json(translations);
          }),
          http.post("/prototype-api/demo/seed", async () => {
            await wait(100);
            return HttpResponse.json({ ok: true, message: "Demo state refreshed" });
          }),
        ];
        """,
        "hooks/use-prototype-data.ts": """
        "use client";

        import { useQuery } from "@tanstack/react-query";
        import { fetchJson } from "@/lib/api";

        export function usePrototypeRoleData(role: string) {
          return useQuery({
            queryKey: ["role-data", role],
            queryFn: () => fetchJson(`/prototype-api/role-data?role=${role}`),
          });
        }

        export function usePrototypeScreens() {
          return useQuery({
            queryKey: ["screens"],
            queryFn: () => fetchJson("/prototype-api/screens"),
          });
        }

        export function useTranslations() {
          return useQuery({
            queryKey: ["translations"],
            queryFn: () => fetchJson("/prototype-api/translations"),
          });
        }
        """,
        "components/ui/button.tsx": """
        import * as React from "react";
        import { cva, type VariantProps } from "class-variance-authority";
        import { cn } from "@/lib/utils";

        const buttonVariants = cva(
          "inline-flex items-center justify-center rounded-full text-sm font-medium transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary disabled:pointer-events-none disabled:opacity-40",
          {
            variants: {
              variant: {
                primary: "bg-primary text-white shadow-float hover:translate-y-[-1px]",
                secondary: "border border-line bg-card text-ink hover:bg-black/5 dark:hover:bg-white/5",
                ghost: "text-muted hover:bg-black/5 dark:hover:bg-white/5",
                danger: "bg-danger text-white",
              },
              size: {
                sm: "h-10 px-4",
                md: "h-12 px-5",
                lg: "h-14 px-6 text-base",
              },
            },
            defaultVariants: {
              variant: "primary",
              size: "md",
            },
          },
        );

        export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement>, VariantProps<typeof buttonVariants> {}

        const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(({ className, variant, size, ...props }, ref) => (
          <button ref={ref} className={cn(buttonVariants({ variant, size, className }))} {...props} />
        ));
        Button.displayName = "Button";

        export { Button, buttonVariants };
        """,
        "components/ui/card.tsx": """
        import { cn } from "@/lib/utils";

        export function Card({ className, children }: { className?: string; children: React.ReactNode }) {
          return <div className={cn("rounded-[24px] border border-line bg-card p-5 shadow-calm", className)}>{children}</div>;
        }
        """,
        "components/ui/input.tsx": """
        import { cn } from "@/lib/utils";

        export function Input(props: React.InputHTMLAttributes<HTMLInputElement>) {
          return <input {...props} className={cn("h-12 w-full rounded-2xl border border-line bg-canvas px-4 text-sm text-ink outline-none transition focus:border-primary", props.className)} />;
        }

        export function Textarea(props: React.TextareaHTMLAttributes<HTMLTextAreaElement>) {
          return <textarea {...props} className={cn("min-h-28 w-full rounded-3xl border border-line bg-canvas px-4 py-3 text-sm text-ink outline-none transition focus:border-primary", props.className)} />;
        }
        """,
        "components/ui/badge.tsx": """
        import { cn } from "@/lib/utils";

        export function Badge({ children, tone = "neutral" }: { children: React.ReactNode; tone?: "neutral" | "primary" | "success" | "warning" | "danger" }) {
          const tones = {
            neutral: "bg-black/5 text-muted dark:bg-white/10 dark:text-white/80",
            primary: "bg-primary/10 text-primary",
            success: "bg-success/10 text-success",
            warning: "bg-warning/10 text-warning",
            danger: "bg-danger/10 text-danger",
          };
          return <span className={cn("inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold", tones[tone])}>{children}</span>;
        }
        """,
        "components/ui/progress.tsx": """
        export function Progress({ value }: { value: number }) {
          return (
            <div className="h-2 w-full rounded-full bg-black/5 dark:bg-white/10">
              <div className="h-2 rounded-full bg-primary transition-all duration-300" style={{ width: `${value}%` }} />
            </div>
          );
        }
        """,
        "components/ui/dialog.tsx": """
        import { AnimatePresence, motion } from "framer-motion";
        import { Button } from "@/components/ui/button";

        export function Dialog({
          open,
          title,
          description,
          onClose,
          children,
        }: {
          open: boolean;
          title: string;
          description: string;
          onClose: () => void;
          children?: React.ReactNode;
        }) {
          return (
            <AnimatePresence>
              {open ? (
                <motion.div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4 backdrop-blur-sm" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}>
                  <motion.div initial={{ opacity: 0, scale: 0.96 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.96 }} className="w-full max-w-md rounded-[28px] border border-line bg-card p-6 shadow-float">
                    <h3 className="font-display text-xl font-semibold text-ink">{title}</h3>
                    <p className="mt-2 text-sm text-muted">{description}</p>
                    {children}
                    <div className="mt-5 flex justify-end">
                      <Button variant="secondary" onClick={onClose}>Close</Button>
                    </div>
                  </motion.div>
                </motion.div>
              ) : null}
            </AnimatePresence>
          );
        }
        """,
        "components/ui/sheet.tsx": """
        import { AnimatePresence, motion } from "framer-motion";

        export function Sheet({
          open,
          onClose,
          title,
          children,
        }: {
          open: boolean;
          onClose: () => void;
          title: string;
          children: React.ReactNode;
        }) {
          return (
            <AnimatePresence>
              {open ? (
                <motion.div className="fixed inset-0 z-40 bg-black/25" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={onClose}>
                  <motion.div className="absolute bottom-0 left-0 right-0 rounded-t-[32px] border border-line bg-card p-6 shadow-float" initial={{ y: 320 }} animate={{ y: 0 }} exit={{ y: 320 }} transition={{ duration: 0.24 }} onClick={(event) => event.stopPropagation()}>
                    <div className="mx-auto mb-4 h-1.5 w-14 rounded-full bg-black/10 dark:bg-white/10" />
                    <h3 className="font-display text-lg font-semibold text-ink">{title}</h3>
                    <div className="mt-4">{children}</div>
                  </motion.div>
                </motion.div>
              ) : null}
            </AnimatePresence>
          );
        }
        """,
        "components/design-system/data-widgets.tsx": """
        import { motion } from "framer-motion";
        import { Badge } from "@/components/ui/badge";
        import { Card } from "@/components/ui/card";
        import { Progress } from "@/components/ui/progress";

        export function StatGrid({ items }: { items: { label: string; value: string | number; tone?: "neutral" | "primary" | "success" | "warning" | "danger" }[] }) {
          return (
            <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
              {items.map((item) => (
                <motion.div key={item.label} initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }}>
                  <Card>
                    <p className="text-sm text-muted">{item.label}</p>
                    <div className="mt-3 flex items-center justify-between">
                      <p className="font-display text-2xl font-semibold text-ink">{item.value}</p>
                      <Badge tone={item.tone ?? "primary"}>{item.tone ?? "live"}</Badge>
                    </div>
                  </Card>
                </motion.div>
              ))}
            </div>
          );
        }

        export function BarChart({ values, labelKey, valueKey }: { values: any[]; labelKey: string; valueKey: string }) {
          return (
            <Card className="space-y-4">
              <div>
                <h3 className="font-display text-lg font-semibold text-ink">Trend snapshot</h3>
                <p className="text-sm text-muted">Plain-language visual summaries with privacy-safe abstraction.</p>
              </div>
              <div className="space-y-3">
                {values.map((item) => (
                  <div key={item[labelKey]} className="space-y-1">
                    <div className="flex items-center justify-between text-sm">
                      <span>{item[labelKey]}</span>
                      <span className="text-muted">{item[valueKey]}</span>
                    </div>
                    <Progress value={typeof item[valueKey] === "number" ? item[valueKey] : Number(item[valueKey])} />
                  </div>
                ))}
              </div>
            </Card>
          );
        }

        export function TimelineWidget({ events }: { events: { time: string; event: string }[] }) {
          return (
            <Card className="space-y-4">
              <h3 className="font-display text-lg font-semibold text-ink">Timeline</h3>
              <div className="space-y-4">
                {events.map((event, index) => (
                  <div className="flex gap-3" key={`${event.time}-${index}`}>
                    <div className="mt-1 h-2.5 w-2.5 rounded-full bg-primary" />
                    <div>
                      <p className="text-sm font-medium text-ink">{event.event}</p>
                      <p className="text-xs text-muted">{event.time}</p>
                    </div>
                  </div>
                ))}
              </div>
            </Card>
          );
        }

        export function MessageList({ messages }: { messages: { id: string; author: string; text: string; citation?: string }[] }) {
          return (
            <div className="space-y-3">
              {messages.map((message) => (
                <motion.div key={message.id} initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} className={`max-w-[90%] rounded-[24px] px-4 py-3 text-sm ${message.author === "user" ? "ml-auto bg-primary text-white" : "bg-card text-ink shadow-calm"}`}>
                  <p>{message.text}</p>
                  {message.citation ? <p className="mt-2 text-xs opacity-70">{message.citation}</p> : null}
                </motion.div>
              ))}
            </div>
          );
        }
        """,
        "components/design-system/dev-panel.tsx": """
        "use client";

        import { useState } from "react";
        import { Button } from "@/components/ui/button";
        import { usePrototypeSettings } from "@/lib/prototype-store";
        import { useRouter, usePathname } from "next/navigation";
        import { defaultRoutes, roleSwitcher } from "@/lib/prototype-config";

        export function DeveloperPanel() {
          const [open, setOpen] = useState(false);
          const { role, ageGroup, theme, network, language, demoMode, setRole, setAgeGroup, setTheme, setNetwork, setLanguage, setDemoMode, reset } = usePrototypeSettings();
          const router = useRouter();
          const pathname = usePathname();

          function handleRoleChange(nextRole: "student" | "parent" | "teacher" | "baha") {
            setRole(nextRole);
            router.push(defaultRoutes[nextRole]);
          }

          return (
            <div className="fixed bottom-4 right-4 z-50">
              <Button size="lg" onClick={() => setOpen((value) => !value)}>Developer Panel</Button>
              {open ? (
                <div className="mt-3 w-[320px] rounded-[28px] border border-line bg-card p-5 shadow-float">
                  <div className="space-y-4 text-sm text-muted">
                    <Field label="Role">
                      <select value={role} onChange={(event) => handleRoleChange(event.target.value as "student" | "parent" | "teacher" | "baha")} className="h-11 w-full rounded-2xl border border-line bg-canvas px-3 text-ink">
                        {roleSwitcher.map((item) => <option key={item.id} value={item.id === "baha" ? "baha" : item.id}>{item.label}</option>)}
                      </select>
                    </Field>
                    <Field label="Age Group">
                      <select value={ageGroup} onChange={(event) => setAgeGroup(event.target.value as "9-13" | "14-16" | "17-19")} className="h-11 w-full rounded-2xl border border-line bg-canvas px-3 text-ink">
                        {["9-13", "14-16", "17-19"].map((item) => <option key={item}>{item}</option>)}
                      </select>
                    </Field>
                    <Field label="Theme">
                      <ToggleGroup value={theme} onChange={(value) => setTheme(value as "light" | "dark")} options={["light", "dark"]} />
                    </Field>
                    <Field label="Network">
                      <ToggleGroup value={network} onChange={(value) => setNetwork(value as "online" | "offline")} options={["online", "offline"]} />
                    </Field>
                    <Field label="Language">
                      <select value={language} onChange={(event) => setLanguage(event.target.value as "en-IN" | "hi-IN")} className="h-11 w-full rounded-2xl border border-line bg-canvas px-3 text-ink">
                        <option value="en-IN">English (India)</option>
                        <option value="hi-IN">Hindi</option>
                      </select>
                    </Field>
                    <Field label="Demo Data">
                      <ToggleGroup value={demoMode} onChange={(value) => setDemoMode(value as "baseline" | "seeded")} options={["baseline", "seeded"]} />
                    </Field>
                    <div className="rounded-2xl bg-black/5 p-3 text-xs dark:bg-white/5">
                      <p>Current route</p>
                      <p className="mt-1 font-mono text-[11px] text-ink">{pathname}</p>
                    </div>
                    <Button variant="secondary" className="w-full" onClick={reset}>Reset Prototype</Button>
                  </div>
                </div>
              ) : null}
            </div>
          );
        }

        function Field({ label, children }: { label: string; children: React.ReactNode }) {
          return (
            <div className="space-y-2">
              <p className="text-xs font-semibold uppercase tracking-[0.18em] text-muted">{label}</p>
              {children}
            </div>
          );
        }

        function ToggleGroup({ value, onChange, options }: { value: string; onChange: (value: string) => void; options: string[] }) {
          return (
            <div className="grid grid-cols-2 gap-2 rounded-2xl bg-canvas p-1">
              {options.map((option) => (
                <button key={option} onClick={() => onChange(option)} className={`rounded-2xl px-3 py-2 capitalize transition ${value === option ? "bg-primary text-white" : "text-ink"}`}>
                  {option}
                </button>
              ))}
            </div>
          );
        }
        """,
        "components/design-system/app-shell.tsx": """
        "use client";

        import Link from "next/link";
        import { ArrowLeft, ChevronRight, MoonStar, Sparkles } from "lucide-react";
        import { useRouter } from "next/navigation";
        import { motion } from "framer-motion";
        import { Button } from "@/components/ui/button";
        import { Badge } from "@/components/ui/badge";
        import { Card } from "@/components/ui/card";
        import { topNav } from "@/lib/prototype-config";
        import type { ScreenMeta } from "@/lib/screen-registry";
        import { cn } from "@/lib/utils";
        import { usePrototypeSettings } from "@/lib/prototype-store";

        export function PrototypeAppShell({
          screen,
          children,
          onOpenDialog,
          onOpenSheet,
        }: {
          screen: ScreenMeta;
          children: React.ReactNode;
          onOpenDialog: () => void;
          onOpenSheet: () => void;
        }) {
          const router = useRouter();
          const { role, ageGroup, theme, network } = usePrototypeSettings();
          const navItems = topNav[screen.role];
          const desktop = screen.role === "baha" || screen.role === "teacher";

          return (
            <div className="min-h-screen">
              <div className={cn("mx-auto flex min-h-screen max-w-[1600px]", desktop ? "gap-6 p-4 lg:p-6" : "justify-center px-3 py-4 sm:px-6")}>
                {desktop ? (
                  <aside className="hidden w-72 shrink-0 lg:block">
                    <Card className="sticky top-6 space-y-5">
                      <div>
                        <p className="text-xs uppercase tracking-[0.2em] text-muted">BAHA Prototype</p>
                        <h1 className="mt-2 font-display text-2xl font-semibold text-ink">{screen.roleLabel}</h1>
                      </div>
                      <nav className="space-y-2">
                        {navItems.map((item) => (
                          <Link key={item.route} href={item.route} className={cn("flex items-center justify-between rounded-2xl px-4 py-3 text-sm text-muted transition hover:bg-black/5 hover:text-ink dark:hover:bg-white/5", item.route === screen.route && "bg-primary text-white hover:text-white")}>
                            <span>{item.label}</span>
                            <ChevronRight className="h-4 w-4" />
                          </Link>
                        ))}
                      </nav>
                      <div className="rounded-3xl bg-black/5 p-4 dark:bg-white/5">
                        <p className="text-sm font-medium text-ink">Prototype context</p>
                        <div className="mt-3 flex flex-wrap gap-2">
                          <Badge tone="primary">{ageGroup}</Badge>
                          <Badge tone={network === "online" ? "success" : "warning"}>{network}</Badge>
                          <Badge tone="neutral">{theme}</Badge>
                        </div>
                      </div>
                    </Card>
                  </aside>
                ) : null}
                <div className={cn("flex min-h-[90vh] flex-col", desktop ? "flex-1" : "w-full max-w-md")}>
                  <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} className="rounded-[32px] border border-line bg-card shadow-float">
                    <header className="border-b border-line px-5 py-4">
                      <div className="flex items-start justify-between gap-4">
                        <div className="flex items-start gap-3">
                          <button onClick={() => router.push(screen.previousRoute || `/${screen.role}`)} className="mt-1 inline-flex h-10 w-10 items-center justify-center rounded-full border border-line bg-canvas text-ink">
                            <ArrowLeft className="h-4 w-4" />
                          </button>
                          <div>
                            <p className="text-xs uppercase tracking-[0.18em] text-muted">{screen.id}</p>
                            <h2 className="font-display text-2xl font-semibold text-ink">{screen.name}</h2>
                            <p className="mt-1 text-sm text-muted">{screen.pattern} · {screen.layout}</p>
                          </div>
                        </div>
                        <div className="flex items-center gap-2">
                          <Button variant="ghost" size="sm" onClick={onOpenSheet}>Quick actions</Button>
                          <Button variant="secondary" size="sm" onClick={onOpenDialog}>Info</Button>
                        </div>
                      </div>
                      <div className="mt-4 flex flex-wrap gap-2">
                        <Badge tone="primary">{screen.transition}</Badge>
                        <Badge tone="neutral">{screen.roleLabel}</Badge>
                        <Badge tone={network === "online" ? "success" : "warning"}>{network}</Badge>
                        {theme === "dark" ? <Badge tone="neutral"><MoonStar className="mr-1 h-3 w-3" /> Dark</Badge> : null}
                        <Badge tone="warning"><Sparkles className="mr-1 h-3 w-3" /> Calm Neo-Modern Care</Badge>
                      </div>
                    </header>
                    <main className="min-h-[720px] bg-canvas/40 px-4 py-5 sm:px-5">{children}</main>
                    {!desktop ? (
                      <footer className="border-t border-line px-3 py-3">
                        <div className="grid grid-cols-5 gap-2">
                          {navItems.map((item) => (
                            <Link key={item.route} href={item.route} className={cn("rounded-2xl px-2 py-2 text-center text-xs transition", item.route === screen.route ? "bg-primary text-white" : "text-muted hover:bg-black/5 dark:hover:bg-white/5")}>
                              {item.label}
                            </Link>
                          ))}
                        </div>
                      </footer>
                    ) : null}
                  </motion.div>
                </div>
              </div>
            </div>
          );
        }
        """,
        "components/design-system/screen-renderer.tsx": """
        "use client";

        import { useMemo, useState } from "react";
        import { motion } from "framer-motion";
        import { Controller, useForm } from "react-hook-form";
        import { zodResolver } from "@hookform/resolvers/zod";
        import { z } from "zod";
        import Link from "next/link";
        import { Bell, BookOpen, Brain, Filter, HeartPulse, MessageSquareText, ShieldAlert, Sparkles, Star, Timer, UserRound } from "lucide-react";
        import type { ScreenMeta } from "@/lib/screen-registry";
        import { PrototypeAppShell } from "@/components/design-system/app-shell";
        import { StatGrid, BarChart, TimelineWidget, MessageList } from "@/components/design-system/data-widgets";
        import { Button } from "@/components/ui/button";
        import { Card } from "@/components/ui/card";
        import { Badge } from "@/components/ui/badge";
        import { Input, Textarea } from "@/components/ui/input";
        import { Dialog } from "@/components/ui/dialog";
        import { Sheet } from "@/components/ui/sheet";
        import { Progress } from "@/components/ui/progress";
        import { usePrototypeSettings } from "@/lib/prototype-store";

        const noteSchema = z.object({
          focus: z.string().min(2),
          detail: z.string().min(8),
          urgency: z.string().min(2),
        });

        const checkInSchema = z.object({
          mood: z.number().min(1).max(5),
          sleep: z.number().min(1).max(10),
          stress: z.number().min(1).max(5),
          energy: z.number().min(1).max(5),
        });

        export function PrototypeScreenRenderer({ screen, roleData, roleScreens }: { screen: ScreenMeta; roleData: any; roleScreens: ScreenMeta[] }) {
          const [dialogOpen, setDialogOpen] = useState(false);
          const [sheetOpen, setSheetOpen] = useState(false);
          const { ageGroup, network, demoMode, language } = usePrototypeSettings();

          const checkInForm = useForm({
            resolver: zodResolver(checkInSchema),
            defaultValues: { mood: 4, sleep: 7, stress: 3, energy: 4 },
          });

          const noteForm = useForm({
            resolver: zodResolver(noteSchema),
            defaultValues: { focus: screen.name, detail: "This mocked prototype captures the interaction flow for stakeholder review.", urgency: "Moderate" },
          });

          const quickLinks = useMemo(() => {
            const pairs = [
              roleScreens.find((item) => /module detail/i.test(item.name)),
              roleScreens.find((item) => /lesson view/i.test(item.name)),
              roleScreens.find((item) => /quiz/i.test(item.name)),
              roleScreens.find((item) => /citation detail/i.test(item.name)),
              roleScreens.find((item) => /help center/i.test(item.name)),
              roleScreens.find((item) => /case detail/i.test(item.name)),
              roleScreens.find((item) => /content editor/i.test(item.name)),
              roleScreens.find((item) => /queue filters/i.test(item.name)),
            ].filter(Boolean) as ScreenMeta[];
            return pairs.slice(0, 4);
          }, [roleScreens]);

          const statItems = buildStatItems(screen, roleData);

          return (
            <>
              <PrototypeAppShell screen={screen} onOpenDialog={() => setDialogOpen(true)} onOpenSheet={() => setSheetOpen(true)}>
                <div className="space-y-4">
                  {network === "offline" ? (
                    <Card className="border-warning/30 bg-warning/10">
                      <div className="flex items-start gap-3">
                        <ShieldAlert className="mt-1 h-5 w-5 text-warning" />
                        <div>
                          <p className="font-medium text-ink">Offline simulation active</p>
                          <p className="text-sm text-muted">The prototype is showing cached-safe behavior and resilient UI states for this route.</p>
                        </div>
                      </div>
                    </Card>
                  ) : null}

                  <Hero screen={screen} ageGroup={ageGroup} demoMode={demoMode} />
                  <StatGrid items={statItems} />

                  {renderScreenContent(screen, roleData, checkInForm, noteForm, quickLinks)}

                  <Card className="space-y-3">
                    <div className="flex items-center justify-between">
                      <div>
                        <h3 className="font-display text-lg font-semibold text-ink">Prototype navigation</h3>
                        <p className="text-sm text-muted">Every route in this role is available for stakeholder walkthrough.</p>
                      </div>
                      <Badge tone="neutral">{language}</Badge>
                    </div>
                    <div className="grid gap-2 sm:grid-cols-2">
                      {roleScreens.slice(0, 8).map((item) => (
                        <Link key={item.route} href={item.route} className={`rounded-2xl border border-line bg-canvas px-4 py-3 text-sm transition hover:-translate-y-0.5 ${item.route === screen.route ? "border-primary text-primary" : "text-ink"}`}>
                          <div className="flex items-center justify-between">
                            <span>{item.name}</span>
                            <span className="text-xs text-muted">{item.id}</span>
                          </div>
                        </Link>
                      ))}
                    </div>
                    <div className="flex justify-end gap-3">
                      <Link href={screen.previousRoute}><Button variant="secondary">Back Route</Button></Link>
                      <Link href={screen.nextRoute}><Button>Next Route</Button></Link>
                    </div>
                  </Card>
                </div>
              </PrototypeAppShell>

              <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} title={`${screen.name} details`} description={`${screen.auth}. ${screen.permission}. Transition: ${screen.transition}.`}>
                <div className="mt-4 rounded-2xl bg-canvas p-4 text-sm text-muted">
                  <p>Components</p>
                  <div className="mt-2 flex flex-wrap gap-2">
                    {screen.components.map((component) => <Badge key={component} tone="primary">{component}</Badge>)}
                  </div>
                </div>
              </Dialog>

              <Sheet open={sheetOpen} onClose={() => setSheetOpen(false)} title="Prototype quick actions">
                <div className="space-y-3">
                  <div className="grid gap-2 sm:grid-cols-2">
                    {quickLinks.map((item) => (
                      <Link key={item.route} href={item.route} className="rounded-2xl border border-line bg-canvas px-4 py-3 text-sm text-ink">
                        {item.name}
                      </Link>
                    ))}
                  </div>
                  <Button className="w-full">Trigger success snackbar</Button>
                </div>
              </Sheet>
            </>
          );
        }

        function Hero({ screen, ageGroup, demoMode }: { screen: ScreenMeta; ageGroup: string; demoMode: string }) {
          return (
            <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }}>
              <Card className="overflow-hidden bg-gradient-to-br from-primary/10 via-card to-support/10">
                <div className="flex flex-wrap items-start justify-between gap-4">
                  <div className="space-y-2">
                    <p className="text-xs uppercase tracking-[0.18em] text-muted">{screen.roleLabel} experience</p>
                    <h3 className="font-display text-2xl font-semibold text-ink">{screen.name}</h3>
                    <p className="max-w-2xl text-sm text-muted">Faithful interactive prototype driven by the BAHA architecture, UX specification, navigation model, design system, and visual language.</p>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    <Badge tone="primary">{screen.pattern}</Badge>
                    <Badge tone="success">{ageGroup}</Badge>
                    <Badge tone="warning">{demoMode}</Badge>
                  </div>
                </div>
              </Card>
            </motion.div>
          );
        }

        function buildStatItems(screen: ScreenMeta, roleData: any) {
          if (screen.role === "student") {
            return [
              { label: "Current streak", value: `${roleData.profile.streak} weeks`, tone: "success" as const },
              { label: "Focus theme", value: roleData.profile.focusTheme, tone: "primary" as const },
              { label: "Notifications", value: roleData.notifications.length, tone: "warning" as const },
              { label: "Learning progress", value: `${roleData.modules[0].progress}%`, tone: "primary" as const },
            ];
          }
          if (screen.role === "parent") {
            return [
              { label: "Consent status", value: roleData.guardian.consent, tone: "success" as const },
              { label: "Linked students", value: roleData.linkedStudents.length, tone: "primary" as const },
              { label: "Summary focus", value: roleData.summary.guideTheme, tone: "warning" as const },
              { label: "Unread notices", value: roleData.notifications.length, tone: "primary" as const },
            ];
          }
          if (screen.role === "teacher") {
            return [
              { label: "School", value: roleData.teacher.school, tone: "neutral" as const },
              { label: "Referrals", value: roleData.referrals.length, tone: "warning" as const },
              { label: "Pastoral notes", value: roleData.pastoralNotes.length, tone: "primary" as const },
              { label: "Training", value: roleData.teacher.training, tone: "success" as const },
            ];
          }
          return [
            { label: "Queue count", value: roleData.operator.queueCount, tone: "danger" as const },
            { label: "Cases", value: roleData.queue.length, tone: "warning" as const },
            { label: "Content items", value: roleData.content.length, tone: "primary" as const },
            { label: "Audit events", value: roleData.audit.length, tone: "neutral" as const },
          ];
        }

        function renderScreenContent(screen: ScreenMeta, roleData: any, checkInForm: any, noteForm: any, quickLinks: ScreenMeta[]) {
          const lower = screen.name.toLowerCase();

          if (lower.includes("splash")) {
            return (
              <Card className="flex min-h-[280px] flex-col items-center justify-center gap-4 text-center">
                <div className="rounded-full bg-primary/10 p-5 text-primary"><Sparkles className="h-8 w-8" /></div>
                <h3 className="font-display text-3xl font-semibold">BAHA Wellness Companion</h3>
                <p className="max-w-md text-sm text-muted">Bootstrapping session context, privacy posture, mock notifications, and stakeholder-ready demo data.</p>
                <Progress value={72} />
              </Card>
            );
          }

          if (lower.includes("questionnaire")) {
            return (
              <Card className="space-y-5">
                <div>
                  <h3 className="font-display text-xl font-semibold">Weekly check-in</h3>
                  <p className="text-sm text-muted">Mocked React Hook Form + Zod validation with fully local interaction states.</p>
                </div>
                {(["mood", "sleep", "stress", "energy"] as const).map((field) => (
                  <Controller
                    key={field}
                    control={checkInForm.control}
                    name={field}
                    render={({ field: controllerField }) => (
                      <div className="space-y-2">
                        <div className="flex items-center justify-between text-sm">
                          <span className="capitalize">{field}</span>
                          <span className="text-muted">{controllerField.value}</span>
                        </div>
                        <input type="range" min={field === "sleep" ? 1 : 1} max={field === "sleep" ? 10 : 5} value={controllerField.value} onChange={(event) => controllerField.onChange(Number(event.target.value))} className="w-full accent-[var(--color-primary)]" />
                      </div>
                    )}
                  />
                ))}
                <div className="flex justify-end">
                  <Button onClick={checkInForm.handleSubmit(() => {})}>Save check-in</Button>
                </div>
              </Card>
            );
          }

          if (lower.includes("buddy") || lower.includes("chat")) {
            return (
              <div className="grid gap-4 xl:grid-cols-[1.3fr_0.9fr]">
                <Card className="space-y-4">
                  <div className="flex items-center gap-2">
                    <MessageSquareText className="h-5 w-5 text-primary" />
                    <h3 className="font-display text-xl font-semibold">Conversation</h3>
                  </div>
                  <MessageList messages={roleData.chat} />
                  <div className="rounded-[24px] border border-line bg-canvas p-3">
                    <Input placeholder="Type a supportive message..." />
                    <div className="mt-3 flex justify-end gap-2">
                      <Button variant="secondary">Open citation</Button>
                      <Button>Send</Button>
                    </div>
                  </div>
                </Card>
                <Card className="space-y-4">
                  <h3 className="font-display text-xl font-semibold">Safe prompts and handoff</h3>
                  <div className="space-y-3">
                    {roleData.safeQuestions?.map((question: any) => (
                      <div key={question.id} className="rounded-2xl bg-canvas p-4">
                        <div className="flex items-center justify-between gap-2">
                          <p className="text-sm font-medium text-ink">{question.title}</p>
                          <Badge tone="primary">{question.tag}</Badge>
                        </div>
                      </div>
                    ))}
                  </div>
                  <Button className="w-full" variant="secondary">Get human help</Button>
                </Card>
              </div>
            );
          }

          if (lower.includes("learning") || lower.includes("module") || lower.includes("lesson") || lower.includes("quiz")) {
            return (
              <div className="grid gap-4 xl:grid-cols-[1.1fr_0.9fr]">
                <Card className="space-y-4">
                  <div className="flex items-center gap-2">
                    <BookOpen className="h-5 w-5 text-primary" />
                    <h3 className="font-display text-xl font-semibold">Learning catalogue</h3>
                  </div>
                  <div className="space-y-3">
                    {(roleData.modules || []).map((module: any) => (
                      <div key={module.id} className="rounded-[24px] border border-line bg-canvas p-4">
                        <div className="flex items-start justify-between gap-3">
                          <div>
                            <p className="font-medium text-ink">{module.title}</p>
                            <p className="mt-1 text-sm text-muted">{module.duration} · {module.format ?? "guided content"}</p>
                          </div>
                          <Badge tone="primary">{module.progress}%</Badge>
                        </div>
                        <div className="mt-3"><Progress value={module.progress} /></div>
                        <div className="mt-3 flex gap-2">
                          <Button variant="secondary">Details</Button>
                          <Button>Continue</Button>
                        </div>
                      </div>
                    ))}
                  </div>
                </Card>
                <Card className="space-y-4">
                  <h3 className="font-display text-xl font-semibold">Module detail and quiz</h3>
                  <p className="text-sm text-muted">This prototype shows lesson progression, quiz completion, and reflection states without backend dependency.</p>
                  <div className="space-y-3">
                    <div className="rounded-[24px] bg-canvas p-4">
                      <p className="font-medium text-ink">Lesson summary</p>
                      <p className="mt-2 text-sm text-muted">Supportive content cards, audio, and reflection prompts use the documented design-system components.</p>
                    </div>
                    <div className="rounded-[24px] bg-canvas p-4">
                      <p className="font-medium text-ink">Quiz result</p>
                      <p className="mt-2 text-sm text-muted">Formative feedback remains encouraging and non-punitive.</p>
                      <div className="mt-3 flex gap-2">
                        <Badge tone="success">Completed</Badge>
                        <Badge tone="primary">Reflection saved</Badge>
                      </div>
                    </div>
                  </div>
                </Card>
              </div>
            );
          }

          if (lower.includes("game") || lower.includes("breathing") || lower.includes("friendship") || lower.includes("emotion explorer")) {
            return (
              <div className="grid gap-4 xl:grid-cols-[1.1fr_0.9fr]">
                <Card className="space-y-4">
                  <div className="flex items-center gap-2">
                    <Brain className="h-5 w-5 text-primary" />
                    <h3 className="font-display text-xl font-semibold">Games and regulation</h3>
                  </div>
                  <div className="grid gap-3">
                    {(roleData.games || []).map((game: any) => (
                      <div key={game.id} className="rounded-[24px] border border-line bg-canvas p-4">
                        <div className="flex items-center justify-between gap-3">
                          <div>
                            <p className="font-medium text-ink">{game.title}</p>
                            <p className="text-sm text-muted">{game.duration}</p>
                          </div>
                          <Badge tone="primary">{game.status}</Badge>
                        </div>
                        <div className="mt-3 flex gap-2">
                          <Button variant="secondary">Details</Button>
                          <Button>Launch</Button>
                        </div>
                      </div>
                    ))}
                  </div>
                </Card>
                <Card className="space-y-4">
                  <h3 className="font-display text-xl font-semibold">Achievements</h3>
                  <div className="space-y-3">
                    {(roleData.achievements || []).map((achievement: any) => (
                      <div key={achievement.id} className="rounded-[24px] bg-canvas p-4">
                        <div className="flex items-center justify-between">
                          <p className="font-medium text-ink">{achievement.title}</p>
                          <Badge tone={achievement.status === "earned" ? "success" : "neutral"}>{achievement.status}</Badge>
                        </div>
                      </div>
                    ))}
                  </div>
                </Card>
              </div>
            );
          }

          if (lower.includes("queue") || lower.includes("case") || lower.includes("audit") || lower.includes("content") || lower.includes("analytics") || lower.includes("threshold")) {
            return (
              <div className="grid gap-4 xl:grid-cols-[1.2fr_0.8fr]">
                <Card className="space-y-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Filter className="h-5 w-5 text-primary" />
                      <h3 className="font-display text-xl font-semibold">Operational workspace</h3>
                    </div>
                    <Button variant="secondary">Open filters</Button>
                  </div>
                  <div className="overflow-hidden rounded-[24px] border border-line">
                    <div className="grid grid-cols-4 bg-canvas px-4 py-3 text-xs font-semibold uppercase tracking-[0.12em] text-muted">
                      <span>ID</span>
                      <span>Source</span>
                      <span>Status</span>
                      <span>Severity</span>
                    </div>
                    {(roleData.queue || roleData.content || roleData.users || []).map((row: any, index: number) => (
                      <div key={row.id ?? index} className="grid grid-cols-4 border-t border-line bg-card px-4 py-4 text-sm text-ink">
                        <span>{row.id}</span>
                        <span>{row.source ?? row.title ?? row.name}</span>
                        <span>{row.status ?? row.scope}</span>
                        <span>{row.severity ?? "Reviewed"}</span>
                      </div>
                    ))}
                  </div>
                </Card>
                <div className="space-y-4">
                  {roleData.caseTimeline ? <TimelineWidget events={roleData.caseTimeline} /> : null}
                  {roleData.analytics ? <StatGrid items={roleData.analytics.map((item: any) => ({ label: item.metric, value: item.value, tone: "primary" as const }))} /> : null}
                </div>
              </div>
            );
          }

          if (lower.includes("referral") || lower.includes("pastoral") || lower.includes("request") || lower.includes("assignment") || lower.includes("editor")) {
            return (
              <div className="grid gap-4 xl:grid-cols-[1fr_0.95fr]">
                <Card className="space-y-4">
                  <h3 className="font-display text-xl font-semibold">Workflow form</h3>
                  <div className="space-y-3">
                    <Input placeholder="Focus area" {...noteForm.register("focus")} />
                    <Input placeholder="Urgency" {...noteForm.register("urgency")} />
                    <Textarea placeholder="Add an operational note or support detail" {...noteForm.register("detail")} />
                    <div className="flex justify-end gap-2">
                      <Button variant="secondary">Save draft</Button>
                      <Button onClick={noteForm.handleSubmit(() => {})}>Submit</Button>
                    </div>
                  </div>
                </Card>
                <Card className="space-y-4">
                  <h3 className="font-display text-xl font-semibold">Workflow context</h3>
                  <div className="space-y-3">
                    {quickLinks.map((item) => (
                      <Link key={item.route} href={item.route} className="block rounded-[24px] bg-canvas p-4 text-sm text-ink">
                        {item.name}
                      </Link>
                    ))}
                  </div>
                </Card>
              </div>
            );
          }

          if (lower.includes("trend") || lower.includes("summary") || lower.includes("dashboard") || lower.includes("home")) {
            const chartValues = screen.role === "teacher" ? roleData.classTrends : screen.role === "baha" ? roleData.analytics.map((item: any, index: number) => ({ theme: item.metric, score: 50 + index * 10 })) : roleData.moodHistory ?? [{ week: "Now", mood: 3 }];
            return (
              <div className="grid gap-4 xl:grid-cols-[1.15fr_0.85fr]">
                <BarChart values={chartValues} labelKey={screen.role === "baha" ? "theme" : screen.role === "teacher" ? "theme" : "week"} valueKey={screen.role === "teacher" ? "score" : screen.role === "baha" ? "score" : "mood"} />
                <Card className="space-y-4">
                  <h3 className="font-display text-xl font-semibold">Recommendations and alerts</h3>
                  <div className="space-y-3">
                    {(roleData.notifications || []).map((item: any) => (
                      <div key={item.id} className="rounded-[24px] bg-canvas p-4">
                        <div className="flex items-start gap-3">
                          <Bell className="mt-0.5 h-4 w-4 text-primary" />
                          <div>
                            <p className="font-medium text-ink">{item.title}</p>
                            <p className="mt-1 text-sm text-muted">{item.body}</p>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </Card>
              </div>
            );
          }

          if (lower.includes("profile") || lower.includes("settings") || lower.includes("privacy") || lower.includes("data rights") || lower.includes("notification")) {
            return (
              <div className="grid gap-4 xl:grid-cols-[1fr_1fr]">
                <Card className="space-y-3">
                  <div className="flex items-center gap-2">
                    <UserRound className="h-5 w-5 text-primary" />
                    <h3 className="font-display text-xl font-semibold">Profile and preferences</h3>
                  </div>
                  {[{ label: "Reminders", value: "Enabled" }, { label: "Privacy tier", value: roleData.profile?.consentTier ?? roleData.guardian?.privacyTier ?? "Role-safe default" }, { label: "Language", value: "English (India)" }].map((item) => (
                    <div key={item.label} className="flex items-center justify-between rounded-[24px] bg-canvas px-4 py-3">
                      <span className="text-sm text-ink">{item.label}</span>
                      <Badge tone="primary">{item.value}</Badge>
                    </div>
                  ))}
                </Card>
                <Card className="space-y-3">
                  <h3 className="font-display text-xl font-semibold">Support and privacy</h3>
                  <div className="space-y-3">
                    <div className="rounded-[24px] bg-canvas p-4 text-sm text-muted">Settings are interactive, role-aware, and fully local to this prototype.</div>
                    <div className="flex gap-2">
                      <Button variant="secondary">Open policy dialog</Button>
                      <Button>Save preferences</Button>
                    </div>
                  </div>
                </Card>
              </div>
            );
          }

          if (lower.includes("offline") || lower.includes("pending") || lower.includes("restricted")) {
            return (
              <Card className="space-y-4">
                <div className="flex items-start gap-3">
                  <ShieldAlert className="mt-1 h-6 w-6 text-warning" />
                  <div>
                    <h3 className="font-display text-xl font-semibold text-ink">Resilient state</h3>
                    <p className="mt-2 text-sm text-muted">This route demonstrates offline, pending, or restricted-access behavior without breaking the prototype flow.</p>
                  </div>
                </div>
                <div className="grid gap-3 sm:grid-cols-2">
                  <Card className="bg-canvas">
                    <p className="font-medium text-ink">Cached actions</p>
                    <p className="mt-2 text-sm text-muted">Review saved content, open support guidance, and retry when network is restored.</p>
                  </Card>
                  <Card className="bg-canvas">
                    <p className="font-medium text-ink">Safe next step</p>
                    <p className="mt-2 text-sm text-muted">Use a documented parent route or return to the role home shell.</p>
                  </Card>
                </div>
              </Card>
            );
          }

          return (
            <div className="grid gap-4 xl:grid-cols-[1.05fr_0.95fr]">
              <Card className="space-y-4">
                <div className="flex items-center gap-2">
                  <HeartPulse className="h-5 w-5 text-primary" />
                  <h3 className="font-display text-xl font-semibold">Documented screen experience</h3>
                </div>
                <p className="text-sm text-muted">This screen is rendered from the existing BAHA architecture artifacts, using shared prototype components and realistic mock data.</p>
                <div className="grid gap-3 sm:grid-cols-2">
                  {quickLinks.map((item) => (
                    <Link key={item.route} href={item.route} className="rounded-[24px] bg-canvas p-4 text-sm text-ink">
                      {item.name}
                    </Link>
                  ))}
                </div>
              </Card>
              <Card className="space-y-4">
                <h3 className="font-display text-xl font-semibold">Interaction quality</h3>
                <div className="space-y-3">
                  <QualityRow icon={<Timer className="h-4 w-4" />} title="Motion" body="200–300ms transitions and tactile feedback." />
                  <QualityRow icon={<Star className="h-4 w-4" />} title="Accessibility" body="Large touch targets, contrast, and keyboard support." />
                  <QualityRow icon={<Sparkles className="h-4 w-4" />} title="Mock realism" body="Local JSON data and scenario-specific interactions." />
                </div>
              </Card>
            </div>
          );
        }

        function QualityRow({ icon, title, body }: { icon: React.ReactNode; title: string; body: string }) {
          return (
            <div className="flex gap-3 rounded-[24px] bg-canvas p-4">
              <div className="mt-0.5 text-primary">{icon}</div>
              <div>
                <p className="font-medium text-ink">{title}</p>
                <p className="mt-1 text-sm text-muted">{body}</p>
              </div>
            </div>
          );
        }
        """,
        "app/providers.tsx": """
        "use client";

        import { useEffect } from "react";
        import { PrototypeProvider } from "@/lib/prototype-store";
        import { PrototypeQueryProvider } from "@/lib/query-provider";
        import { initMocks } from "@/lib/init-mocks";
        import { DeveloperPanel } from "@/components/design-system/dev-panel";

        export function Providers({ children }: { children: React.ReactNode }) {
          useEffect(() => {
            initMocks();
          }, []);

          return (
            <PrototypeQueryProvider>
              <PrototypeProvider>
                {children}
                <DeveloperPanel />
              </PrototypeProvider>
            </PrototypeQueryProvider>
          );
        }
        """,
        "app/layout.tsx": """
        import "./globals.css";
        import { Providers } from "@/app/providers";

        export const metadata = {
          title: "BAHA Interactive Prototype",
          description: "Stakeholder review prototype generated from BAHA architecture documents.",
        };

        export default function RootLayout({ children }: { children: React.ReactNode }) {
          return (
            <html lang="en">
              <body>
                <Providers>{children}</Providers>
              </body>
            </html>
          );
        }
        """,
        "app/page.tsx": """
        import Link from "next/link";
        import { Card } from "@/components/ui/card";
        import { Button } from "@/components/ui/button";
        import { roleSwitcher } from "@/lib/prototype-config";
        import { defaultRoutes } from "@/lib/prototype-config";

        export default function HomePage() {
          return (
            <main className="min-h-screen bg-canvas px-4 py-10 text-ink">
              <div className="mx-auto max-w-6xl space-y-8">
                <section className="rounded-[36px] border border-line bg-card p-8 shadow-float">
                  <p className="text-xs uppercase tracking-[0.2em] text-muted">BAHA Stakeholder Prototype</p>
                  <h1 className="mt-3 font-display text-4xl font-semibold">Complete interactive product experience</h1>
                  <p className="mt-4 max-w-3xl text-base text-muted">
                    This prototype is powered entirely by mocked data and the existing BAHA architecture, UX, navigation, design-system, and visual-language repositories.
                  </p>
                </section>
                <section className="grid gap-4 lg:grid-cols-4">
                  {roleSwitcher.map((role) => (
                    <Card key={role.id} className="flex h-full flex-col justify-between gap-6">
                      <div>
                        <h2 className="font-display text-2xl font-semibold text-ink">{role.label}</h2>
                        <p className="mt-2 text-sm text-muted">{role.description}</p>
                      </div>
                      <Link href={defaultRoutes[role.id as keyof typeof defaultRoutes] || "/student/splash"}>
                        <Button className="w-full">Launch prototype</Button>
                      </Link>
                    </Card>
                  ))}
                </section>
              </div>
            </main>
          );
        }
        """,
        "app/[role]/page.tsx": """
        import { redirect } from "next/navigation";
        import { defaultRoutes } from "@/lib/prototype-config";

        export default function RoleIndex({ params }: { params: { role: string } }) {
          const route = defaultRoutes[params.role as keyof typeof defaultRoutes] ?? defaultRoutes.student;
          redirect(route);
        }
        """,
        "app/[role]/[screen]/page.tsx": """
        import { notFound } from "next/navigation";
        import { getRoleScreens, getScreenBySlug } from "@/lib/screen-registry";
        import { PrototypeScreenPage } from "@/components/design-system/screen-page";

        export default function ScreenPage({ params }: { params: { role: string; screen: string } }) {
          const screen = getScreenBySlug(params.role, params.screen);
          if (!screen) return notFound();
          const roleScreens = getRoleScreens(params.role);
          return <PrototypeScreenPage screen={screen} roleScreens={roleScreens} role={params.role} />;
        }
        """,
        "components/design-system/screen-page.tsx": """
        "use client";

        import { usePrototypeRoleData } from "@/hooks/use-prototype-data";
        import { PrototypeScreenRenderer } from "@/components/design-system/screen-renderer";
        import { Card } from "@/components/ui/card";
        import type { ScreenMeta } from "@/lib/screen-registry";

        export function PrototypeScreenPage({ screen, roleScreens, role }: { screen: ScreenMeta; roleScreens: ScreenMeta[]; role: string }) {
          const { data, isLoading } = usePrototypeRoleData(role);

          if (isLoading || !data) {
            return (
              <main className="min-h-screen bg-canvas p-6">
                <div className="mx-auto max-w-5xl space-y-4">
                  <Card className="h-40 animate-pulse bg-canvas" />
                  <Card className="h-72 animate-pulse bg-canvas" />
                </div>
              </main>
            );
          }

          return <PrototypeScreenRenderer screen={screen} roleData={data} roleScreens={roleScreens} />;
        }
        """,
        "app/not-found.tsx": """
        import Link from "next/link";
        import { Button } from "@/components/ui/button";

        export default function NotFound() {
          return (
            <main className="flex min-h-screen items-center justify-center bg-canvas p-6">
              <div className="rounded-[32px] border border-line bg-card p-8 text-center shadow-float">
                <h1 className="font-display text-3xl font-semibold text-ink">Prototype route not found</h1>
                <p className="mt-3 text-sm text-muted">Try relaunching a documented role experience.</p>
                <div className="mt-6">
                  <Link href="/"><Button>Back to launcher</Button></Link>
                </div>
              </div>
            </main>
          );
        }
        """,
    }
    return files


def main():
    screens = enrich_screens()
    for relative, content in build_files(screens).items():
      path = APP_ROOT / relative
      if relative.endswith(".json") and relative != "package.json":
          path.parent.mkdir(parents=True, exist_ok=True)
          if not content.endswith("\n"):
              content = content + "\n"
          path.write_text(content, encoding="utf-8")
      else:
          write(path, content)

    print(f"Generated prototype scaffolding for {len(screens)} documented screens.")


if __name__ == "__main__":
    main()
