class MobileCheckinTemplateSummary {
  const MobileCheckinTemplateSummary({
    required this.id,
    required this.templateKey,
    required this.title,
    required this.cadence,
    required this.ageCohort,
    required this.questionCount,
    required this.metadata,
  });

  final String id;
  final String templateKey;
  final String title;
  final String cadence;
  final String ageCohort;
  final int questionCount;
  final Map<String, dynamic> metadata;

  factory MobileCheckinTemplateSummary.fromJson(Map<String, dynamic> json) {
    return MobileCheckinTemplateSummary(
      id: json['id'] as String? ?? '',
      templateKey: json['template_key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      cadence: json['cadence'] as String? ?? '',
      ageCohort: json['age_cohort'] as String? ?? '',
      questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
    );
  }
}

class MobileCheckinQuestion {
  const MobileCheckinQuestion({
    required this.id,
    required this.questionKey,
    required this.dimension,
    required this.questionType,
    required this.prompt,
    required this.responseConfig,
    required this.isRequired,
    required this.ordinal,
    required this.metadata,
  });

  final String id;
  final String questionKey;
  final String dimension;
  final String questionType;
  final String prompt;
  final Map<String, dynamic> responseConfig;
  final bool isRequired;
  final int ordinal;
  final Map<String, dynamic> metadata;

  List<int> get scaleValues {
    final scale = responseConfig['scale'];
    if (scale is List) {
      return scale.map((value) => (value as num).toInt()).toList();
    }
    return const [1, 2, 3, 4, 5];
  }

  factory MobileCheckinQuestion.fromJson(Map<String, dynamic> json) {
    return MobileCheckinQuestion(
      id: json['id'] as String? ?? '',
      questionKey: json['question_key'] as String? ?? '',
      dimension: json['dimension'] as String? ?? '',
      questionType: json['question_type'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      responseConfig: Map<String, dynamic>.from(json['response_config'] as Map? ?? const {}),
      isRequired: json['is_required'] as bool? ?? false,
      ordinal: (json['ordinal'] as num?)?.toInt() ?? 0,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
    );
  }
}

class MobileCheckinTemplateDetail {
  const MobileCheckinTemplateDetail({
    required this.id,
    required this.templateKey,
    required this.title,
    required this.cadence,
    required this.ageCohort,
    required this.metadata,
    required this.questions,
  });

  final String id;
  final String templateKey;
  final String title;
  final String cadence;
  final String ageCohort;
  final Map<String, dynamic> metadata;
  final List<MobileCheckinQuestion> questions;

  factory MobileCheckinTemplateDetail.fromJson(Map<String, dynamic> json) {
    return MobileCheckinTemplateDetail(
      id: json['id'] as String? ?? '',
      templateKey: json['template_key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      cadence: json['cadence'] as String? ?? '',
      ageCohort: json['age_cohort'] as String? ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
      questions: (json['questions'] as List<dynamic>? ?? const [])
          .map((value) => MobileCheckinQuestion.fromJson(Map<String, dynamic>.from(value as Map)))
          .toList(),
    );
  }
}
