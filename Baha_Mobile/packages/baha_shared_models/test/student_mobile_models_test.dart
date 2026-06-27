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
      'last_activity_at': '2026-06-27T08:40:00.365232Z',
      'module_progress_id': 'e1647779-c19a-40ed-8443-6f8fd237a3b2',
    });

    expect(module.contentItemId, '60000000-0000-0000-0000-000000000001');
    expect(module.completionPercent, 50);
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
}
