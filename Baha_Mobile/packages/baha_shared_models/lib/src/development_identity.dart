import 'student_bootstrap_request.dart';

class DevelopmentIdentity {
  const DevelopmentIdentity({
    required this.externalAuthId,
    this.password,
    this.requestedRole = AppRequestedRole.student,
  });

  final String externalAuthId;
  final String? password;
  final AppRequestedRole requestedRole;

  bool get isValid =>
      externalAuthId.trim().isNotEmpty &&
      (password?.trim().isNotEmpty ?? false);

  Map<String, String> toHeaders() {
    final headers = <String, String>{'X-BAHA-External-Auth-Id': externalAuthId};
    final trimmedPassword = password?.trim();
    if (trimmedPassword != null && trimmedPassword.isNotEmpty) {
      headers['X-BAHA-Dev-Password'] = trimmedPassword;
    }
    return headers;
  }
}
