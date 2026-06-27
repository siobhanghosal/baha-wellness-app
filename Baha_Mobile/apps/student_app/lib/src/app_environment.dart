class StudentAppEnvironment {
  const StudentAppEnvironment({
    required this.apiBaseUrl,
    required this.defaultExternalAuthId,
    required this.defaultAuthEmail,
  });

  final String apiBaseUrl;
  final String defaultExternalAuthId;
  final String defaultAuthEmail;

  factory StudentAppEnvironment.fromDefines() {
    return const StudentAppEnvironment(
      apiBaseUrl: String.fromEnvironment(
        'BAHA_API_BASE_URL',
        defaultValue: 'http://10.0.2.2:8000',
      ),
      defaultExternalAuthId: String.fromEnvironment(
        'BAHA_DEV_EXTERNAL_AUTH_ID',
        defaultValue: '',
      ),
      defaultAuthEmail: String.fromEnvironment(
        'BAHA_DEV_AUTH_EMAIL',
        defaultValue: '',
      ),
    );
  }
}
