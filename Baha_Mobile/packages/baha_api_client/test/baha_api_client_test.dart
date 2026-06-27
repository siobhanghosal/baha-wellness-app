import 'package:baha_api_client/baha_api_client.dart';
import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('fetches onboarding state using development headers', () async {
    final client = BahaApiClient(
      baseUrl: 'http://localhost:8000',
      httpClient: MockClient((request) async {
        expect(request.headers['X-BAHA-External-Auth-Id'], 'student-ext-id');
        return http.Response(
          '{"has_baha_user":true,"identity_match_mode":"external_auth_id","external_auth_id":"student-ext-id","roles":["student"],"approval_status":"not_required","consent_status":"pending","guardian_link_status":"pending","linked_student_count":0,"linked_guardian_count":0,"next_step":"await_guardian_consent"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final state = await client.getOnboardingState(
      identity: const DevelopmentIdentity(externalAuthId: 'student-ext-id'),
    );

    expect(state.externalAuthId, 'student-ext-id');
    expect(state.nextStep, 'await_guardian_consent');
  });

  test('fetches weekly summary payload', () async {
    final client = BahaApiClient(
      baseUrl: 'http://localhost:8000',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/mobile/student/weekly-summary/latest');
        return http.Response(
          '{"id":"1","student_profile_id":"2","week_start":"2026-06-19","week_end":"2026-06-25","privacy_tier_applied":"tier1","summary_status":"ready","summary":{"headline":"Steady week overall"},"source_window":{"checkins":1},"generation_version":"demo-v1","generated_at":"2026-06-26T14:42:39.960669Z"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final summary = await client.getStudentWeeklySummary(
      identity: const DevelopmentIdentity(externalAuthId: 'student-ext-id'),
    );

    expect(summary.summary['headline'], 'Steady week overall');
    expect(summary.privacyTierApplied, 'tier1');
  });

  test('fetches student modules with linked content items', () async {
    final client = BahaApiClient(
      baseUrl: 'http://localhost:8000',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/mobile/student/modules');
        return http.Response(
          '[{"id":"62000000-0000-0000-0000-000000000001","content_item_id":"60000000-0000-0000-0000-000000000001","module_code":"STU-SLEEP-001","title":"Sleep Basics for Students","theme":"Sleep","age_cohort":"13_14","estimated_minutes":12,"sort_order":1,"progress_status":"not_started","completion_percent":0.0,"last_activity_at":null,"module_progress_id":null}]',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final modules = await client.listStudentModules(
      identity: const DevelopmentIdentity(externalAuthId: 'student-ext-id'),
    );

    expect(
      modules.single.contentItemId,
      '60000000-0000-0000-0000-000000000001',
    );
    expect(modules.single.title, 'Sleep Basics for Students');
  });

  test('fetches content detail blocks', () async {
    final client = BahaApiClient(
      baseUrl: 'http://localhost:8000',
      httpClient: MockClient((request) async {
        expect(
          request.url.path,
          '/mobile/content/60000000-0000-0000-0000-000000000001',
        );
        return http.Response(
          '{"id":"60000000-0000-0000-0000-000000000001","slug":"demo-student-module-sleep-basics","title":"Sleep Basics for Students","content_type":"learning_module","audience_app":"student","age_cohort":"13_14","theme":"Sleep","summary":"Demo student module for Flutter integration","version_id":"61000000-0000-0000-0000-000000000001","version_number":1,"body":{"blocks":[{"type":"text","value":"Students can build healthier sleep routines."}]},"plain_text":"Students can build healthier sleep routines.","metadata":{"demo":true},"published_at":"2026-06-26T14:42:39.956992Z","reviewed_by":"BAHA Demo Reviewer","reviewed_at":"2026-06-26T14:42:39.956629Z"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final detail = await client.getMobileContentDetail(
      identity: const DevelopmentIdentity(externalAuthId: 'student-ext-id'),
      contentItemId: '60000000-0000-0000-0000-000000000001',
    );

    expect(detail.blocks.single.value, contains('sleep routines'));
  });
}
