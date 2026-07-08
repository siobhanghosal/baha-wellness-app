import type { ScreenMeta } from "@/lib/screen-registry";

export type DemoPersonaId = "persona-a" | "persona-b" | "persona-c";

export type DemoScenario = {
  id: string;
  name: string;
  description: string;
  purpose: string;
  estimatedDuration: string;
  role: "student" | "parent" | "teacher" | "baha";
  ageGroup: "9-13" | "14-16" | "17-19";
  personaId: DemoPersonaId;
  routes: string[];
};

export type DemoAudienceCard = {
  id: string;
  label: string;
  role: "student" | "parent" | "teacher" | "baha";
  ageGroup: "9-13" | "14-16" | "17-19";
  targetAudience: string;
  purpose: string;
  mainWorkflows: string[];
  estimatedDemoDuration: string;
  route: string;
};

export const demoAudienceCards: DemoAudienceCard[] = [
  {
    id: "student-9-13",
    label: "Student (9-13)",
    role: "student",
    ageGroup: "9-13",
    targetAudience: "Upper-primary students, school counselors, safeguarding reviewers.",
    purpose: "Show age-appropriate onboarding, emotional literacy, and gentle support loops.",
    mainWorkflows: ["Onboarding and consent", "Weekly check-in", "Guided learning", "Games and achievements"],
    estimatedDemoDuration: "6-8 min",
    route: "/student/splash",
  },
  {
    id: "student-14-16",
    label: "Student (14-16)",
    role: "student",
    ageGroup: "14-16",
    targetAudience: "Secondary students, teachers, parents, pilot partners.",
    purpose: "Demonstrate the core adolescent wellbeing journey with realistic academic-stress data.",
    mainWorkflows: ["Daily dashboard", "Weekly reflection", "Buddy chat", "Help-seeking pathways"],
    estimatedDemoDuration: "8-10 min",
    route: "/student/home_dashboard",
  },
  {
    id: "student-17-19",
    label: "Student (17-19)",
    role: "student",
    ageGroup: "17-19",
    targetAudience: "Senior students, clinicians, transition-to-college stakeholders.",
    purpose: "Show mature autonomy, privacy-aware coaching, and deeper self-management journeys.",
    mainWorkflows: ["Consent review", "Trend insight follow-up", "Learning and reflection", "Support escalation"],
    estimatedDemoDuration: "7-9 min",
    route: "/student/home_dashboard",
  },
  {
    id: "parent",
    label: "Parent",
    role: "parent",
    ageGroup: "14-16",
    targetAudience: "Parents, guardians, school leaders, NGO program teams.",
    purpose: "Explain how summaries, privacy boundaries, and conversation guidance support families.",
    mainWorkflows: ["Weekly summary", "Trend explanation", "Conversation guides", "Consent and settings"],
    estimatedDemoDuration: "5-7 min",
    route: "/parent/weekly_summary_home",
  },
  {
    id: "teacher",
    label: "Teacher",
    role: "teacher",
    ageGroup: "14-16",
    targetAudience: "Teachers, pastoral teams, implementation leads.",
    purpose: "Demonstrate anonymized class signals and responsible referral workflows.",
    mainWorkflows: ["Class trends", "Pastoral note input", "Referral queue", "Staff learning"],
    estimatedDemoDuration: "6-8 min",
    route: "/teacher/class_trends_dashboard",
  },
  {
    id: "counselor",
    label: "Counselor",
    role: "baha",
    ageGroup: "14-16",
    targetAudience: "Clinicians, BAHA operators, safeguarding partners, investors.",
    purpose: "Show triage, case handling, content governance, and analytics in one operational flow.",
    mainWorkflows: ["Support queue", "Case review", "Escalation actions", "Clinical analytics"],
    estimatedDemoDuration: "7-10 min",
    route: "/baha/support_queue",
  },
];

export const demoPersonas = [
  {
    id: "persona-a" as const,
    label: "Persona A",
    title: "Healthy student",
    summary: "A resilient student with steady routines, healthy sleep, and positive engagement.",
    bestFor: "Launchers, parent summaries, and learning adoption stories.",
  },
  {
    id: "persona-b" as const,
    label: "Persona B",
    title: "Academic stress",
    summary: "A high-performing student experiencing exam pressure, rising stress, and help-seeking moments.",
    bestFor: "Weekly check-ins, chatbot, teacher referral, and support queue workflows.",
  },
  {
    id: "persona-c" as const,
    label: "Persona C",
    title: "Sleep difficulties",
    summary: "A student showing inconsistent sleep, low morning energy, and regulation challenges.",
    bestFor: "Learning, parent review, sleep coaching, and emergency monitoring walkthroughs.",
  },
];

