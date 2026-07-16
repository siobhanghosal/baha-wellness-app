class LinkedGuardianSummary {
  const LinkedGuardianSummary({
    required this.guardianId,
    required this.displayName,
    this.guardianUserId,
    this.relationshipToStudent,
    this.isPrimary = false,
  });

  final String guardianId;
  final String displayName;
  final String? guardianUserId;
  final String? relationshipToStudent;
  final bool isPrimary;

  factory LinkedGuardianSummary.fromJson(Map<String, dynamic> json) {
    return LinkedGuardianSummary(
      guardianId: json['guardian_id'] as String? ?? '',
      guardianUserId: json['guardian_user_id'] as String?,
      displayName: json['display_name'] as String? ?? 'Parent or guardian',
      relationshipToStudent: json['relationship_to_student'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }
}

class StudentLinkingState {
  const StudentLinkingState({
    required this.studentProfileId,
    required this.studentCode,
    required this.linkedGuardianCount,
    required this.linkedGuardians,
    required this.parentSummarySharingEnabled,
    this.legalConsentBand,
    this.guardianLinkVerificationCode,
    this.guardianLinkCodeGeneratedAt,
    this.guardianLinkCodeExpiresAt,
    this.updatedAt,
  });

  final String studentProfileId;
  final String studentCode;
  final String? legalConsentBand;
  final int linkedGuardianCount;
  final List<LinkedGuardianSummary> linkedGuardians;
  final String? guardianLinkVerificationCode;
  final DateTime? guardianLinkCodeGeneratedAt;
  final DateTime? guardianLinkCodeExpiresAt;
  final bool parentSummarySharingEnabled;
  final DateTime? updatedAt;

  factory StudentLinkingState.fromJson(Map<String, dynamic> json) {
    return StudentLinkingState(
      studentProfileId: json['student_profile_id'] as String? ?? '',
      studentCode: json['student_code'] as String? ?? '',
      legalConsentBand: json['legal_consent_band'] as String?,
      linkedGuardianCount:
          (json['linked_guardian_count'] as num?)?.toInt() ?? 0,
      linkedGuardians:
          (json['linked_guardians'] as List<dynamic>? ?? const [])
              .map(
                (item) => LinkedGuardianSummary.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(),
      guardianLinkVerificationCode:
          json['guardian_link_verification_code'] as String?,
      guardianLinkCodeGeneratedAt: _parseDateTime(
        json['guardian_link_code_generated_at'],
      ),
      guardianLinkCodeExpiresAt: _parseDateTime(
        json['guardian_link_code_expires_at'],
      ),
      parentSummarySharingEnabled:
          json['parent_summary_sharing_enabled'] as bool? ?? false,
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }
}

class StudentParentSummarySharingRequest {
  const StudentParentSummarySharingRequest({required this.enabled});

  final bool enabled;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'enabled': enabled};
  }
}

DateTime? _parseDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value);
  }
  return null;
}
