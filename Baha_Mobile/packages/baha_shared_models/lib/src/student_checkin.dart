class StudentCheckinSummary {
  const StudentCheckinSummary({
    required this.id,
    required this.templateId,
    required this.templateKey,
    required this.title,
    required this.status,
    required this.sourceMode,
    required this.visibilityScope,
    required this.responseCount,
    this.scheduledFor,
    this.submittedAt,
  });

  final String id;
  final String templateId;
  final String templateKey;
  final String title;
  final DateTime? scheduledFor;
  final DateTime? submittedAt;
  final String status;
  final String sourceMode;
  final String visibilityScope;
  final int responseCount;

  factory StudentCheckinSummary.fromJson(Map<String, dynamic> json) {
    return StudentCheckinSummary(
      id: json['id'] as String? ?? '',
      templateId: json['template_id'] as String? ?? '',
      templateKey: json['template_key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      scheduledFor: _parseDateTime(json['scheduled_for']),
      submittedAt: _parseDateTime(json['submitted_at']),
      status: json['status'] as String? ?? '',
      sourceMode: json['source_mode'] as String? ?? '',
      visibilityScope: json['visibility_scope'] as String? ?? '',
      responseCount: (json['response_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class StudentCheckinAnswer {
  const StudentCheckinAnswer({
    required this.questionId,
    required this.questionKey,
    required this.prompt,
    required this.dimension,
    required this.questionType,
    this.numericValue,
    this.textValue,
    this.booleanValue,
    this.selectedOptions = const [],
    this.normalizedValue = const {},
  });

  final String questionId;
  final String questionKey;
  final String prompt;
  final String dimension;
  final String questionType;
  final double? numericValue;
  final String? textValue;
  final bool? booleanValue;
  final List<String> selectedOptions;
  final Map<String, dynamic> normalizedValue;

  factory StudentCheckinAnswer.fromJson(Map<String, dynamic> json) {
    return StudentCheckinAnswer(
      questionId: json['question_id'] as String? ?? '',
      questionKey: json['question_key'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      dimension: json['dimension'] as String? ?? '',
      questionType: json['question_type'] as String? ?? '',
      numericValue: (json['numeric_value'] as num?)?.toDouble(),
      textValue: json['text_value'] as String?,
      booleanValue: json['boolean_value'] as bool?,
      selectedOptions: (json['selected_options'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      normalizedValue: Map<String, dynamic>.from(json['normalized_value'] as Map? ?? const {}),
    );
  }
}

class StudentCheckinDetail {
  const StudentCheckinDetail({
    required this.id,
    required this.templateId,
    required this.templateKey,
    required this.title,
    required this.status,
    required this.sourceMode,
    required this.visibilityScope,
    required this.answers,
    this.scheduledFor,
    this.submittedAt,
  });

  final String id;
  final String templateId;
  final String templateKey;
  final String title;
  final DateTime? scheduledFor;
  final DateTime? submittedAt;
  final String status;
  final String sourceMode;
  final String visibilityScope;
  final List<StudentCheckinAnswer> answers;

  factory StudentCheckinDetail.fromJson(Map<String, dynamic> json) {
    return StudentCheckinDetail(
      id: json['id'] as String? ?? '',
      templateId: json['template_id'] as String? ?? '',
      templateKey: json['template_key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      scheduledFor: _parseDateTime(json['scheduled_for']),
      submittedAt: _parseDateTime(json['submitted_at']),
      status: json['status'] as String? ?? '',
      sourceMode: json['source_mode'] as String? ?? '',
      visibilityScope: json['visibility_scope'] as String? ?? '',
      answers: (json['answers'] as List<dynamic>? ?? const [])
          .map((value) => StudentCheckinAnswer.fromJson(Map<String, dynamic>.from(value as Map)))
          .toList(),
    );
  }
}

DateTime? _parseDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value);
  }
  return null;
}
