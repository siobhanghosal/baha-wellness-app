typedef BootstrapMetadata = Map<String, dynamic>;

enum AppRequestedRole {
  student('student'),
  guardian('guardian'),
  teacher('teacher'),
  counselor('counselor');

  const AppRequestedRole(this.apiValue);

  final String apiValue;

  String get label {
    switch (this) {
      case AppRequestedRole.student:
        return 'Student';
      case AppRequestedRole.guardian:
        return 'Parent or guardian';
      case AppRequestedRole.teacher:
        return 'Teacher';
      case AppRequestedRole.counselor:
        return 'Counselor';
    }
  }

  static AppRequestedRole fromApiValue(String? value) {
    return AppRequestedRole.values.firstWhere(
      (role) => role.apiValue == value,
      orElse: () => AppRequestedRole.student,
    );
  }
}

class AppBootstrapRequest {
  const AppBootstrapRequest({
    required this.role,
    required this.displayName,
    this.email,
    this.phone,
    this.preferredLanguage = 'en',
    this.schoolId,
    this.schoolName,
    this.ageCohort,
    this.legalConsentBand,
    this.gender = 'unspecified',
    this.guardianType = 'parent',
    this.staffCode,
    this.metadata = const {},
  });

  final AppRequestedRole role;
  final String displayName;
  final String? email;
  final String? phone;
  final String preferredLanguage;
  final String? schoolId;
  final String? schoolName;
  final String? ageCohort;
  final String? legalConsentBand;
  final String gender;
  final String guardianType;
  final String? staffCode;
  final BootstrapMetadata metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'role': role.apiValue,
      'display_name': displayName,
      'email': email,
      'phone': phone,
      'preferred_language': preferredLanguage,
      'school_id': schoolId,
      'school_name': schoolName,
      'age_cohort': ageCohort,
      'legal_consent_band': legalConsentBand,
      'gender': gender,
      'guardian_type': guardianType,
      'staff_code': staffCode,
      'metadata': metadata,
    };
  }
}

class StudentBootstrapRequest extends AppBootstrapRequest {
  const StudentBootstrapRequest({
    required super.displayName,
    required String schoolName,
    required String ageCohort,
    required String legalConsentBand,
    super.email,
    super.gender = 'unspecified',
    super.preferredLanguage = 'en',
    super.metadata = const {},
  }) : super(
         role: AppRequestedRole.student,
         schoolName: schoolName,
         ageCohort: ageCohort,
         legalConsentBand: legalConsentBand,
       );
}
