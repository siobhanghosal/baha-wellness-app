class ChatSessionSummary {
  const ChatSessionSummary({
    required this.id,
    required this.sessionType,
    required this.status,
    required this.safetyDisposition,
    required this.startedAt,
    required this.messageCount,
    required this.summaryVisibilityScope,
    this.endedAt,
    this.lastMessageAt,
  });

  final String id;
  final String sessionType;
  final String status;
  final String safetyDisposition;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime? lastMessageAt;
  final int messageCount;
  final String summaryVisibilityScope;

  factory ChatSessionSummary.fromJson(Map<String, dynamic> json) {
    return ChatSessionSummary(
      id: json['id'] as String? ?? '',
      sessionType: json['session_type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      safetyDisposition: json['safety_disposition'] as String? ?? '',
      startedAt:
          _parseDateTime(json['started_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endedAt: _parseDateTime(json['ended_at']),
      lastMessageAt: _parseDateTime(json['last_message_at']),
      messageCount: (json['message_count'] as num?)?.toInt() ?? 0,
      summaryVisibilityScope:
          json['summary_visibility_scope'] as String? ?? 'private',
    );
  }
}

class ChatSessionCreateRequest {
  const ChatSessionCreateRequest({
    this.sessionType = 'general_support',
    this.summaryVisibilityScope = 'private',
  });

  final String sessionType;
  final String summaryVisibilityScope;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'session_type': sessionType,
      'summary_visibility_scope': summaryVisibilityScope,
    };
  }
}

class MobileChatMessage {
  const MobileChatMessage({
    required this.id,
    required this.chatSessionId,
    required this.senderType,
    required this.messageType,
    required this.ordinal,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    this.structuredPayload = const {},
    this.retrievalFilters = const {},
    this.safetyLabels = const [],
  });

  final String id;
  final String chatSessionId;
  final String senderType;
  final String messageType;
  final int ordinal;
  final String body;
  final Map<String, dynamic> structuredPayload;
  final Map<String, dynamic> retrievalFilters;
  final List<String> safetyLabels;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory MobileChatMessage.fromJson(Map<String, dynamic> json) {
    return MobileChatMessage(
      id: json['id'] as String? ?? '',
      chatSessionId: json['chat_session_id'] as String? ?? '',
      senderType: json['sender_type'] as String? ?? '',
      messageType: json['message_type'] as String? ?? '',
      ordinal: (json['ordinal'] as num?)?.toInt() ?? 0,
      body: json['body'] as String? ?? '',
      structuredPayload: Map<String, dynamic>.from(
        json['structured_payload'] as Map? ?? const {},
      ),
      retrievalFilters: Map<String, dynamic>.from(
        json['retrieval_filters'] as Map? ?? const {},
      ),
      safetyLabels: (json['safety_labels'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      createdAt:
          _parseDateTime(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          _parseDateTime(json['updated_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class MobileChatMessageCreateRequest {
  const MobileChatMessageCreateRequest({
    required this.body,
    this.filters = const {},
  });

  final String body;
  final Map<String, dynamic> filters;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'body': body, 'filters': filters};
  }
}

class MobileChatExchangeResponse {
  const MobileChatExchangeResponse({
    required this.userMessage,
    required this.assistantMessage,
    required this.answer,
    required this.retrieved,
  });

  final MobileChatMessage userMessage;
  final MobileChatMessage assistantMessage;
  final Map<String, dynamic> answer;
  final List<Map<String, dynamic>> retrieved;

  factory MobileChatExchangeResponse.fromJson(Map<String, dynamic> json) {
    return MobileChatExchangeResponse(
      userMessage: MobileChatMessage.fromJson(
        Map<String, dynamic>.from(json['user_message'] as Map? ?? const {}),
      ),
      assistantMessage: MobileChatMessage.fromJson(
        Map<String, dynamic>.from(
          json['assistant_message'] as Map? ?? const {},
        ),
      ),
      answer: Map<String, dynamic>.from(json['answer'] as Map? ?? const {}),
      retrieved: (json['retrieved'] as List<dynamic>? ?? const [])
          .map((value) => Map<String, dynamic>.from(value as Map))
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