export const demoScenarios: DemoScenario[] = [
  {
    id: "student-daily-journey",
    name: "Student Daily Journey",
    description: "Walk through dashboard, reflection, and next-step support in one compact flow.",
    purpose: "Show how the student app feels like an everyday companion instead of a one-off intervention.",
    estimatedDuration: "5 min",
    role: "student",
    ageGroup: "14-16",
    personaId: "persona-b",
    routes: [
      "/student/home_dashboard",
      "/student/weekly_check_in_prompt",
      "/student/check_in_questionnaire",
      "/student/check_in_completion",
      "/student/trend_dashboard_active",
      "/student/challenges_hub",
    ],
  },
  {
    id: "student-weekly-checkin",
    name: "Student Weekly Check-in",
    description: "Move from prompt to completion and trend reflection with realistic signals.",
    purpose: "Explain how the product captures wellbeing patterns without feeling clinical or heavy.",
    estimatedDuration: "4 min",
    role: "student",
    ageGroup: "14-16",
    personaId: "persona-b",
    routes: [
      "/student/weekly_check_in_prompt",
      "/student/check_in_questionnaire",
      "/student/check_in_completion",
      "/student/trend_dashboard_active",
      "/student/trend_insight_detail",
    ],
  },
  {
    id: "learning-journey",
    name: "Learning Journey",
    description: "Open the learning hub, continue a module, and end on quiz-based reflection.",
    purpose: "Show how educational content reinforces self-awareness and coping skills.",
    estimatedDuration: "4 min",
    role: "student",
    ageGroup: "17-19",
    personaId: "persona-c",
    routes: [
      "/student/learning_home",
      "/student/module_detail",
      "/student/lesson_view",
      "/student/quiz_and_reflection",
    ],
  },
  {
    id: "chatbot-journey",
    name: "Chatbot Journey",
    description: "Demonstrate safe prompts, supportive responses, and handoff-safe boundaries.",
    purpose: "Give reviewers confidence in the Buddy interaction model and escalation posture.",
    estimatedDuration: "4 min",
    role: "student",
    ageGroup: "14-16",
    personaId: "persona-b",
    routes: [
      "/student/safe_questions_library",
      "/student/buddy_chat",
      "/student/buddy_citation_detail",
      "/student/buddy_out_of_scope",
    ],
  },
  {
    id: "games-journey",
    name: "Games Journey",
    description: "Walk through playful regulation tools and achievement loops.",
    purpose: "Show how engagement mechanics reinforce healthy habits without gamifying distress.",
    estimatedDuration: "4 min",
    role: "student",
    ageGroup: "9-13",
    personaId: "persona-a",
    routes: [
      "/student/games_hub",
      "/student/emotion_explorer",
      "/student/friendship_choices",
      "/student/calm_breathing",
      "/student/time_cap_prompt",
    ],
  },
  {
    id: "parent-weekly-review",
    name: "Parent Weekly Review",
    description: "Review the summary, unpack the trend explanation, and open a conversation guide.",
    purpose: "Show how parents receive useful insight while staying within consent boundaries.",
    estimatedDuration: "5 min",
    role: "parent",
    ageGroup: "14-16",
    personaId: "persona-c",
    routes: [
      "/parent/weekly_summary_home",
      "/parent/sleep_and_mood_trend_explanation",
      "/parent/conversation_guide_detail",
      "/parent/notification_settings",
    ],
  },
  {
    id: "teacher-referral",
    name: "Teacher Referral",
    description: "Start with class trends, create a note, and land in the referral queue.",
    purpose: "Demonstrate how educators move from observation to escalation responsibly.",
    estimatedDuration: "5 min",
    role: "teacher",
    ageGroup: "14-16",
    personaId: "persona-b",
    routes: [
      "/teacher/class_trends_dashboard",
      "/teacher/trend_filter",
      "/teacher/pastoral_input_form",
      "/teacher/pastoral_input_confirmation",
      "/teacher/referral_queue",
      "/teacher/referral_detail",
    ],
  },
  {
    id: "counselor-escalation",
    name: "Counselor Escalation",
    description: "Move from the queue to a case, then through actions and assignment.",
    purpose: "Show the BAHA operational workflow from triage to documented response.",
    estimatedDuration: "6 min",
    role: "baha",
    ageGroup: "14-16",
    personaId: "persona-b",
    routes: [
      "/baha/support_queue",
      "/baha/queue_filters",
      "/baha/case_detail",
      "/baha/action_log_editor",
      "/baha/case_assignment",
    ],
  },
  {
    id: "privacy-consent",
    name: "Privacy & Consent",
    description: "Focus on the privacy promise, settings, and consent controls already in the product.",
    purpose: "Help reviewers understand how trust and informed participation are built into the experience.",
    estimatedDuration: "4 min",
    role: "student",
    ageGroup: "17-19",
    personaId: "persona-a",
    routes: [
      "/student/privacy_settings",
      "/student/consent_tier_editor",
      "/student/consent_override_notification",
      "/student/profile_summary",
    ],
  },
  {
    id: "emergency-workflow",
    name: "Emergency Workflow",
    description: "Jump to the high-priority support path and emergency protocol view.",
    purpose: "Show how the prototype handles urgent situations with clarity and accountability.",
    estimatedDuration: "4 min",
    role: "baha",
    ageGroup: "14-16",
    personaId: "persona-c",
    routes: [
      "/baha/support_queue",
      "/baha/case_detail",
      "/baha/case_assignment",
      "/baha/emergency_protocol_view",
    ],
  },
];

