class MobileContentSummary {
  const MobileContentSummary({
    required this.id,
    required this.slug,
    required this.title,
    required this.contentType,
    required this.audienceApp,
    required this.ageCohort,
    required this.versionId,
    required this.versionNumber,
    this.theme,
    this.topic,
    this.subtopic,
    this.summary,
    this.plainText,
    this.metadata = const {},
    this.publishedAt,
  });

  final String id;
  final String slug;
  final String title;
  final String contentType;
  final String audienceApp;
  final String ageCohort;
  final String? theme;
  final String? topic;
  final String? subtopic;
  final String? summary;
  final String versionId;
  final int versionNumber;
  final String? plainText;
  final Map<String, dynamic> metadata;
  final DateTime? publishedAt;

  factory MobileContentSummary.fromJson(Map<String, dynamic> json) {
    return MobileContentSummary(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      contentType: json['content_type'] as String? ?? '',
      audienceApp: json['audience_app'] as String? ?? '',
      ageCohort: json['age_cohort'] as String? ?? '',
      theme: json['theme'] as String?,
      topic: json['topic'] as String?,
      subtopic: json['subtopic'] as String?,
      summary: json['summary'] as String?,
      versionId: json['version_id'] as String? ?? '',
      versionNumber: (json['version_number'] as num?)?.toInt() ?? 0,
      plainText: json['plain_text'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
      publishedAt: _parseDateTime(json['published_at']),
    );
  }
}

class MobileContentBlock {
  const MobileContentBlock({
    required this.type,
    this.value,
    this.data = const {},
  });

  final String type;
  final String? value;
  final Map<String, dynamic> data;

  factory MobileContentBlock.fromJson(Map<String, dynamic> json) {
    return MobileContentBlock(
      type: json['type'] as String? ?? 'text',
      value: json['value'] as String?,
      data: Map<String, dynamic>.from(json),
    );
  }
}

class MobileContentDetail {
  const MobileContentDetail({
    required this.id,
    required this.slug,
    required this.title,
    required this.contentType,
    required this.audienceApp,
    required this.ageCohort,
    required this.versionId,
    required this.versionNumber,
    required this.body,
    required this.blocks,
    this.theme,
    this.topic,
    this.subtopic,
    this.summary,
    this.plainText,
    this.metadata = const {},
    this.publishedAt,
    this.reviewedBy,
    this.reviewedAt,
  });

  final String id;
  final String slug;
  final String title;
  final String contentType;
  final String audienceApp;
  final String ageCohort;
  final String? theme;
  final String? topic;
  final String? subtopic;
  final String? summary;
  final String versionId;
  final int versionNumber;
  final Map<String, dynamic> body;
  final List<MobileContentBlock> blocks;
  final String? plainText;
  final Map<String, dynamic> metadata;
  final DateTime? publishedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  factory MobileContentDetail.fromJson(Map<String, dynamic> json) {
    final body = Map<String, dynamic>.from(json['body'] as Map? ?? const {});
    final blocksJson = body['blocks'] as List<dynamic>? ?? const [];
    return MobileContentDetail(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      contentType: json['content_type'] as String? ?? '',
      audienceApp: json['audience_app'] as String? ?? '',
      ageCohort: json['age_cohort'] as String? ?? '',
      theme: json['theme'] as String?,
      topic: json['topic'] as String?,
      subtopic: json['subtopic'] as String?,
      summary: json['summary'] as String?,
      versionId: json['version_id'] as String? ?? '',
      versionNumber: (json['version_number'] as num?)?.toInt() ?? 0,
      body: body,
      blocks: blocksJson
          .map(
            (value) => MobileContentBlock.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList(),
      plainText: json['plain_text'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
      publishedAt: _parseDateTime(json['published_at']),
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: _parseDateTime(json['reviewed_at']),
    );
  }
}

DateTime? _parseDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value);
  }
  return null;
}
