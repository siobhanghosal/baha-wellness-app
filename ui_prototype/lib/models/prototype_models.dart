import 'package:flutter/material.dart';

enum AppRole { student, parent, teacher, admin }

enum StudentGender { male, female }

enum StudentAgeGroup { child, teen, youngAdult }

extension AppRoleX on AppRole {
  String get label => switch (this) {
        AppRole.student => 'Student App',
        AppRole.parent => 'Parent App',
        AppRole.teacher => 'Teacher App',
        AppRole.admin => 'BAHA Admin App',
      };

  String get slug => switch (this) {
        AppRole.student => 'student',
        AppRole.parent => 'parent',
        AppRole.teacher => 'teacher',
        AppRole.admin => 'admin',
      };

  IconData get icon => switch (this) {
        AppRole.student => Icons.auto_awesome_rounded,
        AppRole.parent => Icons.family_restroom_rounded,
        AppRole.teacher => Icons.school_rounded,
        AppRole.admin => Icons.admin_panel_settings_rounded,
      };

  String get pitch => switch (this) {
        AppRole.student => 'Check-ins, games, Buddy, learning, and support.',
        AppRole.parent => 'Consent-aware summaries and family guidance.',
        AppRole.teacher => 'Class wellbeing, pastoral actions, and reports.',
        AppRole.admin =>
          'Enterprise oversight, approvals, content, and analytics.',
      };
}

extension StudentGenderX on StudentGender {
  String get label => this == StudentGender.male ? 'Male' : 'Female';
}

extension StudentAgeGroupX on StudentAgeGroup {
  String get label => switch (this) {
        StudentAgeGroup.child => '9-12',
        StudentAgeGroup.teen => '13-16',
        StudentAgeGroup.youngAdult => '17-19',
      };
}

class UiMetric {
  const UiMetric(
      {required this.label,
      required this.value,
      required this.detail,
      required this.icon,
      required this.color});
  final String label;
  final double value;
  final String detail;
  final IconData icon;
  final Color color;
}

class UiCardItem {
  const UiCardItem(
      {required this.title,
      required this.subtitle,
      required this.tag,
      required this.icon,
      required this.color});
  final String title;
  final String subtitle;
  final String tag;
  final IconData icon;
  final Color color;
}

class UiEvent {
  const UiEvent(
      {required this.time,
      required this.title,
      required this.detail,
      required this.color});
  final String time;
  final String title;
  final String detail;
  final Color color;
}

class ChatBubble {
  const ChatBubble(
      {required this.sender, required this.text, required this.isUser});
  final String sender;
  final String text;
  final bool isUser;
}