const personaRoleOverrides: Record<DemoPersonaId, Record<string, Record<string, unknown>>> = {
  "persona-a": {
    student: {
      profile: {
        name: "Aanya S.",
        streak: 8,
        energy: "Balanced",
        focusTheme: "Protecting healthy routines",
      },
      moodHistory: [
        { week: "Week 1", mood: 4, sleep: 8, stress: 2, energy: 4 },
        { week: "Week 2", mood: 4, sleep: 8, stress: 2, energy: 4 },
        { week: "Week 3", mood: 5, sleep: 8, stress: 2, energy: 5 },
        { week: "Week 4", mood: 4, sleep: 7, stress: 2, energy: 4 },
      ],
      modules: [
        { id: "mod-1", title: "Stress and Study Balance", duration: "8 min", progress: 91, format: "interactive lesson" },
        { id: "mod-2", title: "Sleep That Helps Your Mood", duration: "6 min", progress: 76, format: "audio + reflection" },
        { id: "mod-3", title: "Asking for Help Early", duration: "5 min", progress: 48, format: "cards + quiz" },
      ],
      chat: [
        { id: "m1", author: "buddy", text: "You have been showing steady routines. Want a quick check-in or a confidence boost for the week?", citation: "BAHA Safe Questions v2.3" },
        { id: "m2", author: "user", text: "A confidence boost." },
        { id: "m3", author: "buddy", text: "You have kept a strong streak. Let us lock in one habit that helped and repeat it this week.", citation: "Strength-based coaching prompt" },
      ],
      notifications: [
        { id: "sn1", title: "Reflection streak strong", body: "You have completed eight steady weeks.", tone: "success", time: "Today, 7:15 AM" },
        { id: "sn2", title: "Achievement unlocked", body: "Healthy habit explorer badge earned.", tone: "info", time: "Yesterday" },
      ],
      achievements: [
        { id: "a1", title: "8-week reflection streak", status: "earned" },
        { id: "a2", title: "Healthy sleep champion", status: "earned" },
        { id: "a3", title: "Support seeker", status: "earned" },
      ],
      games: [
        { id: "game-1", title: "Emotion Explorer", duration: "4 min", status: "Completed" },
        { id: "game-2", title: "Friendship Choices", duration: "5 min", status: "Replay" },
        { id: "game-3", title: "Calm Breathing", duration: "3 min", status: "Ready" },
      ],
    },
    parent: {
      summary: {
        headline: "Aanya maintained healthy routines and showed stable mood and sleep trends this week.",
        sleepTrend: 8,
        moodTrend: 4,
        guideTheme: "Encouraging independence while staying connected",
      },
      linkedStudents: [{ id: "child-1", name: "Aanya S.", summaryStatus: "Available", focusTheme: "Healthy routines sustained" }],
      notifications: [
        { id: "pn1", title: "Weekly summary available", body: "A positive wellbeing summary is ready to review.", tone: "success", time: "Today" },
        { id: "pn2", title: "New conversation guide", body: "Try a short strengths-based conversation prompt.", tone: "info", time: "This week" },
      ],
    },
    teacher: {
      classTrends: [
        { theme: "Sleep", score: 74 },
        { theme: "Stress", score: 63 },
        { theme: "Energy", score: 77 },
        { theme: "Help seeking", score: 58 },
      ],
      referrals: [{ id: "r1", studentCode: "GF-11-A-24", status: "Closed", submitted: "Last week" }],
      pastoralNotes: [{ id: "p1", title: "Positive engagement observed", status: "Submitted" }],
    },
    baha: {
      operator: { name: "Dr. Kavya Rao", role: "Clinical Reviewer", queueCount: 9 },
      queue: [
        { id: "case-101", studentCode: "GF-11-A-24", severity: "Monitoring", status: "Closed", source: "Routine review" },
        { id: "case-102", studentCode: "GF-10-C-03", severity: "Low", status: "Monitoring", source: "Teacher check-in" },
      ],
      analytics: [
        { metric: "Weekly active students", value: "1,284" },
        { metric: "Check-in completion", value: "84%" },
        { metric: "Cases escalated", value: "11" },
        { metric: "Learning completion", value: "72%" },
      ],
    },
  },
  "persona-b": {
    student: {
      profile: {
        name: "Aarav N.",
        streak: 6,
        energy: "Steady but strained",
        focusTheme: "Managing school stress",
      },
      moodHistory: [
        { week: "Week 1", mood: 3, sleep: 6, stress: 4, energy: 3 },
        { week: "Week 2", mood: 4, sleep: 7, stress: 3, energy: 4 },
        { week: "Week 3", mood: 3, sleep: 6, stress: 5, energy: 3 },
        { week: "Week 4", mood: 3, sleep: 6, stress: 5, energy: 3 },
      ],
      modules: [
        { id: "mod-1", title: "Stress and Study Balance", duration: "8 min", progress: 72, format: "interactive lesson" },
        { id: "mod-2", title: "Sleep That Helps Your Mood", duration: "6 min", progress: 40, format: "audio + reflection" },
        { id: "mod-3", title: "Asking for Help Early", duration: "5 min", progress: 12, format: "cards + quiz" },
      ],
      chat: [
        { id: "m1", author: "buddy", text: "You handled a heavy week. Want to unpack stress, sleep, or school pressure first?", citation: "BAHA Safe Questions v2.3" },
        { id: "m2", author: "user", text: "School pressure." },
        { id: "m3", author: "buddy", text: "We can look at one thing you can control today, one thing you can ask help with, and one thing to pause for now.", citation: "Cognitive coping tip reviewed 2026-06" },
      ],
      notifications: [
        { id: "sn1", title: "Weekly check-in ready", body: "Take 2 minutes to update your mood and energy.", tone: "info", time: "Today, 7:30 AM" },
        { id: "sn2", title: "New learning recommendation", body: "A short stress lesson matches your recent trend.", tone: "warning", time: "Yesterday" },
      ],
      achievements: [
        { id: "a1", title: "6-week reflection streak", status: "earned" },
        { id: "a2", title: "First calm session", status: "earned" },
        { id: "a3", title: "Support seeker", status: "locked" },
      ],
      games: [
        { id: "game-1", title: "Emotion Explorer", duration: "4 min", status: "Ready" },
        { id: "game-2", title: "Friendship Choices", duration: "5 min", status: "Resume" },
        { id: "game-3", title: "Calm Breathing", duration: "3 min", status: "Quick start" },
      ],
    },
    parent: {
      summary: {
        headline: "Aarav showed exam-related strain this week, with stress rising faster than sleep recovered.",
        sleepTrend: 6,
        moodTrend: 3,
        guideTheme: "Supportive conversations about exams",
      },
      linkedStudents: [{ id: "child-1", name: "Aarav N.", summaryStatus: "Available", focusTheme: "School stress improving slowly" }],
      notifications: [
        { id: "pn1", title: "Weekly summary available", body: "Stress signals rose slightly this week.", tone: "warning", time: "Today" },
        { id: "pn2", title: "Conversation guide suggested", body: "Try a calm, non-judgmental exam check-in.", tone: "info", time: "Yesterday" },
      ],
    },
    teacher: {
      classTrends: [
        { theme: "Sleep", score: 67 },
        { theme: "Stress", score: 58 },
        { theme: "Energy", score: 72 },
        { theme: "Help seeking", score: 49 },
      ],
      referrals: [
        { id: "r1", studentCode: "GF-11-A-24", status: "In review", submitted: "Today, 11:20 AM" },
        { id: "r2", studentCode: "GF-10-C-03", status: "Closed", submitted: "Yesterday" },
      ],
      pastoralNotes: [
        { id: "p1", title: "Observed exam-related withdrawal", status: "Draft" },
        { id: "p2", title: "Attendance and peer concerns", status: "Submitted" },
      ],
    },
    baha: {
      operator: { name: "Dr. Kavya Rao", role: "Clinical Reviewer", queueCount: 18 },
      queue: [
        { id: "case-101", studentCode: "GF-11-A-24", severity: "High", status: "New", source: "Student help request" },
        { id: "case-102", studentCode: "GF-10-C-03", severity: "Medium", status: "Assigned", source: "Teacher referral" },
        { id: "case-103", studentCode: "LM-09-B-11", severity: "Monitoring", status: "Awaiting follow-up", source: "Trend threshold" },
      ],
      caseTimeline: [
        { time: "09:10", event: "Student requested human support" },
        { time: "09:18", event: "Queue priority set to High" },
        { time: "09:27", event: "Clinical reviewer assigned" },
        { time: "09:41", event: "Guardian contact decision pending" },
      ],
      notifications: [
        { id: "bn1", title: "High-priority case added", body: "Queue priority requires review within SLA.", tone: "danger", time: "Now" },
        { id: "bn2", title: "Content review due", body: "One Safe Questions item is past review date.", tone: "warning", time: "Today" },
      ],
    },
  },
  "persona-c": {
    student: {
      profile: {
        name: "Zoya R.",
        streak: 3,
        energy: "Low mornings",
        focusTheme: "Improving sleep consistency",
      },
      moodHistory: [
        { week: "Week 1", mood: 3, sleep: 5, stress: 4, energy: 2 },
        { week: "Week 2", mood: 3, sleep: 5, stress: 4, energy: 2 },
        { week: "Week 3", mood: 2, sleep: 4, stress: 4, energy: 2 },
        { week: "Week 4", mood: 3, sleep: 5, stress: 3, energy: 3 },
      ],
      modules: [
        { id: "mod-1", title: "Stress and Study Balance", duration: "8 min", progress: 38, format: "interactive lesson" },
        { id: "mod-2", title: "Sleep That Helps Your Mood", duration: "6 min", progress: 81, format: "audio + reflection" },
        { id: "mod-3", title: "Asking for Help Early", duration: "5 min", progress: 15, format: "cards + quiz" },
      ],
      chat: [
        { id: "m1", author: "buddy", text: "Want to look at what happens before sleep or how tired mornings feel?", citation: "Sleep check-in prompt v1.7" },
        { id: "m2", author: "user", text: "Mornings feel heavy." },
        { id: "m3", author: "buddy", text: "Let us try one lighter evening habit and one morning support step this week.", citation: "Behavioral sleep support prompt" },
      ],
      notifications: [
        { id: "sn1", title: "Sleep lesson recommended", body: "A short audio module matches your recent trend.", tone: "warning", time: "Today, 8:00 AM" },
        { id: "sn2", title: "Breathing reset available", body: "Try a 3-minute calm routine before bed tonight.", tone: "info", time: "Yesterday evening" },
      ],
      achievements: [
        { id: "a1", title: "3-week reflection streak", status: "earned" },
        { id: "a2", title: "Sleep reset starter", status: "earned" },
        { id: "a3", title: "Morning energy builder", status: "locked" },
      ],
      games: [
        { id: "game-1", title: "Emotion Explorer", duration: "4 min", status: "Resume" },
        { id: "game-2", title: "Friendship Choices", duration: "5 min", status: "Ready" },
        { id: "game-3", title: "Calm Breathing", duration: "3 min", status: "Completed" },
      ],
    },
    parent: {
      summary: {
        headline: "Zoya is showing recurring sleep difficulty and lower morning energy, with stress staying moderate.",
        sleepTrend: 5,
        moodTrend: 3,
        guideTheme: "Supporting sleep routines without adding pressure",
      },
      linkedStudents: [{ id: "child-1", name: "Zoya R.", summaryStatus: "Available", focusTheme: "Sleep consistency needs support" }],
      notifications: [
        { id: "pn1", title: "Weekly summary available", body: "Sleep consistency remains the clearest support opportunity.", tone: "warning", time: "Today" },
        { id: "pn2", title: "Guide recommended", body: "Review the evening routine conversation guide.", tone: "info", time: "Today" },
      ],
    },
    teacher: {
      classTrends: [
        { theme: "Sleep", score: 54 },
        { theme: "Stress", score: 61 },
        { theme: "Energy", score: 48 },
        { theme: "Help seeking", score: 44 },
      ],
      referrals: [
        { id: "r1", studentCode: "GF-11-A-24", status: "Monitoring", submitted: "Today, 10:05 AM" },
        { id: "r2", studentCode: "GF-10-C-03", status: "In review", submitted: "This week" },
      ],
      pastoralNotes: [
        { id: "p1", title: "Low morning energy and reduced participation", status: "Submitted" },
        { id: "p2", title: "Sleep-related concern logged for follow-up", status: "Draft" },
      ],
    },
    baha: {
      operator: { name: "Dr. Kavya Rao", role: "Clinical Reviewer", queueCount: 14 },
      queue: [
        { id: "case-201", studentCode: "GF-11-A-24", severity: "Medium", status: "Assigned", source: "Sleep trend threshold" },
        { id: "case-202", studentCode: "GF-10-C-03", severity: "High", status: "Review now", source: "Repeated low-energy pattern" },
        { id: "case-203", studentCode: "LM-09-B-11", severity: "Monitoring", status: "Follow-up planned", source: "Parent concern" },
      ],
      caseTimeline: [
        { time: "08:45", event: "Sleep-risk threshold triggered" },
        { time: "09:00", event: "Case grouped with prior low-energy trend" },
        { time: "09:14", event: "Reviewer opened protocol guidance" },
        { time: "09:31", event: "Family communication review queued" },
      ],
      notifications: [
        { id: "bn1", title: "Sleep-risk case requires follow-up", body: "One student has repeated low-sleep indicators.", tone: "warning", time: "Now" },
        { id: "bn2", title: "Night routine content performing well", body: "Sleep module completion is above cohort average.", tone: "info", time: "Today" },
      ],
    },
  },
};

