import 'package:flutter/material.dart';

import 'prototype_models.dart';

const studentPrimaryCards = [
  UiCardItem(
    title: 'Daily Check-in',
    subtitle:
        'Sleep, mood, stress, energy, body, and connection with smart follow-ups.',
    tag: '2 min',
    icon: Icons.favorite_rounded,
    color: Color(0xFF14B8A6),
  ),
  UiCardItem(
    title: 'BAHA Buddy',
    subtitle: 'Ask safe questions with approved guidance.',
    tag: 'Chat',
    icon: Icons.smart_toy_rounded,
    color: Color(0xFFEC4899),
  ),
  UiCardItem(
    title: 'SOS Help',
    subtitle: 'Clear next steps when something feels unsafe.',
    tag: 'Safety',
    icon: Icons.health_and_safety_rounded,
    color: Color(0xFFDC2626),
  ),
];

const activityCards = [
  UiCardItem(
    title: 'Comet Sequence',
    subtitle: 'Watch the pattern, remember it, and repeat it before it fades.',
    tag: 'Memory',
    icon: Icons.auto_awesome_rounded,
    color: Color(0xFF8B5CF6),
  ),
  UiCardItem(
    title: 'Calm Breathing',
    subtitle: 'A guided reset with animation and sound-free rhythm.',
    tag: '1 min',
    icon: Icons.air_rounded,
    color: Color(0xFF3B82F6),
  ),
  UiCardItem(
    title: 'Focus Catch',
    subtitle: 'Track the moving comet and tap fast before it jumps away.',
    tag: 'Reflex',
    icon: Icons.ads_click_rounded,
    color: Color(0xFFF97316),
  ),
  UiCardItem(
    title: 'Story World',
    subtitle: 'A guided story game where every reply changes the next scene.',
    tag: 'Live',
    icon: Icons.explore_rounded,
    color: Color(0xFF06B6D4),
  ),
];

const learningCards = [
  UiCardItem(
    title: 'Sleep Reset',
    subtitle: 'Build a wind-down routine that does not feel like punishment.',
    tag: 'Module',
    icon: Icons.bedtime_rounded,
    color: Color(0xFF6366F1),
  ),
  UiCardItem(
    title: 'Digital Wellness',
    subtitle: 'Learn how to make screens less sticky and more intentional.',
    tag: 'Guide',
    icon: Icons.phone_android_rounded,
    color: Color(0xFF0EA5E9),
  ),
  UiCardItem(
    title: 'Peer Pressure',
    subtitle: 'Practice saying no without losing confidence.',
    tag: 'Story',
    icon: Icons.groups_2_rounded,
    color: Color(0xFFEC4899),
  ),
  UiCardItem(
    title: 'Exam Stress',
    subtitle: 'Plan, reset, and ask for help without spiralling.',
    tag: 'Toolkit',
    icon: Icons.edit_note_rounded,
    color: Color(0xFFF97316),
  ),
];

const studentCards = [
  ...studentPrimaryCards,
  ...activityCards,
];

const learning = learningCards;

const roleActions = [
  UiCardItem(
    title: 'Notifications',
    subtitle: 'Review recent updates and reminders.',
    tag: '12 new',
    icon: Icons.notifications_rounded,
    color: Color(0xFFF59E0B),
  ),
  UiCardItem(
    title: 'Calendar',
    subtitle: 'Appointments, activities, and school events.',
    tag: 'Today',
    icon: Icons.calendar_month_rounded,
    color: Color(0xFF3B82F6),
  ),
  UiCardItem(
    title: 'Settings',
    subtitle: 'Profile, privacy, theme, and preferences.',
    tag: 'Edit',
    icon: Icons.settings_rounded,
    color: Color(0xFF64748B),
  ),
  UiCardItem(
    title: 'Support',
    subtitle: 'Contact BAHA, send feedback, or request help.',
    tag: 'Open',
    icon: Icons.support_agent_rounded,
    color: Color(0xFF14B8A6),
  ),
];

const chatBubbles = [
  ChatBubble(
    sender: 'BAHA Buddy',
    text:
        'Hi, I can help you think through stress, sleep, friendships, or safe next steps.',
    isUser: false,
  ),
  ChatBubble(sender: 'You', text: 'I feel nervous before exams.', isUser: true),
  ChatBubble(
    sender: 'BAHA Buddy',
    text:
        'That makes sense. Let us try a 60-second reset and then choose one tiny study action.',
    isUser: false,
  ),
];
