import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/src/wellbeing/student_checkin_logic.dart';
import 'package:student_app/src/wellbeing/student_profile_logic.dart';

void main() {
  test('profile tags capture major personalization signals', () {
    const profile = StudentWellbeingProfile(
      ageBand: '13_14',
      genderIdentity: 'female',
      trustedSupportPerson: 'parent_guardian',
      schoolDaySleepQuality: 'poor',
      usualEnergy: 'okay',
      weeklyStressFrequency: 'very_often',
      mainPressure: 'school',
      mainPhysicalIssue: 'headaches',
      experiencesPeriods: 'yes',
      periodImpact: 'often',
      copingStyle: 'stay_alone',
      helpSeekingEase: 'very_hard',
      socialConnectedness: 'a_bit_isolated',
      supportPreference: 'activities_games',
      checkinFocus: 'sleep',
    );

    expect(
      profile.profileTags,
      containsAll(
        const [
          'sleep_vulnerable',
          'stress_vulnerable',
          'school_pressure_driven',
          'somatic_signal_prone',
          'period_linked_physical_impact',
          'low_help_seeking',
          'social_isolation_risk',
          'engagement_prefers_activity',
          'focus_sleep',
        ],
      ),
    );
  });

  test('conditional question visibility respects answers and profile', () {
    final question = MobileCheckinQuestion.fromJson(const {
      'id': '1',
      'question_key': 'body_reason',
      'dimension': 'physical_wellbeing',
      'question_type': 'choice',
      'prompt': 'What bothered you most physically?',
      'response_config': {
        'choices': [
          {
            'key': 'period_related',
            'label': 'Period-related',
            'score': 0,
            'metadata': {
              'profile_requirements': {'experiences_periods': 'yes'},
            },
          },
        ],
      },
      'is_required': false,
      'ordinal': 10,
      'metadata': {
        'show_when': {
          'question_key': 'body_today',
          'selected_options': ['not_great', 'quite_bad'],
        },
      },
    });

    const profile = StudentWellbeingProfile(
      ageBand: '13_14',
      genderIdentity: 'female',
      trustedSupportPerson: 'parent_guardian',
      schoolDaySleepQuality: 'okay',
      usualEnergy: 'okay',
      weeklyStressFrequency: 'sometimes',
      mainPressure: 'school',
      mainPhysicalIssue: 'none',
      experiencesPeriods: 'yes',
      copingStyle: 'talk_to_someone',
      helpSeekingEase: 'mixed',
      socialConnectedness: 'mostly_connected',
      supportPreference: 'quick_tips',
      checkinFocus: 'no_preference',
    );

    expect(
      isQuestionVisible(
        question: question,
        selectedAnswers: const {'body_today': 'not_great'},
        profile: profile,
      ),
      isTrue,
    );
    expect(
      choicesForQuestion(question, profile).map((choice) => choice.key),
      contains('period_related'),
    );
    expect(
      isQuestionVisible(
        question: question,
        selectedAnswers: const {'body_today': 'mostly_good'},
        profile: profile,
      ),
      isFalse,
    );
  });

  test('trend points derive tracked factor scores from check-in detail', () {
    final detail = StudentCheckinDetail.fromJson(const {
      'id': 'resp-1',
      'template_id': 'tmpl-1',
      'template_key': 'daily_student_pulse_v2_13_14',
      'title': 'Daily Wellbeing Pulse',
      'status': 'submitted',
      'source_mode': 'daily_optional',
      'visibility_scope': 'private',
      'submitted_at': '2026-07-10T12:00:00Z',
      'answers': [
        {
          'question_id': 'q1',
          'question_key': 'sleep_last_night',
          'prompt': 'How did you sleep last night?',
          'dimension': 'sleep',
          'question_type': 'choice',
          'numeric_value': 3,
          'selected_options': ['poorly'],
          'normalized_value': {
            'score': 3,
            'label': 'Poorly',
            'dimension': 'sleep',
            'is_core': true,
          },
        },
        {
          'question_id': 'q2',
          'question_key': 'mood_today',
          'prompt': 'How is your mood today?',
          'dimension': 'mood',
          'question_type': 'choice',
          'numeric_value': 1,
          'selected_options': ['good'],
          'normalized_value': {
            'score': 1,
            'label': 'Good',
            'dimension': 'mood',
            'is_core': true,
          },
        },
      ],
    });

    final points = buildTrendPointsFromDetails([detail]);

    expect(points, hasLength(1));
    expect(points.single.factorScores['sleep'], 3);
    expect(points.single.factorScores['mood'], 1);
    expect(points.single.overallScore, 2);
  });
}