export function getScenarioById(id: null | string) {
  return demoScenarios.find((scenario) => scenario.id === id) ?? null;
}

export function getPersonaById(id: DemoPersonaId) {
  return demoPersonas.find((persona) => persona.id === id) ?? demoPersonas[1];
}

export function applyPersonaOverlay<T>(role: string, baseData: T, personaId: DemoPersonaId, ageGroup: string, demoMode: "baseline" | "seeded") {
  const clone = JSON.parse(JSON.stringify(baseData ?? {}));
  const normalizedRole = role === "counselor" ? "baha" : role;

  if (normalizedRole === "student" && clone.profile) {
    clone.profile.ageGroup = ageGroup;
  }

  if (demoMode === "baseline") {
    return clone as T;
  }

  const overlay = personaRoleOverrides[personaId]?.[normalizedRole];
  if (!overlay) {
    return clone as T;
  }

  return deepMerge(clone, overlay) as T;
}

export function getStakeholderNote(screen: ScreenMeta) {
  const lower = screen.name.toLowerCase();

  let whyExists = `This screen exists to support the ${screen.roleLabel.toLowerCase()} ${screen.pattern.toLowerCase()} workflow while keeping the documented ${screen.layout.toLowerCase()} intact.`;
  let userGoal = `Help the user move confidently through ${screen.name} and into ${screen.nextRoute.split("/").pop()?.replaceAll("_", " ") ?? "the next documented step"}.`;
  let privacy = `This route follows ${screen.permission.toLowerCase()} boundaries and should only reveal information appropriate to the current role and consent posture.`;
  let clinical = "The experience should stay supportive, non-diagnostic, and clear about when human review or escalation is appropriate.";

  if (lower.includes("check-in") || lower.includes("trend") || lower.includes("mood")) {
    whyExists = "This screen exists to capture or explain wellbeing signals in a way that feels lightweight, reflective, and safe for adolescents.";
    userGoal = "Help the user notice patterns, complete reflection tasks, and understand what happens next.";
    privacy = "Only the minimum trend information needed for the current workflow should be shown, especially when summaries may later be shared with guardians or staff.";
    clinical = "Trend presentation should avoid over-pathologizing normal variation while still surfacing sustained risk patterns for review.";
  } else if (lower.includes("chat") || lower.includes("buddy") || lower.includes("safe questions")) {
    whyExists = "This screen exists to provide supportive conversational guidance while staying inside the documented safe-response boundaries.";
    userGoal = "Help the user ask a question, receive grounded support, and understand when a human handoff is needed.";
    privacy = "Conversation history should stay scoped to approved consent settings and avoid exposing sensitive details outside the immediate support context.";
    clinical = "Responses should remain bounded, evidence-aligned, and clear about the limits of automated support.";
  } else if (lower.includes("learning") || lower.includes("module") || lower.includes("lesson") || lower.includes("quiz")) {
    whyExists = "This screen exists to turn wellbeing education into a guided, measurable learning journey.";
    userGoal = "Help the user continue a module, absorb the content, and reflect on a practical next step.";
    privacy = "Learning progress should feel personal and motivating without exposing sensitive wellbeing signals beyond the current role's permissions.";
    clinical = "Content should reinforce healthy coping strategies and avoid framing learning completion as a proxy for clinical improvement.";
  } else if (lower.includes("game") || lower.includes("breathing") || lower.includes("friendship") || lower.includes("emotion explorer")) {
    whyExists = "This screen exists to provide a playful regulation moment that supports emotional learning and retention.";
    userGoal = "Help the user quickly enter an activity, stay engaged, and leave with a felt sense of progress.";
    privacy = "Game progress and achievements should remain motivational and should not disclose sensitive emotional states beyond the user's consent boundaries.";
    clinical = "Activities should regulate and educate, not gamify risk, distress, or crisis behavior.";
  } else if (lower.includes("consent") || lower.includes("privacy") || lower.includes("data rights")) {
    whyExists = "This screen exists to make trust, consent, and data boundaries understandable before or during continued product use.";
    userGoal = "Help the user understand what is shared, what stays private, and which choices they can still change.";
    privacy = "This is a high-sensitivity route: language should be plain, reversible where appropriate, and aligned to age and role-specific permissions.";
    clinical = "Consent flows should support informed participation without pressuring the user during vulnerable moments.";
  } else if (lower.includes("queue") || lower.includes("case") || lower.includes("referral") || lower.includes("assignment") || lower.includes("protocol") || lower.includes("audit")) {
    whyExists = "This screen exists to support structured operational review, triage, and accountable follow-through on wellbeing concerns.";
    userGoal = "Help the reviewer quickly understand the case state, choose the next documented action, and preserve a clear audit trail.";
    privacy = "Operational routes should surface only role-appropriate details, avoid unnecessary identifiers, and maintain least-privilege visibility.";
    clinical = "Escalation views should make urgency, documentation quality, and safe human intervention easy to understand at a glance.";
  } else if (lower.includes("summary") || lower.includes("dashboard") || lower.includes("notification") || lower.includes("home")) {
    whyExists = "This screen exists to orient the user with concise signals, recommendations, and the most relevant next actions.";
    userGoal = "Help the user quickly understand the current state of their experience and choose a clear next step.";
    privacy = "Summaries should abstract sensitive signals responsibly, especially when they are visible to guardians, staff, or operators.";
    clinical = "Dashboards should guide attention without turning wellbeing information into an alarmist or diagnostic artifact.";
  }

  return {
    whyExists,
    userGoal,
    prdReference: `${screen.roleLabel} · ${screen.pattern} · ${screen.name}`,
    privacy,
    clinical,
  };
}

function deepMerge(target: Record<string, unknown>, source: Record<string, unknown>) {
  const merged = { ...target };

  Object.entries(source).forEach(([key, value]) => {
    const current = merged[key];
    if (Array.isArray(value)) {
      merged[key] = value;
      return;
    }
    if (isObject(value) && isObject(current)) {
      merged[key] = deepMerge(current, value);
      return;
    }
    merged[key] = value;
  });

  return merged;
}

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
