class MobileLinkedStudentSummary {
  const MobileLinkedStudentSummary({
    required this.studentProfileId,
    required this.studentName,
    required this.relationshipToStudent,
    required this.isPrimary,
    this.ageCohort,
    this.schoolName,
  });

  final String studentProfileId;
  final String studentName;
  final String? ageCohort;
  final String relationshipToStudent;
  final bool isPrimary;
  final String? schoolName;

  factory MobileLinkedStudentSummary.fromJson(Map<String, dynamic> json) {
    return MobileLinkedStudentSummary(
      studentProfileId: json['student_profile_id'] as String? ?? '',
      studentName: json['student_name'] as String? ?? '',
      ageCohort: json['age_cohort'] as String?,
      relationshipToStudent: json['relationship_to_student'] as String? ?? '',
      isPrimary: json['is_primary'] as bool? ?? false,
      schoolName: json['school_name'] as String?,
    );
  }
}

class ParentAccessSummary {
  const ParentAccessSummary({
    required this.allowed,
    required this.mode,
    required this.visibleTiers,
    this.reason,
  });

  final bool allowed;
  final String mode;
  final List<String> visibleTiers;
  final String? reason;

  factory ParentAccessSummary.fromJson(Map<String, dynamic> json) {
    return ParentAccessSummary(
      allowed: json['allowed'] as bool? ?? false,
      mode: json['mode'] as String? ?? '',
      visibleTiers: (json['visible_tiers'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      reason: json['reason'] as String?,
    );
  }
}

class ParentWeeklySummary {
  const ParentWeeklySummary({
    required this.id,
    required this.studentProfileId,
    required this.guardianId,
    required this.weekStart,
    required this.weekEnd,
    required this.consentStatus,
    required this.visibleTiers,
    required this.summary,
    required this.generatedAt,
    required this.access,
  });

  final String id;
  final String studentProfileId;
  final String guardianId;
  final DateTime weekStart;
  final DateTime weekEnd;
  final String consentStatus;
  final List<String> visibleTiers;
  final Map<String, dynamic> summary;
  final DateTime generatedAt;
  final ParentAccessSummary access;

  factory ParentWeeklySummary.fromJson(Map<String, dynamic> json) {
    return ParentWeeklySummary(
      id: json['id'] as String? ?? '',
      studentProfileId: json['student_profile_id'] as String? ?? '',
      guardianId: json['guardian_id'] as String? ?? '',
      weekStart: _parseDate(json['week_start']) ?? DateTime(1970),
      weekEnd: _parseDate(json['week_end']) ?? DateTime(1970),
      consentStatus: json['consent_status'] as String? ?? '',
      visibleTiers: (json['visible_tiers'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      summary: Map<String, dynamic>.from(json['summary'] as Map? ?? const {}),
      generatedAt:
          _parseDateTime(json['generated_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      access: ParentAccessSummary.fromJson(
        Map<String, dynamic>.from(json['access'] as Map? ?? const {}),
      ),
    );
  }
}

class ParentSummaryConsentStatus {
  const ParentSummaryConsentStatus({
    required this.consentType,
    required this.studentProfileId,
    required this.guardianId,
    required this.status,
    required this.scope,
    this.consentVersionId,
    this.actorRelationship,
    this.grantedAt,
    this.withdrawnAt,
    this.createdAt,
  });

  final String consentType;
  final String? consentVersionId;
  final String studentProfileId;
  final String guardianId;
  final String status;
  final String scope;
  final String? actorRelationship;
  final DateTime? grantedAt;
  final DateTime? withdrawnAt;
  final DateTime? createdAt;

  factory ParentSummaryConsentStatus.fromJson(Map<String, dynamic> json) {
    return ParentSummaryConsentStatus(
      consentType: json['consent_type'] as String? ?? '',
      consentVersionId: json['consent_version_id'] as String?,
      studentProfileId: json['student_profile_id'] as String? ?? '',
      guardianId: json['guardian_id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      scope: json['scope'] as String? ?? '',
      actorRelationship: json['actor_relationship'] as String?,
      grantedAt: _parseDateTime(json['granted_at']),
      withdrawnAt: _parseDateTime(json['withdrawn_at']),
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

class ParentSummaryConsentRequest {
  const ParentSummaryConsentRequest({
    required this.studentProfileId,
    this.status = 'granted',
  });

  final String studentProfileId;
  final String status;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'student_profile_id': studentProfileId,
      'status': status,
    };
  }
}

class PlatformParticipationConsentRequest {
  const PlatformParticipationConsentRequest({
    required this.studentProfileId,
    this.status = 'granted',
  });

  final String studentProfileId;
  final String status;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'student_profile_id': studentProfileId,
      'status': status,
    };
  }
}

DateTime? _parseDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value);
  }
  return null;
}

DateTime? _parseDate(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value);
  }
  return null;
}
