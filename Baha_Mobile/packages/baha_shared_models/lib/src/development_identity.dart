import 'student_bootstrap_request.dart';

class DevelopmentIdentity {
  const DevelopmentIdentity({
    required this.externalAuthId,
    this.authEmail,
    this.requestedRole = AppRequestedRole.student,
  });

  final String externalAuthId;
  final String? authEmail;
  final AppRequestedRole requestedRole;

  bool get isValid => externalAuthId.trim().isNotEmpty;

  Map<String, String> toHeaders() {
    final headers = <String, String>{'X-BAHA-External-Auth-Id': externalAuthId};
    final email = authEmail?.trim();
    if (email != null && email.isNotEmpty) {
      headers['X-BAHA-Auth-Email'] = email;
    }
    return headers;
  }
}
