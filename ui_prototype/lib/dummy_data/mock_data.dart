import 'package:flutter/material.dart';

import '../models/prototype_models.dart';

const studentMetrics = [
  UiMetric(
      label: 'Mood',
      value: .78,
      detail: 'Feeling steady today',
      icon: Icons.sentiment_satisfied_alt_rounded,
      color: Color(0xFF14B8A6)),
  UiMetric(
      label: 'Sleep',
      value: .62,
      detail: '7h 10m last night',
      icon: Icons.bedtime_rounded,
      color: Color(0xFF6366F1)),
  UiMetric(
      label: 'Stress',
      value: .34,
      detail: 'Lower than yesterday',
      icon: Icons.spa_rounded,
      color: Color(0xFFF59E0B)),
  UiMetric(
      label: 'Energy',
      value: .71,
      detail: 'Good focus window',
      icon: Icons.bolt_rounded,
      color: Color(0xFFEF4444)),
];

const studentCards = [
  UiCardItem(
      title: 'Daily Check-in',
      subtitle: 'Mood, sleep, stress, energy, and one gentle reflection.',
      tag: '2 min',
      icon: Icons.favorite_rounded,
      color: Color(0xFF14B8A6)),
  UiCardItem(
      title: 'Emotion Wheel',
      subtitle: 'Find the right word for what you are feeling.',
      tag: 'Private',
      icon: Icons.bubble_chart_rounded,
      color: Color(0xFF8B5CF6)),
  UiCardItem(
      title: 'Calm Breathing',
      subtitle: 'A guided reset with animation and sound-free rhythm.',
      tag: '1 min',
      icon: Icons.air_rounded,
      color: Color(0xFF3B82F6)),
  UiCardItem(
      title: 'Friendship Choices',
      subtitle: 'Practice tricky social moments without pressure.',
      tag: 'Game',
      icon: Icons.diversity_1_rounded,
      color: Color(0xFFF97316)),
  UiCardItem(
      title: 'BAHA Buddy',
      subtitle: 'Ask safe questions with approved guidance.',
      tag: 'Chat',
      icon: Icons.smart_toy_rounded,
      color: Color(0xFFEC4899)),
  UiCardItem(
      title: 'SOS Help',
      subtitle: 'Clear next steps when something feels unsafe.',
      tag: 'Safety',
      icon: Icons.health_and_safety_rounded,
      color: Color(0xFFDC2626)),
];

const parentMetrics = [
  UiMetric(
      label: 'Check-in Rhythm',
      value: .84,
      detail: '5 of 6 weeks completed',
      icon: Icons.insights_rounded,
      color: Color(0xFF2563EB)),
  UiMetric(
      label: 'Sleep Pattern',
      value: .68,
      detail: 'Improving bedtime consistency',
      icon: Icons.nights_stay_rounded,
      color: Color(0xFF7C3AED)),
  UiMetric(
      label: 'Learning',
      value: .45,
      detail: '2 parent guides completed',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF059669)),
];

const teacherMetrics = [
  UiMetric(
      label: 'Class Calm Index',
      value: .72,
      detail: 'Class 9B looks stable this week',
      icon: Icons.groups_rounded,
      color: Color(0xFF0EA5E9)),
  UiMetric(
      label: 'Attendance',
      value: .91,
      detail: 'Slight dip on Fridays',
      icon: Icons.event_available_rounded,
      color: Color(0xFF22C55E)),
  UiMetric(
      label: 'Pastoral Flags',
      value: .28,
      detail: '3 open, 1 high priority',
      icon: Icons.flag_rounded,
      color: Color(0xFFF97316)),
];

const adminMetrics = [
  UiMetric(
      label: 'Active Students',
      value: .82,
      detail: '12,482 active this month',
      icon: Icons.people_alt_rounded,
      color: Color(0xFF38BDF8)),
  UiMetric(
      label: 'Schools',
      value: .64,
      detail: '38 onboarded schools',
      icon: Icons.apartment_rounded,
      color: Color(0xFFA78BFA)),
  UiMetric(
      label: 'Approvals',
      value: .38,
      detail: '21 pending reviews',
      icon: Icons.verified_user_rounded,
      color: Color(0xFFFBBF24)),
  UiMetric(
      label: 'System Health',
      value: .96,
      detail: 'All services green',
      icon: Icons.monitor_heart_rounded,
      color: Color(0xFF34D399)),
];

const roleActions = [
  UiCardItem(
      title: 'Notifications',
      subtitle: 'Review recent updates and reminders.',
      tag: '12 new',
      icon: Icons.notifications_rounded,
      color: Color(0xFFF59E0B)),
  UiCardItem(
      title: 'Calendar',
      subtitle: 'Appointments, activities, and school events.',
      tag: 'Today',
      icon: Icons.calendar_month_rounded,
      color: Color(0xFF3B82F6)),
  UiCardItem(
      title: 'Settings',
      subtitle: 'Profile, privacy, theme, and preferences.',
      tag: 'Edit',
      icon: Icons.settings_rounded,
      color: Color(0xFF64748B)),
  UiCardItem(
      title: 'Support',
      subtitle: 'Contact BAHA, send feedback, or request help.',
      tag: 'Open',
      icon: Icons.support_agent_rounded,
      color: Color(0xFF14B8A6)),
];

const timeline = [
  UiEvent(
      time: '8:20 AM',
      title: 'Morning check-in',
      detail: 'Mood steady, energy rising.',
      color: Color(0xFF14B8A6)),
  UiEvent(
      time: '11:45 AM',
      title: 'Learning module',
      detail: 'Screen-time reset guide opened.',
      color: Color(0xFF6366F1)),
  UiEvent(
      time: '4:10 PM',
      title: 'Breathing activity',
      detail: 'One-minute calm reset completed.',
      color: Color(0xFFF59E0B)),
  UiEvent(
      time: '7:30 PM',
      title: 'Journal prompt',
      detail: 'One private reflection saved.',
      color: Color(0xFFEC4899)),
];

const chatBubbles = [
  ChatBubble(
      sender: 'BAHA Buddy',
      text:
          'Hi, I can help you think through stress, sleep, friendships, or safe next steps.',
      isUser: false),
  ChatBubble(sender: 'You', text: 'I feel nervous before exams.', isUser: true),
  ChatBubble(
      sender: 'BAHA Buddy',
      text:
          'That makes sense. Let us try a 60-second reset and then choose one tiny study action.',
      isUser: false),
];

const learning = [
  UiCardItem(
      title: 'Sleep Reset',
      subtitle: 'Build a wind-down routine that does not feel like punishment.',
      tag: 'Module',
      icon: Icons.bedtime_rounded,
      color: Color(0xFF6366F1)),
  UiCardItem(
      title: 'Digital Wellness',
      subtitle: 'Learn how to make screens less sticky and more intentional.',
      tag: 'Guide',
      icon: Icons.phone_android_rounded,
      color: Color(0xFF0EA5E9)),
  UiCardItem(
      title: 'Peer Pressure',
      subtitle: 'Practice saying no without losing confidence.',
      tag: 'Story',
      icon: Icons.groups_2_rounded,
      color: Color(0xFFEC4899)),
  UiCardItem(
      title: 'Exam Stress',
      subtitle: 'Plan, reset, and ask for help without spiralling.',
      tag: 'Toolkit',
      icon: Icons.edit_note_rounded,
      color: Color(0xFFF97316)),
];
