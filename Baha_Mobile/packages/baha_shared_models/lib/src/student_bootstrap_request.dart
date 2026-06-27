class StudentBootstrapRequest {
  const StudentBootstrapRequest({
    required this.displayName,
    required this.schoolName,
    required this.ageCohort,
    required this.legalConsentBand,
    this.email,
    this.gender = 'unspecified',
    this.preferredLanguage = 'en',
  });

  final String displayName;
  final String schoolName;
  final String ageCohort;
  final String legalConsentBand;
  final String? email;
  final String gender;
  final String preferredLanguage;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'role': 'student',
      'display_name': displayName,
      'email': email,
      'preferred_language': preferredLanguage,
      'school_name': schoolName,
      'age_cohort': ageCohort,
      'legal_consent_band': legalConsentBand,
      'gender': gender,
    };
  }
}
