class MobileActor {
  const MobileActor({
    required this.userId,
    required this.displayName,
    required this.roles,
    required this.primaryRole,
    required this.appAudience,
    required this.userMetadata,
    required this.studentMetadata,
    this.externalAuthId,
    this.studentProfileId,
    this.guardianId,
    this.teacherProfileId,
    this.ageCohort,
    this.schoolId,
    this.schoolName,
  });

  final String userId;
  final String displayName;
  final List<String> roles;
  final String primaryRole;
  final String appAudience;
  final Map<String, dynamic> userMetadata;
  final Map<String, dynamic> studentMetadata;
  final String? externalAuthId;
  final String? studentProfileId;
  final String? guardianId;
  final String? teacherProfileId;
  final String? ageCohort;
  final String? schoolId;
  final String? schoolName;

  factory MobileActor.fromJson(Map<String, dynamic> json) {
    return MobileActor(
      userId: json['user_id'] as String? ?? '',
      externalAuthId: json['external_auth_id'] as String?,
      displayName: json['display_name'] as String? ?? 'Unknown user',
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      primaryRole: json['primary_role'] as String? ?? 'student',
      appAudience: json['app_audience'] as String? ?? 'student',
      userMetadata: Map<String, dynamic>.from(
        json['user_metadata'] as Map? ?? const {},
      ),
      studentMetadata: Map<String, dynamic>.from(
        json['student_metadata'] as Map? ?? const {},
      ),
      studentProfileId: json['student_profile_id'] as String?,
      guardianId: json['guardian_id'] as String?,
      teacherProfileId: json['teacher_profile_id'] as String?,
      ageCohort: json['age_cohort'] as String?,
      schoolId: json['school_id'] as String?,
      schoolName: json['school_name'] as String?,
    );
  }
}
