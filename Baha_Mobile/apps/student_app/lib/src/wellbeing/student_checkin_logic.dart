import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/material.dart';

import '../prototype/prototype_models.dart';
import 'student_profile_logic.dart';

const _trackedFactors = <String>[
  'sleep',
  'energy',
  'mood',
  'stress',
  'physical_wellbeing',
  'connectedness',
];

class CheckinChoice {
  const CheckinChoice({
    required this.key,
    required this.label,
    required this.score,
    this.metadata = const {},
  });

  final String key;
  final String label;
  final double score;
  final Map<String, dynamic> metadata;

  factory CheckinChoice.fromJson(Map<String, dynamic> json) {
    return CheckinChoice(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
    );
  }
}

class WellbeingTrendPoint {
  const WellbeingTrendPoint({required this.date, required this.factorScores});

  final DateTime date;
  final Map<String, double> factorScores;

  double get overallScore {
    if (factorScores.isEmpty) {
      return 0;
    }
    final total = factorScores.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    return total / factorScores.length;
  }
}

class WellbeingFactorMetric {
  const WellbeingFactorMetric({
    required this.label,
    required this.factorKey,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String label;
  final String factorKey;
  final double value;
  final String detail;
  final IconData icon;
  final Color color;

  UiMetric toUiMetric() {
    return UiMetric(
      label: label,
      value: value,
      detail: detail,
      icon: icon,
      color: color,
    );
  }
}

List<CheckinChoice> choicesForQuestion(
  MobileCheckinQuestion question,
  StudentWellbeingProfile? profile,
) {
  final rawChoices = question.responseConfig['choices'];
  if (rawChoices is List) {
    return rawChoices
        .whereType<Map>()
        .map(
          (choice) => CheckinChoice.fromJson(Map<String, dynamic>.from(choice)),
        )
        .where((choice) => _choiceVisibleForProfile(choice, profile))
        .toList();
  }
  return question.scaleValues
      .map(
        (value) => CheckinChoice(
          key: '$value',
          label: '$value',
          score: value.toDouble(),
        ),
      )
      .toList();
}

bool isQuestionVisible({
  required MobileCheckinQuestion question,
  required Map<String, String> selectedAnswers,
  required StudentWellbeingProfile? profile,
}) {
  if (!_profileRequirementSatisfied(
    question.metadata['profile_requirements'],
    profile,
  )) {
    return false;
  }
  final showWhen = question.metadata['show_when'];
  if (showWhen is Map<String, dynamic>) {
    return _conditionSatisfied(showWhen, selectedAnswers, profile);
  }
  final showWhenAny = question.metadata['show_when_any'];
  if (showWhenAny is List) {
    return showWhenAny.whereType<Map>().any(
      (condition) => _conditionSatisfied(
        Map<String, dynamic>.from(condition),
        selectedAnswers,
        profile,
      ),
    );
  }
  return true;
}

List<WellbeingTrendPoint> buildTrendPointsFromDetails(
  List<StudentCheckinDetail> details,
) {
  final points = <WellbeingTrendPoint>[];
  for (final detail in details) {
    final submittedAt = detail.submittedAt;
    if (submittedAt == null) {
      continue;
    }
    final factorScores = <String, double>{};
    for (final answer in detail.answers) {
      final factorKey = _factorKeyForAnswer(answer);
      if (factorKey == null || !_trackedFactors.contains(factorKey)) {
        continue;
      }
      if (!_isCoreAnswer(answer)) {
        continue;
      }
      final score = _scoreForAnswer(answer);
      if (score == null) {
        continue;
      }
      factorScores[factorKey] = score.clamp(0, 4);
    }
    if (factorScores.isNotEmpty) {
      points.add(
        WellbeingTrendPoint(date: submittedAt, factorScores: factorScores),
      );
    }
  }
  points.sort((left, right) => left.date.compareTo(right.date));
  return points;
}

List<WellbeingFactorMetric> buildFactorMetrics({
  required List<WellbeingTrendPoint> points,
  required StudentWellbeingProfile? profile,
}) {
  if (points.isEmpty) {
    return const [];
  }
  final latest = points.last;
  final previous = points.length > 1 ? points[points.length - 2] : null;
  return _trackedFactors.map((factorKey) {
    final descriptor = _factorDescriptor(factorKey);
    final value = latest.factorScores[factorKey] ?? 0;
    final previousValue = previous?.factorScores[factorKey];
    final trendText = _trendSummary(
      factorKey: factorKey,
      value: value,
      previousValue: previousValue,
      profile: profile,
    );
    return WellbeingFactorMetric(
      label: descriptor.label,
      factorKey: factorKey,
      value: (4 - value) / 4,
      detail: trendText,
      icon: descriptor.icon,
      color: descriptor.color,
    );
  }).toList();
}

List<double> chartValuesForFactor(
  List<WellbeingTrendPoint> points,
  String factorKey,
) {
  return points
      .map((point) => point.factorScores[factorKey] ?? point.overallScore)
      .map((value) => double.parse(value.toStringAsFixed(2)))
      .toList();
}

List<double> overallChartValues(List<WellbeingTrendPoint> points) {
  return points
      .map((point) => double.parse(point.overallScore.toStringAsFixed(2)))
      .toList();
}

List<String> chartLabels(List<WellbeingTrendPoint> points) {
  return points.map((point) => _weekdayLabel(point.date.weekday)).toList();
}

List<String> riskFlags({
  required List<WellbeingTrendPoint> points,
  required StudentWellbeingProfile? profile,
}) {
  final source = points;
  final flags = <String>[];
  if (_countAtOrAbove(source, 'sleep', 3) >= 3) {
    flags.add('Sleep strain repeating');
  }
  if (_consecutiveAtOrAbove(source, 'stress', 3, 2)) {
    flags.add('Stress elevated across days');
  }
  if (_consecutiveAtOrAbove(source, 'mood', 3, 2)) {
    flags.add('Mood dip needs attention');
  }
  if (_consecutiveAtOrAbove(source, 'connectedness', 3, 2)) {
    flags.add('Connection feels low');
  }
  if (profile != null &&
      profile.profileTags.contains('somatic_signal_prone') &&
      _countAtOrAbove(source, 'physical_wellbeing', 3) >= 2) {
    flags.add('Physical discomfort pattern visible');
  }
  return flags.take(3).toList();
}

CheckinAnswerInput buildSubmissionAnswer({
  required MobileCheckinQuestion question,
  required CheckinChoice choice,
}) {
  return CheckinAnswerInput(
    questionId: question.id,
    numericValue: choice.score,
    selectedOptions: [choice.key],
    normalizedValue: <String, dynamic>{
      'question_key': question.questionKey,
      'dimension': question.dimension,
      'choice_key': choice.key,
      'label': choice.label,
      'score': choice.score,
      'is_core': question.metadata['is_core'] == true,
      'source': 'student_app_v2',
    },
  );
}

String answerDisplayLabel(StudentCheckinAnswer answer) {
  final normalizedLabel = answer.normalizedValue['label']?.toString();
  if (normalizedLabel != null && normalizedLabel.isNotEmpty) {
    return normalizedLabel;
  }
  if (answer.selectedOptions.isNotEmpty) {
    return answer.selectedOptions.join(', ');
  }
  if (answer.numericValue != null) {
    return answer.numericValue!.toStringAsFixed(
      answer.numericValue! % 1 == 0 ? 0 : 1,
    );
  }
  if (answer.textValue != null && answer.textValue!.isNotEmpty) {
    return answer.textValue!;
  }
  if (answer.booleanValue != null) {
    return answer.booleanValue! ? 'Yes' : 'No';
  }
  return 'No answer captured';
}

String dailyStateHeadline(List<WellbeingTrendPoint> points) {
  if (points.isEmpty) {
    return 'No check-in entries yet.';
  }
  final latest = points.last;
  final highest = latest.factorScores.entries.fold<MapEntry<String, double>?>(
    null,
    (best, current) =>
        best == null || current.value > best.value ? current : best,
  );
  if (highest == null) {
    return 'Today looks steady overall.';
  }
  final descriptor = _factorDescriptor(highest.key);
  if (highest.value >= 3) {
    return '${descriptor.label} is the biggest strain signal today.';
  }
  if (latest.overallScore < 1.4) {
    return 'Today looks fairly steady overall.';
  }
  return '${descriptor.label} is worth keeping an eye on today.';
}

class _FactorDescriptor {
  const _FactorDescriptor({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

String personalizedPromptForQuestion(
  MobileCheckinQuestion question,
  StudentWellbeingProfile profile,
) {
  final ageBand = profile.ageBand;
  final older = ageBand == '15_18' || ageBand == '18_plus';
  switch (question.questionKey) {
    case 'sleep_last_night':
      return older
          ? 'How was your sleep last night?'
          : 'How did you sleep last night?';
    case 'energy_today':
      return older
          ? 'How is your energy level today?'
          : 'How is your energy today?';
    case 'mood_today':
      return older
          ? 'How has your mood felt today?'
          : 'How is your mood today?';
    case 'stress_today':
      return older
          ? 'How much stress or worry are you carrying today?'
          : 'How stressed or worried do you feel today?';
    case 'body_today':
      return older
          ? 'How is your body feeling today overall?'
          : 'How does your body feel today?';
    case 'connected_today':
      return older
          ? 'How connected or supported do you feel today?'
          : 'How supported or connected do you feel today?';
    case 'sleep_reason':
      return older
          ? 'What was the main reason sleep felt off?'
          : 'What was the biggest reason your sleep felt bad?';
    case 'energy_reason':
      return older
          ? 'What seems to explain the low energy most?'
          : 'What best explains the low energy?';
    case 'hardest_today':
      return older
          ? 'What felt heaviest or hardest today?'
          : 'What felt hardest today?';
    case 'body_reason':
      if (profile.experiencesPeriods == 'yes') {
        return older
            ? 'What physical issue stood out most today?'
            : 'What bothered you most physically today?';
      }
      return older
          ? 'What physical issue stood out most today?'
          : 'What bothered you most physically?';
    case 'support_today':
      return older
          ? 'Would any support be useful right now?'
          : 'Would you like support today?';
    default:
      return question.prompt;
  }
}

_FactorDescriptor _factorDescriptor(String factorKey) {
  switch (factorKey) {
    case 'sleep':
      return const _FactorDescriptor(
        label: 'Sleep',
        color: Color(0xFF6366F1),
        icon: Icons.bedtime_rounded,
      );
    case 'energy':
      return const _FactorDescriptor(
        label: 'Energy',
        color: Color(0xFFEF4444),
        icon: Icons.bolt_rounded,
      );
    case 'mood':
      return const _FactorDescriptor(
        label: 'Mood',
        color: Color(0xFF14B8A6),
        icon: Icons.sentiment_satisfied_alt_rounded,
      );
    case 'stress':
      return const _FactorDescriptor(
        label: 'Stress',
        color: Color(0xFFF59E0B),
        icon: Icons.spa_rounded,
      );
    case 'physical_wellbeing':
      return const _FactorDescriptor(
        label: 'Body',
        color: Color(0xFF0EA5E9),
        icon: Icons.favorite_rounded,
      );
    case 'connectedness':
      return const _FactorDescriptor(
        label: 'Connection',
        color: Color(0xFFEC4899),
        icon: Icons.groups_2_rounded,
      );
    default:
      return const _FactorDescriptor(
        label: 'Wellbeing',
        color: Color(0xFF64748B),
        icon: Icons.insights_rounded,
      );
  }
}

bool _choiceVisibleForProfile(
  CheckinChoice choice,
  StudentWellbeingProfile? profile,
) {
  return _profileRequirementSatisfied(
    choice.metadata['profile_requirements'],
    profile,
  );
}

bool _conditionSatisfied(
  Map<String, dynamic> condition,
  Map<String, String> selectedAnswers,
  StudentWellbeingProfile? profile,
) {
  if (!_profileRequirementSatisfied(
    condition['profile_requirements'],
    profile,
  )) {
    return false;
  }
  final questionKey = condition['question_key']?.toString();
  if (questionKey == null || questionKey.isEmpty) {
    return false;
  }
  final selected = selectedAnswers[questionKey];
  if (selected == null) {
    return false;
  }
  final allowed = condition['selected_options'];
  if (allowed is List && allowed.isNotEmpty) {
    return allowed.map((value) => value.toString()).contains(selected);
  }
  return true;
}

bool _profileRequirementSatisfied(
  Object? rawRequirements,
  StudentWellbeingProfile? profile,
) {
  if (rawRequirements is! Map || profile == null) {
    return rawRequirements == null;
  }
  final requirements = Map<String, dynamic>.from(rawRequirements);
  final periods = requirements['experiences_periods'];
  if (periods != null && profile.experiencesPeriods != periods.toString()) {
    return false;
  }
  final ageBands = requirements['age_bands'];
  if (ageBands is List &&
      !ageBands.map((value) => value.toString()).contains(profile.ageBand)) {
    return false;
  }
  return true;
}

String? _factorKeyForAnswer(StudentCheckinAnswer answer) {
  final fromNormalized = answer.normalizedValue['dimension']?.toString();
  if (fromNormalized != null && fromNormalized.isNotEmpty) {
    return fromNormalized;
  }
  switch (answer.dimension) {
    case 'sleep':
    case 'energy':
    case 'mood':
    case 'stress':
    case 'physical_wellbeing':
    case 'connectedness':
      return answer.dimension;
    default:
      return null;
  }
}

bool _isCoreAnswer(StudentCheckinAnswer answer) {
  if (answer.normalizedValue['is_core'] == true) {
    return true;
  }
  return _trackedFactors.contains(answer.dimension);
}

double? _scoreForAnswer(StudentCheckinAnswer answer) {
  final normalizedScore = answer.normalizedValue['score'];
  if (normalizedScore is num) {
    return normalizedScore.toDouble();
  }
  return answer.numericValue;
}

String _trendSummary({
  required String factorKey,
  required double value,
  required double? previousValue,
  required StudentWellbeingProfile? profile,
}) {
  final descriptor = _factorDescriptor(factorKey);
  final delta = previousValue == null ? 0 : value - previousValue;
  final severity = value >= 3
      ? 'high'
      : value >= 2
      ? 'moderate'
      : 'steady';
  final direction = delta >= 0.35
      ? 'worsening'
      : delta <= -0.35
      ? 'improving'
      : 'steady';
  if (factorKey == 'sleep' &&
      profile?.profileTags.contains('sleep_vulnerable') == true) {
    return '${descriptor.label} looks $severity and $direction against this student’s sleep-sensitive baseline.';
  }
  if (factorKey == 'stress' &&
      profile?.profileTags.contains('school_pressure_driven') == true) {
    return '${descriptor.label} looks $severity, with school pressure likely to matter most.';
  }
  return '${descriptor.label} looks $severity and $direction across recent check-ins.';
}

int _countAtOrAbove(
  List<WellbeingTrendPoint> points,
  String factorKey,
  double threshold,
) {
  return points
      .where((point) => (point.factorScores[factorKey] ?? 0) >= threshold)
      .length;
}

bool _consecutiveAtOrAbove(
  List<WellbeingTrendPoint> points,
  String factorKey,
  double threshold,
  int countNeeded,
) {
  var count = 0;
  for (final point in points.reversed) {
    if ((point.factorScores[factorKey] ?? 0) >= threshold) {
      count += 1;
      if (count >= countNeeded) {
        return true;
      }
    } else {
      count = 0;
    }
  }
  return false;
}

String _weekdayLabel(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Mon';
    case DateTime.tuesday:
      return 'Tue';
    case DateTime.wednesday:
      return 'Wed';
    case DateTime.thursday:
      return 'Thu';
    case DateTime.friday:
      return 'Fri';
    case DateTime.saturday:
      return 'Sat';
    case DateTime.sunday:
      return 'Sun';
    default:
      return '';
  }
}
