class StudentWeeklySummary {
  const StudentWeeklySummary({
    required this.id,
    required this.studentProfileId,
    required this.weekStart,
    required this.weekEnd,
    required this.privacyTierApplied,
    required this.summaryStatus,
    required this.summary,
    required this.sourceWindow,
    required this.generationVersion,
    required this.generatedAt,
  });

  final String id;
  final String studentProfileId;
  final DateTime weekStart;
  final DateTime weekEnd;
  final String privacyTierApplied;
  final String summaryStatus;
  final Map<String, dynamic> summary;
  final Map<String, dynamic> sourceWindow;
  final String generationVersion;
  final DateTime generatedAt;

  factory StudentWeeklySummary.fromJson(Map<String, dynamic> json) {
    return StudentWeeklySummary(
      id: json['id'] as String? ?? '',
      studentProfileId: json['student_profile_id'] as String? ?? '',
      weekStart: DateTime.parse(json['week_start'] as String),
      weekEnd: DateTime.parse(json['week_end'] as String),
      privacyTierApplied: json['privacy_tier_applied'] as String? ?? '',
      summaryStatus: json['summary_status'] as String? ?? '',
      summary: Map<String, dynamic>.from(json['summary'] as Map? ?? const {}),
      sourceWindow: Map<String, dynamic>.from(json['source_window'] as Map? ?? const {}),
      generationVersion: json['generation_version'] as String? ?? '',
      generatedAt: DateTime.parse(json['generated_at'] as String),
    );
  }
}
