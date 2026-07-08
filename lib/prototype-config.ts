export const roleSwitcher = [
  {
    "id": "student",
    "label": "Student",
    "description": "Adolescent wellness companion"
  },
  {
    "id": "parent",
    "label": "Parent",
    "description": "Consent and weekly summaries"
  },
  {
    "id": "teacher",
    "label": "Teacher",
    "description": "Class trends and referrals"
  },
  {
    "id": "baha",
    "label": "Counselor / BAHA",
    "description": "Operations, queues, and analytics"
  }
] as const;
        export const topNav = {
  "student": [
    {
      "label": "Home",
      "route": "/student/home_dashboard"
    },
    {
      "label": "Buddy",
      "route": "/student/buddy_chat"
    },
    {
      "label": "Learn",
      "route": "/student/learning_home"
    },
    {
      "label": "Games",
      "route": "/student/games_hub"
    },
    {
      "label": "Profile",
      "route": "/student/profile_summary"
    }
  ],
  "parent": [
    {
      "label": "Summary",
      "route": "/parent/weekly_summary_home"
    },
    {
      "label": "Guides",
      "route": "/parent/conversation_guide_detail"
    },
    {
      "label": "Learn",
      "route": "/parent/parent_learning_home"
    },
    {
      "label": "Settings",
      "route": "/parent/notification_settings"
    }
  ],
  "teacher": [
    {
      "label": "Dashboard",
      "route": "/teacher/class_trends_dashboard"
    },
    {
      "label": "Referrals",
      "route": "/teacher/referral_queue"
    },
    {
      "label": "Learn",
      "route": "/teacher/teacher_learning_home"
    },
    {
      "label": "Settings",
      "route": "/teacher/settings"
    }
  ],
  "baha": [
    {
      "label": "Queue",
      "route": "/baha/support_queue"
    },
    {
      "label": "Content",
      "route": "/baha/content_library"
    },
    {
      "label": "Analytics",
      "route": "/baha/pilot_analytics_dashboard"
    },
    {
      "label": "Audit",
      "route": "/baha/audit_log"
    },
    {
      "label": "Settings",
      "route": "/baha/operational_settings"
    }
  ]
} as const;
        export const defaultRoutes = {
  "student": "/student/splash",
  "parent": "/parent/splash",
  "teacher": "/teacher/splash",
  "baha": "/baha/splash",
  "counselor": "/baha/splash"
} as const;
