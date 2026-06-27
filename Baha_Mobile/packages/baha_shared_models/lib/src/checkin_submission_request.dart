class CheckinAnswerInput {
  const CheckinAnswerInput({
    required this.questionId,
    this.numericValue,
    this.textValue,
    this.booleanValue,
    this.selectedOptions = const [],
    this.normalizedValue = const {},
  });

  final String questionId;
  final double? numericValue;
  final String? textValue;
  final bool? booleanValue;
  final List<String> selectedOptions;
  final Map<String, dynamic> normalizedValue;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'question_id': questionId,
      'numeric_value': numericValue,
      'text_value': textValue,
      'boolean_value': booleanValue,
      'selected_options': selectedOptions,
      'normalized_value': normalizedValue,
    };
  }
}

class CheckinSubmissionRequest {
  const CheckinSubmissionRequest({
    required this.templateId,
    required this.answers,
    this.sourceMode = 'manual',
    this.visibilityScope = 'private',
  });

  final String templateId;
  final String sourceMode;
  final String visibilityScope;
  final List<CheckinAnswerInput> answers;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'template_id': templateId,
      'source_mode': sourceMode,
      'visibility_scope': visibilityScope,
      'answers': answers.map((answer) => answer.toJson()).toList(),
    };
  }
}
