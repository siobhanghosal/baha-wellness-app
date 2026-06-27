import 'package:baha_api_client/baha_api_client.dart';
import 'package:baha_auth_session/baha_auth_session.dart';
import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('restoreSession requires identity when no saved prefs exist', () async {
    SharedPreferences.setMockInitialValues(const {});
    final controller = AppSessionController(
      apiClient: BahaApiClient(
        baseUrl: 'http://localhost:8000',
        httpClient: MockClient((request) async {
          return http.Response('{}', 500);
        }),
      ),
    );

    await controller.restoreSession();

    expect(controller.stage, SessionStage.requiresIdentity);
    expect(controller.identity, isNull);
  });

  test('saveIdentity persists session and resolves ready state', () async {
    SharedPreferences.setMockInitialValues(const {});
    final client = BahaApiClient(
      baseUrl: 'http://localhost:8000',
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/auth/onboarding-state')) {
          return http.Response(
            '{"has_baha_user":true,"identity_match_mode":"external_auth_id","external_auth_id":"student-ext-id","roles":["student"],"approval_status":"not_required","consent_status":"granted","guardian_link_status":"linked","linked_student_count":0,"linked_guardian_count":1,"next_step":"ready"}',
            200,
          );
        }
        return http.Response(
          '{"user_id":"123","external_auth_id":"student-ext-id","display_name":"Student Demo","roles":["student"],"primary_role":"student","app_audience":"student"}',
          200,
        );
      }),
    );
    final controller = AppSessionController(apiClient: client);

    await controller.saveIdentity(
      const DevelopmentIdentity(externalAuthId: 'student-ext-id'),
    );

    expect(controller.stage, SessionStage.ready);
    expect(controller.actor?.displayName, 'Student Demo');
  });
}
