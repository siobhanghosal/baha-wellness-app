class StudentModuleSummary {
  const StudentModuleSummary({
    required this.id,
    required this.contentItemId,
    required this.moduleCode,
    required this.title,
    required this.theme,
    required this.ageCohort,
    required this.sortOrder,
    required this.progressStatus,
    required this.completionPercent,
    this.estimatedMinutes,
    this.lastActivityAt,
    this.moduleProgressId,
  });

  final String id;
  final String contentItemId;
  final String moduleCode;
  final String title;
  final String theme;
  final String ageCohort;
  final int? estimatedMinutes;
  final int sortOrder;
  final String progressStatus;
  final double completionPercent;
  final DateTime? lastActivityAt;
  final String? moduleProgressId;

  factory StudentModuleSummary.fromJson(Map<String, dynamic> json) {
    return StudentModuleSummary(
      id: json['id'] as String? ?? '',
      contentItemId: json['content_item_id'] as String? ?? '',
      moduleCode: json['module_code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      theme: json['theme'] as String? ?? '',
      ageCohort: json['age_cohort'] as String? ?? '',
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt(),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      progressStatus: json['progress_status'] as String? ?? 'not_started',
      completionPercent: (json['completion_percent'] as num?)?.toDouble() ?? 0,
      lastActivityAt: _parseDateTime(json['last_activity_at']),
      moduleProgressId: json['module_progress_id'] as String?,
    );
  }
}

class ModuleProgressUpsertRequest {
  const ModuleProgressUpsertRequest({
    required this.status,
    required this.completionPercent,
    this.currentSectionOrdinal,
    this.currentStepOrdinal,
  });

  final String status;
  final double completionPercent;
  final int? currentSectionOrdinal;
  final int? currentStepOrdinal;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'status': status,
      'completion_percent': completionPercent,
      'current_section_ordinal': currentSectionOrdinal,
      'current_step_ordinal': currentStepOrdinal,
    };
  }
}

class ModuleProgressUpsertResponse {
  const ModuleProgressUpsertResponse({
    required this.id,
    required this.status,
    required this.completionPercent,
    required this.updatedAt,
    this.currentSectionOrdinal,
    this.currentStepOrdinal,
    this.lastActivityAt,
  });

  final String id;
  final String status;
  final double completionPercent;
  final int? currentSectionOrdinal;
  final int? currentStepOrdinal;
  final DateTime? lastActivityAt;
  final DateTime updatedAt;

  factory ModuleProgressUpsertResponse.fromJson(Map<String, dynamic> json) {
    return ModuleProgressUpsertResponse(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      completionPercent: (json['completion_percent'] as num?)?.toDouble() ?? 0,
      currentSectionOrdinal: (json['current_section_ordinal'] as num?)?.toInt(),
      currentStepOrdinal: (json['current_step_ordinal'] as num?)?.toInt(),
      lastActivityAt: _parseDateTime(json['last_activity_at']),
      updatedAt:
          _parseDateTime(json['updated_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

DateTime? _parseDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value);
  }
  return null;
}
