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
        expect(request.url.queryParameters['theme'], 'Sleep');
        return http.Response(
          '[{"id":"62000000-0000-0000-0000-000000000001","content_item_id":"60000000-0000-0000-0000-000000000001","module_code":"STU-SLEEP-001","title":"Sleep Basics for Students","theme":"Sleep","age_cohort":"13_14","estimated_minutes":12,"sort_order":1,"progress_status":"not_started","completion_percent":0.0,"current_section_ordinal":null,"current_step_ordinal":null,"last_activity_at":null,"module_progress_id":null,"total_sections":1,"total_steps":1}]',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final modules = await client.listStudentModules(
      identity: const DevelopmentIdentity(externalAuthId: 'student-ext-id'),
      theme: 'Sleep',
    );

    expect(
      modules.single.contentItemId,
      '60000000-0000-0000-0000-000000000001',
    );
    expect(modules.single.title, 'Sleep Basics for Students');
    expect(modules.single.totalSections, 1);
  });

  test('fetches filtered content feed', () async {
    final client = BahaApiClient(
      baseUrl: 'http://localhost:8000',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/mobile/content/feed');
        expect(request.url.queryParameters['theme'], 'Digital Wellness');
        expect(request.url.queryParameters['topic'], 'digital_habits');
        return http.Response(
          '[{"id":"60000000-0000-0000-0000-000000000005","slug":"demo-student-module-digital-balance","title":"Digital Balance After School","content_type":"learning_module","audience_app":"student","age_cohort":"13_14","theme":"Digital Wellness","topic":"digital_habits","subtopic":"screen_boundaries","summary":"Reset from scrolling loops.","version_id":"61000000-0000-0000-0000-000000000005","version_number":1,"plain_text":"Choose a stop cue before you open the app.","metadata":{"demo":true},"published_at":"2026-06-28T10:00:00Z"}]',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final items = await client.listMobileContentFeed(
      identity: const DevelopmentIdentity(externalAuthId: 'student-ext-id'),
      theme: 'Digital Wellness',
      topic: 'digital_habits',
    );

    expect(items.single.theme, 'Digital Wellness');
    expect(items.single.topic, 'digital_habits');
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

  test('fetches support contacts', () async {
    final client = BahaApiClient(
      baseUrl: 'http://localhost:8000',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/mobile/support-contacts');
        return http.Response(
          '[{"id":"70000000-0000-0000-0000-000000000001","school_id":"10000000-0000-0000-0000-000000000001","contact_type":"counselor","audience_app":"shared","label":"BAHA Demo Counselor Line","phone":"+91-90000-00001","email":"counselor.demo@baha.local","contact_url":null,"service_hours":"Mon-Fri 9am-6pm","priority":1,"metadata":{"demo":true}}]',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final contacts = await client.listSupportContacts(
      identity: const DevelopmentIdentity(externalAuthId: 'student-ext-id'),
    );

    expect(contacts.single.label, 'BAHA Demo Counselor Line');
  });

  test('fetches story world state', () async {
    final client = BahaApiClient(
      baseUrl: 'http://localhost:8000',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/mobile/student/games/story-world/state');
        return http.Response(
          '{"student_profile_id":"30000000-0000-0000-0000-000000000001","display_name":"Aarav Student","age_cohort":"13_14","theme_variant":"social_confidence","pet_name":"Comet","xp":120,"coins":40,"stars":0,"current_day":1,"current_location_id":"home","completed_quest_count":0,"locations":[{"location_id":"home","display_name":"Home","subtitle":"Family moments, daily routines, and small choices.","npc_id":"ria","npc_name":"Ria","unlock_stars":0,"chapter":1,"last_choice":null,"unlocked":true,"completed":false,"progress_percent":0.0,"session_status":"started"}],"npcs":[{"npc_id":"ria","npc_name":"Ria","friendship_level":1,"current_mood":"curious","memories":[]}]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final state = await client.getStoryWorldState(
      identity: const DevelopmentIdentity(externalAuthId: 'student-ext-id'),
    );

    expect(state.currentLocationId, 'home');
    expect(state.locations.single.npcName, 'Ria');
  });

  test('submits story world turn', () async {
    final client = BahaApiClient(
      baseUrl: 'http://localhost:8000',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/mobile/student/games/story-world/turns');
        expect(request.method, 'POST');
        return http.Response(
          '{"state":{"student_profile_id":"30000000-0000-0000-0000-000000000001","display_name":"Aarav Student","theme_variant":"social_confidence","pet_name":"Comet","xp":165,"coins":56,"stars":2,"current_day":1,"current_location_id":"school","completed_quest_count":0,"locations":[],"npcs":[]},"scene":{"location_id":"school","chapter":2,"title":"The Hallway Supply Sprint · Chapter 2","body":"The quest grows bigger because of what you do next.","prompt":"What is your next move?","npc_id":"maya","npc_name":"Maya"},"message":"Your first move lands immediately.","memory":"Maya remembers how you chose to help.","xp_earned":45,"coins_earned":16,"stars_earned":2,"observed_signals":["kindness","cooperation"]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final turn = await client.submitStoryWorldTurn(
      identity: const DevelopmentIdentity(externalAuthId: 'student-ext-id'),
      request: const StoryWorldTurnRequest(
        locationId: 'school',
        answer: 'Help Maya rebuild the volcano together',
        expectedChapter: 1,
      ),
    );

    expect(turn.scene.chapter, 2);
    expect(turn.starsEarned, 2);
    expect(turn.observedSignals, contains('cooperation'));
  });

  test('creates student help request', () async {
    final client = BahaApiClient(
      baseUrl: 'http://localhost:8000',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/mobile/student/help-requests');
        expect(request.method, 'POST');
        return http.Response(
          '{"id":"1cfd6ca0-6af0-40b4-a6cd-8e74ff5a1a47","student_profile_id":"30000000-0000-0000-0000-000000000001","requested_by_user_id":"20000000-0000-0000-0000-000000000001","requested_for_user_id":"20000000-0000-0000-0000-000000000001","request_channel":"student_app","category":"academic_stress","urgency":"standard","status":"open","summary":"Need help balancing school work.","details":{"note":"Demo request from integration check"},"visibility_scope":"private","created_at":"2026-06-27T09:12:31.057939Z"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final response = await client.createStudentHelpRequest(
      identity: const DevelopmentIdentity(externalAuthId: 'student-ext-id'),
      request: const HelpRequestCreateRequest(
        category: 'academic_stress',
        summary: 'Need help balancing school work.',
        details: {'note': 'Demo request from integration check'},
      ),
    );

    expect(response.category, 'academic_stress');
    expect(response.status, 'open');
  });

  test('lists chat sessions', () async {
    final client = BahaApiClient(
      baseUrl: 'http://localhost:8000',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/mobile/chat/sessions');
        return http.Response(
          '[{"id":"5fdff4be-a671-4571-8701-4a3cd420a5f2","session_type":"general_support","status":"active","safety_disposition":"none","started_at":"2026-06-27T09:18:17.709664Z","ended_at":null,"last_message_at":null,"message_count":0,"summary_visibility_scope":"private"}]',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final sessions = await client.listChatSessions(
      identity: const DevelopmentIdentity(externalAuthId: 'student-ext-id'),
    );

    expect(sessions.single.status, 'active');
  });

  test('creates chat message exchange', () async {
    final client = BahaApiClient(
      baseUrl: 'http://localhost:8000',
      httpClient: MockClient((request) async {
        expect(
          request.url.path,
          '/mobile/chat/sessions/5fdff4be-a671-4571-8701-4a3cd420a5f2/messages',
        );
        expect(request.method, 'POST');
        return http.Response(
          '{"user_message":{"id":"1","chat_session_id":"2","sender_type":"user","message_type":"user_query","ordinal":1,"body":"I feel stressed.","structured_payload":{},"retrieval_filters":{},"safety_labels":[],"created_at":"2026-06-27T09:18:17.716179Z","updated_at":"2026-06-27T09:18:17.716179Z"},"assistant_message":{"id":"3","chat_session_id":"2","sender_type":"assistant","message_type":"assistant_answer","ordinal":2,"body":"Talk to a trusted adult.","structured_payload":{},"retrieval_filters":{},"safety_labels":[],"created_at":"2026-06-27T09:18:17.716179Z","updated_at":"2026-06-27T09:18:17.716179Z"},"answer":{"condition":"Exam Stress"},"retrieved":[]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final exchange = await client.createChatMessage(
      identity: const DevelopmentIdentity(externalAuthId: 'student-ext-id'),
      sessionId: '5fdff4be-a671-4571-8701-4a3cd420a5f2',
      request: const MobileChatMessageCreateRequest(body: 'I feel stressed.'),
    );

    expect(exchange.userMessage.body, 'I feel stressed.');
    expect(exchange.assistantMessage.senderType, 'assistant');
  });

  test('streams chat message exchange events', () async {
    final client = BahaApiClient(
      baseUrl: 'http://localhost:8000',
      httpClient: MockClient((request) async {
        expect(
          request.url.path,
          '/mobile/chat/sessions/5fdff4be-a671-4571-8701-4a3cd420a5f2/messages/stream',
        );
        expect(request.method, 'POST');
        return http.Response(
          '{"type":"ack","user_message":{"id":"1","chat_session_id":"2","sender_type":"user","message_type":"user_query","ordinal":1,"body":"I feel stressed.","structured_payload":{},"retrieval_filters":{},"safety_labels":[],"created_at":"2026-06-27T09:18:17.716179Z","updated_at":"2026-06-27T09:18:17.716179Z"}}\n'
          '{"type":"delta","delta":"That sounds heavy. "}\n'
          '{"type":"delta","delta":"Try one small step next."}\n'
          '{"type":"complete","assistant_message":{"id":"3","chat_session_id":"2","sender_type":"assistant","message_type":"assistant_answer","ordinal":2,"body":"That sounds heavy. Try one small step next.","structured_payload":{},"retrieval_filters":{},"safety_labels":[],"created_at":"2026-06-27T09:18:17.716179Z","updated_at":"2026-06-27T09:18:17.716179Z"},"backend_used":"openai_conversational","retrieved":[]}\n',
          200,
          headers: {'content-type': 'application/x-ndjson'},
        );
      }),
    );

    final events = await client
        .createChatMessageStream(
          identity: const DevelopmentIdentity(externalAuthId: 'student-ext-id'),
          sessionId: '5fdff4be-a671-4571-8701-4a3cd420a5f2',
          request: const MobileChatMessageCreateRequest(
            body: 'I feel stressed.',
          ),
        )
        .toList();

    expect(events.first.isAck, isTrue);
    expect(events[1].delta, 'That sounds heavy. ');
    expect(events[2].delta, 'Try one small step next.');
    expect(events.last.isComplete, isTrue);
    expect(events.last.assistantMessage?.body, contains('small step next'));
  });

  test('lists linked parent students', () async {
    final client = BahaApiClient(
      baseUrl: 'http://localhost:8000',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/mobile/parent/students');
        return http.Response(
          '[{"student_profile_id":"30000000-0000-0000-0000-000000000001","student_name":"Aarav Student","age_cohort":"13_14","relationship_to_student":"mother","is_primary":true,"school_name":"BAHA Pilot School"}]',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final students = await client.listParentStudents(
      identity: const DevelopmentIdentity(externalAuthId: 'guardian-ext-id'),
    );

    expect(students.single.studentName, 'Aarav Student');
    expect(students.single.isPrimary, isTrue);
  });

  test('fetches parent weekly summary', () async {
    final client = BahaApiClient(
      baseUrl: 'http://localhost:8000',
      httpClient: MockClient((request) async {
        expect(
          request.url.path,
          '/mobile/parent/students/30000000-0000-0000-0000-000000000001/weekly-summary/latest',
        );
        return http.Response(
          '{"id":"73000000-0000-0000-0000-000000000001","student_profile_id":"30000000-0000-0000-0000-000000000001","guardian_id":"30000000-0000-0000-0000-000000000101","week_start":"2026-06-22","week_end":"2026-06-28","consent_status":"approved","visible_tiers":["tier1","tier2"],"summary":{"headline":"Your child showed consistent check-in participation.","safe_talking_point":"Ask what part of the week felt easiest."},"generated_at":"2026-06-27T10:15:00Z","access":{"allowed":true,"mode":"approved","visible_tiers":["tier1","tier2"],"reason":null}}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final summary = await client.getParentWeeklySummary(
      identity: const DevelopmentIdentity(externalAuthId: 'guardian-ext-id'),
      studentProfileId: '30000000-0000-0000-0000-000000000001',
    );

    expect(summary.access.mode, 'approved');
    expect(summary.summary['safe_talking_point'], contains('easiest'));
  });

  test('fetches parent summary consent status', () async {
    final client = BahaApiClient(
      baseUrl: 'http://localhost:8000',
      httpClient: MockClient((request) async {
        expect(
          request.url.path,
          '/auth/guardian/consent/parent-summary-sharing/30000000-0000-0000-0000-000000000001',
        );
        return http.Response(
          '{"consent_type":"parent_summary_sharing","consent_version_id":"76000000-0000-0000-0000-000000000001","student_profile_id":"30000000-0000-0000-0000-000000000001","guardian_id":"30000000-0000-0000-0000-000000000101","status":"granted","scope":"weekly_summaries","actor_relationship":"parent","granted_at":"2026-06-27T10:15:00Z","withdrawn_at":null,"created_at":"2026-06-27T10:00:00Z"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final consent = await client.getParentSummaryConsentStatus(
      identity: const DevelopmentIdentity(externalAuthId: 'guardian-ext-id'),
      studentProfileId: '30000000-0000-0000-0000-000000000001',
    );

    expect(consent.status, 'granted');
    expect(consent.actorRelationship, 'parent');
  });

  test('updates parent summary consent', () async {
    final client = BahaApiClient(
      baseUrl: 'http://localhost:8000',
      httpClient: MockClient((request) async {
        expect(
          request.url.path,
          '/auth/guardian/consent/parent-summary-sharing',
        );
        expect(request.method, 'POST');
        return http.Response(
          '{"consent_type":"parent_summary_sharing","consent_version_id":"76000000-0000-0000-0000-000000000001","student_profile_id":"30000000-0000-0000-0000-000000000001","guardian_id":"30000000-0000-0000-0000-000000000101","status":"withdrawn","scope":"weekly_summaries","actor_relationship":"parent","granted_at":"2026-06-27T10:15:00Z","withdrawn_at":"2026-06-27T10:30:00Z","created_at":"2026-06-27T10:00:00Z"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final consent = await client.updateParentSummaryConsent(
      identity: const DevelopmentIdentity(externalAuthId: 'guardian-ext-id'),
      request: const ParentSummaryConsentRequest(
        studentProfileId: '30000000-0000-0000-0000-000000000001',
        status: 'withdrawn',
      ),
    );

    expect(consent.status, 'withdrawn');
    expect(consent.withdrawnAt, isNotNull);
  });

  test('updates platform participation consent', () async {
    final client = BahaApiClient(
      baseUrl: 'http://localhost:8000',
      httpClient: MockClient((request) async {
        expect(
          request.url.path,
          '/auth/guardian/consent/platform-participation',
        );
        expect(request.method, 'POST');
        return http.Response(
          '{"has_baha_user":true,"identity_match_mode":"external_auth_id","external_auth_id":"guardian-ext-id","roles":["guardian"],"approval_status":"not_required","consent_status":"granted","guardian_link_status":"linked","linked_student_count":1,"linked_guardian_count":0,"next_step":"ready","detail":"Guardian participation granted.","student_profile_id":"30000000-0000-0000-0000-000000000001"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final state = await client.updatePlatformParticipationConsent(
      identity: const DevelopmentIdentity(externalAuthId: 'guardian-ext-id'),
      request: const PlatformParticipationConsentRequest(
        studentProfileId: '30000000-0000-0000-0000-000000000001',
      ),
    );

    expect(state.nextStep, 'ready');
    expect(state.consentStatus, 'granted');
  });

  test('links guardian to student with verification code', () async {
    final client = BahaApiClient(
      baseUrl: 'http://localhost:8000',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/auth/guardian/link-student');
        expect(request.method, 'POST');
        expect(request.body, contains('"student_code":"STU-ABC1234567"'));
        expect(request.body, contains('"verification_code":"482931"'));
        return http.Response(
          '{"has_baha_user":true,"identity_match_mode":"external_auth_id","external_auth_id":"guardian-ext-id","roles":["guardian"],"guardian_link_status":"linked","approval_status":"not_required","consent_status":"not_required","linked_student_count":1,"linked_guardian_count":0,"next_step":"ready"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final state = await client.linkGuardianStudent(
      identity: const DevelopmentIdentity(
        externalAuthId: 'guardian-ext-id',
        requestedRole: AppRequestedRole.guardian,
      ),
      request: const GuardianLinkStudentRequest(
        studentCode: 'STU-ABC1234567',
        verificationCode: '482931',
        relationshipToStudent: 'parent',
      ),
    );

    expect(state.guardianLinkStatus, 'linked');
    expect(state.linkedStudentCount, 1);
  });

  test('loads platform participation consent status for guardian', () async {
    final client = BahaApiClient(
      baseUrl: 'http://localhost:8000',
      httpClient: MockClient((request) async {
        expect(
          request.url.path,
          '/auth/guardian/consent/platform-participation/student-1',
        );
        return http.Response(
          '{"consent_type":"platform_participation","student_profile_id":"student-1","guardian_id":"guardian-1","status":"granted","scope":"platform_access","actor_relationship":"parent","granted_at":"2026-07-14T10:00:00Z"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final status = await client.getPlatformParticipationConsentStatus(
      identity: const DevelopmentIdentity(
        externalAuthId: 'guardian-ext-id',
        requestedRole: AppRequestedRole.guardian,
      ),
      studentProfileId: 'student-1',
    );

    expect(status.status, 'granted');
    expect(status.scope, 'platform_access');
  });

  test(
    'surfaces plain-text bootstrap failures as readable API errors',
    () async {
      final client = BahaApiClient(
        baseUrl: 'http://localhost:8000',
        httpClient: MockClient((request) async {
          expect(request.url.path, '/auth/bootstrap');
          return http.Response(
            'Internal Server Error',
            500,
            headers: {'content-type': 'text/plain'},
          );
        }),
      );

      expect(
        () => client.bootstrapIdentity(
          identity: const DevelopmentIdentity(externalAuthId: 'student-ext-id'),
          request: const AppBootstrapRequest(
            role: AppRequestedRole.student,
            displayName: 'Student Demo',
            schoolName: 'BAHA Pilot School',
            ageCohort: '15_18',
            legalConsentBand: 'minor',
            gender: 'male',
          ),
        ),
        throwsA(
          isA<BahaApiException>().having(
            (error) => error.message,
            'message',
            'Internal Server Error',
          ),
        ),
      );
    },
  );
}
