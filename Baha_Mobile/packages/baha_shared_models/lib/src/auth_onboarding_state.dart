class AuthOnboardingState {
  const AuthOnboardingState({
    required this.hasBahaUser,
    required this.identityMatchMode,
    required this.externalAuthId,
    required this.roles,
    required this.approvalStatus,
    required this.consentStatus,
    required this.guardianLinkStatus,
    required this.linkedStudentCount,
    required this.linkedGuardianCount,
    required this.nextStep,
    this.userId,
    this.email,
    this.displayName,
    this.accountStatus,
    this.primaryRole,
    this.schoolId,
    this.studentProfileId,
    this.guardianId,
    this.teacherProfileId,
    this.studentCode,
    this.guardianLinkVerificationCode,
    this.ageCohort,
    this.legalConsentBand,
    this.detail,
  });

  final bool hasBahaUser;
  final String identityMatchMode;
  final String externalAuthId;
  final String? userId;
  final String? email;
  final String? displayName;
  final String? accountStatus;
  final List<String> roles;
  final String? primaryRole;
  final String? schoolId;
  final String? studentProfileId;
  final String? guardianId;
  final String? teacherProfileId;
  final String? studentCode;
  final String? guardianLinkVerificationCode;
  final String? ageCohort;
  final String? legalConsentBand;
  final String approvalStatus;
  final String consentStatus;
  final String guardianLinkStatus;
  final int linkedStudentCount;
  final int linkedGuardianCount;
  final String nextStep;
  final String? detail;

  bool get isReady => nextStep == 'ready';

  bool get requiresBootstrap =>
      nextStep == 'bootstrap' || nextStep == 'complete_profile';

  bool get requiresAttention => !isReady && !requiresBootstrap;

  factory AuthOnboardingState.fromJson(Map<String, dynamic> json) {
    return AuthOnboardingState(
      hasBahaUser: json['has_baha_user'] as bool? ?? false,
      identityMatchMode: json['identity_match_mode'] as String? ?? 'none',
      externalAuthId: json['external_auth_id'] as String? ?? '',
      userId: json['user_id'] as String?,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      accountStatus: json['account_status'] as String?,
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      primaryRole: json['primary_role'] as String?,
      schoolId: json['school_id'] as String?,
      studentProfileId: json['student_profile_id'] as String?,
      guardianId: json['guardian_id'] as String?,
      teacherProfileId: json['teacher_profile_id'] as String?,
      studentCode: json['student_code'] as String?,
      guardianLinkVerificationCode:
          json['guardian_link_verification_code'] as String?,
      ageCohort: json['age_cohort'] as String?,
      legalConsentBand: json['legal_consent_band'] as String?,
      approvalStatus: json['approval_status'] as String? ?? 'not_required',
      consentStatus: json['consent_status'] as String? ?? 'not_required',
      guardianLinkStatus:
          json['guardian_link_status'] as String? ?? 'not_required',
      linkedStudentCount: (json['linked_student_count'] as num?)?.toInt() ?? 0,
      linkedGuardianCount:
          (json['linked_guardian_count'] as num?)?.toInt() ?? 0,
      nextStep: json['next_step'] as String? ?? 'bootstrap',
      detail: json['detail'] as String?,
    );
  }
}
