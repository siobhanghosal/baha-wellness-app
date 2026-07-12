import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:test/test.dart';

void main() {
  test('maps weekly summary payload', () {
    final summary = StudentWeeklySummary.fromJson(const {
      'id': '1',
      'student_profile_id': '2',
      'week_start': '2026-06-19',
      'week_end': '2026-06-25',
      'privacy_tier_applied': 'tier1',
      'summary_status': 'ready',
      'summary': {'headline': 'Steady week overall'},
      'source_window': {'checkins': 1},
      'generation_version': 'demo-v1',
      'generated_at': '2026-06-26T14:42:39.960669Z',
    });

    expect(summary.summary['headline'], 'Steady week overall');
    expect(summary.generatedAt.year, 2026);
  });

  test('maps checkin template question scale values', () {
    final detail = MobileCheckinTemplateDetail.fromJson(const {
      'id': '1',
      'template_key': 'weekly',
      'title': 'Weekly Student Check-In',
      'cadence': 'weekly',
      'age_cohort': '13_14',
      'metadata': {},
      'questions': [
        {
          'id': 'q1',
          'question_key': 'mood_week',
          'dimension': 'mood',
          'question_type': 'scale',
          'prompt': 'How are you?',
          'response_config': {
            'scale': [1, 2, 3, 4, 5],
          },
          'is_required': true,
          'ordinal': 1,
          'metadata': {},
        },
      ],
    });

    expect(detail.questions.single.scaleValues, [1, 2, 3, 4, 5]);
  });

  test('maps module summary with linked content item', () {
    final module = StudentModuleSummary.fromJson(const {
      'id': '62000000-0000-0000-0000-000000000001',
      'content_item_id': '60000000-0000-0000-0000-000000000001',
      'module_code': 'STU-SLEEP-001',
      'title': 'Sleep Basics for Students',
      'theme': 'Sleep',
      'age_cohort': '13_14',
      'estimated_minutes': 12,
      'sort_order': 1,
      'progress_status': 'in_progress',
      'completion_percent': 50,
      'current_section_ordinal': 1,
      'current_step_ordinal': 1,
      'last_activity_at': '2026-06-27T08:40:00.365232Z',
      'module_progress_id': 'e1647779-c19a-40ed-8443-6f8fd237a3b2',
      'total_sections': 2,
      'total_steps': 3,
    });

    expect(module.contentItemId, '60000000-0000-0000-0000-000000000001');
    expect(module.completionPercent, 50);
    expect(module.currentSectionOrdinal, 1);
    expect(module.totalSteps, 3);
  });

  test('maps content detail blocks', () {
    final detail = MobileContentDetail.fromJson(const {
      'id': '60000000-0000-0000-0000-000000000001',
      'slug': 'demo-student-module-sleep-basics',
      'title': 'Sleep Basics for Students',
      'content_type': 'learning_module',
      'audience_app': 'student',
      'age_cohort': '13_14',
      'theme': 'Sleep',
      'summary': 'Demo student module for Flutter integration',
      'version_id': '61000000-0000-0000-0000-000000000001',
      'version_number': 1,
      'body': {
        'blocks': [
          {
            'type': 'text',
            'value': 'Students can build healthier sleep routines.',
          },
        ],
      },
      'plain_text': 'Students can build healthier sleep routines.',
      'metadata': {'demo': true},
      'published_at': '2026-06-26T14:42:39.956992Z',
      'reviewed_by': 'BAHA Demo Reviewer',
      'reviewed_at': '2026-06-26T14:42:39.956629Z',
    });

    expect(detail.blocks.single.type, 'text');
    expect(detail.blocks.single.value, contains('sleep routines'));
  });

  test('maps support contact payload', () {
    final contact = MobileSupportContact.fromJson(const {
      'id': '70000000-0000-0000-0000-000000000001',
      'school_id': '10000000-0000-0000-0000-000000000001',
      'contact_type': 'counselor',
      'audience_app': 'shared',
      'label': 'BAHA Demo Counselor Line',
      'phone': '+91-90000-00001',
      'email': 'counselor.demo@baha.local',
      'contact_url': null,
      'service_hours': 'Mon-Fri 9am-6pm',
      'priority': 1,
      'metadata': {'demo': true},
    });

    expect(contact.contactType, 'counselor');
    expect(contact.phone, '+91-90000-00001');
  });

  test('maps help request response payload', () {
    final response = HelpRequestResponse.fromJson(const {
      'id': '1cfd6ca0-6af0-40b4-a6cd-8e74ff5a1a47',
      'student_profile_id': '30000000-0000-0000-0000-000000000001',
      'requested_by_user_id': '20000000-0000-0000-0000-000000000001',
      'requested_for_user_id': '20000000-0000-0000-0000-000000000001',
      'request_channel': 'student_app',
      'category': 'academic_stress',
      'urgency': 'standard',
      'status': 'open',
      'summary': 'Need help balancing school work.',
      'details': {'note': 'Demo request from integration check'},
      'visibility_scope': 'private',
      'created_at': '2026-06-27T09:12:31.057939Z',
    });

    expect(response.status, 'open');
    expect(response.details['note'], contains('integration'));
  });

  test('maps chat session summary payload', () {
    final session = ChatSessionSummary.fromJson(const {
      'id': '5fdff4be-a671-4571-8701-4a3cd420a5f2',
      'session_type': 'general_support',
      'status': 'active',
      'safety_disposition': 'none',
      'started_at': '2026-06-27T09:18:17.709664Z',
      'ended_at': null,
      'last_message_at': null,
      'message_count': 0,
      'summary_visibility_scope': 'private',
    });

    expect(session.sessionType, 'general_support');
    expect(session.messageCount, 0);
  });

  test('maps chat exchange response payload', () {
    final exchange = MobileChatExchangeResponse.fromJson(const {
      'user_message': {
        'id': '1',
        'chat_session_id': '2',
        'sender_type': 'user',
        'message_type': 'user_query',
        'ordinal': 1,
        'body': 'I feel stressed.',
        'structured_payload': {},
        'retrieval_filters': {},
        'safety_labels': [],
        'created_at': '2026-06-27T09:18:17.716179Z',
        'updated_at': '2026-06-27T09:18:17.716179Z',
      },
      'assistant_message': {
        'id': '3',
        'chat_session_id': '2',
        'sender_type': 'assistant',
        'message_type': 'assistant_answer',
        'ordinal': 2,
        'body': 'Talk to a trusted adult.',
        'structured_payload': {},
        'retrieval_filters': {},
        'safety_labels': [],
        'created_at': '2026-06-27T09:18:17.716179Z',
        'updated_at': '2026-06-27T09:18:17.716179Z',
      },
      'answer': {'condition': 'Exam Stress'},
      'retrieved': [],
    });

    expect(exchange.assistantMessage.senderType, 'assistant');
    expect(exchange.answer['condition'], 'Exam Stress');
  });

  test('maps linked parent student summary payload', () {
    final student = MobileLinkedStudentSummary.fromJson(const {
      'student_profile_id': '30000000-0000-0000-0000-000000000001',
      'student_name': 'Aarav Student',
      'age_cohort': '13_14',
      'relationship_to_student': 'mother',
      'is_primary': true,
      'school_name': 'BAHA Pilot School',
    });

    expect(student.studentName, 'Aarav Student');
    expect(student.relationshipToStudent, 'mother');
    expect(student.isPrimary, isTrue);
  });

  test('maps parent weekly summary payload', () {
    final summary = ParentWeeklySummary.fromJson(const {
      'id': '73000000-0000-0000-0000-000000000001',
      'student_profile_id': '30000000-0000-0000-0000-000000000001',
      'guardian_id': '30000000-0000-0000-0000-000000000101',
      'week_start': '2026-06-22',
      'week_end': '2026-06-28',
      'consent_status': 'approved',
      'visible_tiers': ['tier1', 'tier2'],
      'summary': {
        'headline': 'Your child showed consistent check-in participation.',
        'safe_talking_point': 'Ask what part of the week felt easiest.',
      },
      'generated_at': '2026-06-27T10:15:00Z',
      'access': {
        'allowed': true,
        'mode': 'approved',
        'visible_tiers': ['tier1', 'tier2'],
        'reason': null,
      },
    });

    expect(summary.access.allowed, isTrue);
    expect(summary.summary['headline'], contains('consistent'));
    expect(summary.visibleTiers, ['tier1', 'tier2']);
  });

  test('maps parent summary consent payload', () {
    final consent = ParentSummaryConsentStatus.fromJson(const {
      'consent_type': 'parent_summary_sharing',
      'consent_version_id': '76000000-0000-0000-0000-000000000001',
      'student_profile_id': '30000000-0000-0000-0000-000000000001',
      'guardian_id': '30000000-0000-0000-0000-000000000101',
      'status': 'granted',
      'scope': 'weekly_summaries',
      'actor_relationship': 'parent',
      'granted_at': '2026-06-27T10:15:00Z',
      'withdrawn_at': null,
      'created_at': '2026-06-27T10:00:00Z',
    });

    expect(consent.status, 'granted');
    expect(consent.scope, 'weekly_summaries');
    expect(consent.actorRelationship, 'parent');
  });

  test('maps story world state and scene payloads', () {
    final state = StoryWorldState.fromJson(const {
      'student_profile_id': '30000000-0000-0000-0000-000000000001',
      'display_name': 'Aarav Student',
      'age_cohort': '13_14',
      'theme_variant': 'social_confidence',
      'pet_name': 'Comet',
      'xp': 165,
      'coins': 56,
      'stars': 4,
      'current_day': 2,
      'current_location_id': 'school',
      'completed_quest_count': 0,
      'locations': [
        {
          'location_id': 'school',
          'display_name': 'School',
          'subtitle': 'Class, teamwork, and learning one step at a time.',
          'npc_id': 'maya',
          'npc_name': 'Maya',
          'unlock_stars': 0,
          'chapter': 2,
          'last_choice': 'Help Maya rebuild the volcano together',
          'unlocked': true,
          'completed': false,
          'progress_percent': 25.0,
          'session_status': 'started',
        },
      ],
      'npcs': [
        {
          'npc_id': 'maya',
          'npc_name': 'Maya',
          'friendship_level': 2,
          'current_mood': 'warm',
          'memories': ['Maya remembers how you helped before.'],
        },
      ],
    });
    final scene = StoryWorldScene.fromJson(const {
      'location_id': 'school',
      'chapter': 2,
      'title': 'The Hallway Supply Sprint · Chapter 2',
      'body': 'Maya remembers your first brave move.',
      'prompt': 'What is your next move?',
      'npc_id': 'maya',
      'npc_name': 'Maya',
    });

    expect(state.currentLocationId, 'school');
    expect(state.locations.single.progressPercent, 25.0);
    expect(state.npcs.single.friendshipLevel, 2);
    expect(scene.npcName, 'Maya');
    expect(scene.prompt, contains('next move'));
  });

  test('maps story world turn response payload', () {
    final response = StoryWorldTurnResponse.fromJson(const {
      'state': {
        'student_profile_id': '30000000-0000-0000-0000-000000000001',
        'display_name': 'Aarav Student',
        'theme_variant': 'social_confidence',
        'pet_name': 'Comet',
        'xp': 210,
        'coins': 72,
        'stars': 6,
        'current_day': 2,
        'current_location_id': 'school',
        'completed_quest_count': 0,
        'locations': [],
        'npcs': [],
      },
      'scene': {
        'location_id': 'school',
        'chapter': 3,
        'title': 'The Judge\'s Surprise Question · Chapter 3',
        'body': 'The story keeps moving.',
        'prompt': 'How do you answer or help in the moment?',
        'npc_id': 'maya',
        'npc_name': 'Maya',
      },
      'message': 'Your kind move changes the mood before it changes the path.',
      'memory': 'Maya remembers how you chose to help.',
      'xp_earned': 45,
      'coins_earned': 16,
      'stars_earned': 2,
      'observed_signals': ['kindness', 'cooperation'],
    });

    expect(response.scene.chapter, 3);
    expect(response.xpEarned, 45);
    expect(response.observedSignals, contains('kindness'));
  });
}
