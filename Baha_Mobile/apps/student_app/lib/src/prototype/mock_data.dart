import 'package:flutter/material.dart';

import 'prototype_models.dart';

const studentPrimaryCards = [
  UiCardItem(
    title: 'Daily Check-in',
    subtitle:
        'Sleep, mood, stress, energy, physical symptoms, and support with smart follow-ups.',
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
    title: 'Journal',
    subtitle:
        'Write freely, use a guided prompt, and keep private notes you can revisit later.',
    tag: 'Reflect',
    icon: Icons.menu_book_rounded,
    color: Color(0xFF0F766E),
  ),
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
];

const age13To14LearningCards = [
  UiCardItem(
    title: 'Sleep Reset',
    subtitle:
        'Build a calmer night routine that helps school, mood, and energy.',
    tag: 'Path',
    icon: Icons.bedtime_rounded,
    color: Color(0xFF6366F1),
  ),
  UiCardItem(
    title: 'Stress Reset',
    subtitle: 'Notice stress earlier and build a simple calm plan that works.',
    tag: 'Path',
    icon: Icons.self_improvement_rounded,
    color: Color(0xFF14B8A6),
  ),
  UiCardItem(
    title: 'Bullying and Boundaries',
    subtitle: 'Know what repeated harm looks like and how to get help safely.',
    tag: 'Path',
    icon: Icons.shield_rounded,
    color: Color(0xFFEC4899),
  ),
  UiCardItem(
    title: 'Healthy Gaming',
    subtitle: 'Keep games fun without letting them crowd out sleep or school.',
    tag: 'Path',
    icon: Icons.sports_esports_rounded,
    color: Color(0xFF0EA5E9),
  ),
  UiCardItem(
    title: 'Alcohol Safety',
    subtitle:
        'Practice confident, safe choices and know when to get help fast.',
    tag: 'Path',
    icon: Icons.no_drinks_rounded,
    color: Color(0xFFF97316),
  ),
];

const age15To18LearningCards = [
  UiCardItem(
    title: 'Sleep and Recovery',
    subtitle:
        'Protect rest so energy, focus, and decision-making stay steadier.',
    tag: 'Path',
    icon: Icons.bedtime_rounded,
    color: Color(0xFF6366F1),
  ),
  UiCardItem(
    title: 'Handling Stress',
    subtitle: 'Break pressure into smaller steps and use calm support earlier.',
    tag: 'Path',
    icon: Icons.self_improvement_rounded,
    color: Color(0xFF14B8A6),
  ),
  UiCardItem(
    title: 'Bullying and Boundaries',
    subtitle:
        'Protect yourself, back others safely, and escalate repeated harm.',
    tag: 'Path',
    icon: Icons.shield_rounded,
    color: Color(0xFFEC4899),
  ),
  UiCardItem(
    title: 'Healthy Gaming',
    subtitle: 'Keep gaming balanced with study, relationships, and sleep.',
    tag: 'Path',
    icon: Icons.sports_esports_rounded,
    color: Color(0xFF0EA5E9),
  ),
  UiCardItem(
    title: 'Alcohol Safety',
    subtitle: 'Think ahead about pressure, risky settings, and safe ways out.',
    tag: 'Path',
    icon: Icons.no_drinks_rounded,
    color: Color(0xFFF97316),
  ),
];

const age18PlusLearningCards = [
  UiCardItem(
    title: 'Sleep and Recovery',
    subtitle: 'Use sleep as a foundation for focus, mood, and resilience.',
    tag: 'Path',
    icon: Icons.bedtime_rounded,
    color: Color(0xFF6366F1),
  ),
  UiCardItem(
    title: 'Stress Under Pressure',
    subtitle: 'Manage heavy weeks without letting pressure run the whole day.',
    tag: 'Path',
    icon: Icons.self_improvement_rounded,
    color: Color(0xFF14B8A6),
  ),
  UiCardItem(
    title: 'Bullying and Boundaries',
    subtitle:
        'Respond to repeated harm clearly, safely, and without isolation.',
    tag: 'Path',
    icon: Icons.shield_rounded,
    color: Color(0xFFEC4899),
  ),
  UiCardItem(
    title: 'Healthy Gaming',
    subtitle:
        'Keep digital habits aligned with goals, work, study, and health.',
    tag: 'Path',
    icon: Icons.sports_esports_rounded,
    color: Color(0xFF0EA5E9),
  ),
  UiCardItem(
    title: 'Alcohol Safety',
    subtitle:
        'Handle independence, peer pressure, and risky choices more safely.',
    tag: 'Path',
    icon: Icons.no_drinks_rounded,
    color: Color(0xFFF97316),
  ),
];

const age9To12LearningCards = [
  UiCardItem(
    title: 'Sleep and Recharge',
    subtitle: 'Build a bedtime routine that helps your body and brain rest.',
    tag: 'Path',
    icon: Icons.bedtime_rounded,
    color: Color(0xFF6366F1),
  ),
  UiCardItem(
    title: 'Calm Through Stress',
    subtitle: 'Learn what stress feels like and build your calm toolbox.',
    tag: 'Path',
    icon: Icons.self_improvement_rounded,
    color: Color(0xFF14B8A6),
  ),
  UiCardItem(
    title: 'Bullying and Kindness',
    subtitle: 'Know what bullying looks like and how to get help safely.',
    tag: 'Path',
    icon: Icons.shield_rounded,
    color: Color(0xFFEC4899),
  ),
  UiCardItem(
    title: 'Healthy Gaming',
    subtitle: 'Keep games fun while protecting sleep, homework, and balance.',
    tag: 'Path',
    icon: Icons.sports_esports_rounded,
    color: Color(0xFF0EA5E9),
  ),
  UiCardItem(
    title: 'Alcohol Safety',
    subtitle:
        'Practice safe choices and know what to do if something feels wrong.',
    tag: 'Path',
    icon: Icons.no_drinks_rounded,
    color: Color(0xFFF97316),
  ),
];

const studentCards = [...studentPrimaryCards, ...activityCards];

const learning = age15To18LearningCards;

List<UiCardItem> learningCardsForAgeBand(String? ageBand) {
  if (ageBand == '9_12') {
    return age9To12LearningCards;
  }
  if (ageBand == '13_14') {
    return age13To14LearningCards;
  }
  if (ageBand == '18_plus') {
    return age18PlusLearningCards;
  }
  return age15To18LearningCards;
}

const roleActions = [
  UiCardItem(
    title: 'Notifications',
    subtitle: 'Review recent updates and reminders.',
    tag: '12 new',
    icon: Icons.notifications_rounded,
    color: Color(0xFFF59E0B),
  ),
  UiCardItem(
    title: 'Your Week',
    subtitle:
        'See simple scores, trends, and next steps from recent check-ins.',
    tag: 'Progress',
    icon: Icons.insights_rounded,
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
