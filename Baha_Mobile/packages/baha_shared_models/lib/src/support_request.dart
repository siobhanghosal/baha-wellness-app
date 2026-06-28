class MobileSupportContact {
  const MobileSupportContact({
    required this.id,
    required this.contactType,
    required this.audienceApp,
    required this.label,
    required this.priority,
    this.schoolId,
    this.phone,
    this.email,
    this.contactUrl,
    this.serviceHours,
    this.metadata = const {},
  });

  final String id;
  final String? schoolId;
  final String contactType;
  final String audienceApp;
  final String label;
  final String? phone;
  final String? email;
  final String? contactUrl;
  final String? serviceHours;
  final int priority;
  final Map<String, dynamic> metadata;

  factory MobileSupportContact.fromJson(Map<String, dynamic> json) {
    return MobileSupportContact(
      id: json['id'] as String? ?? '',
      schoolId: json['school_id'] as String?,
      contactType: json['contact_type'] as String? ?? '',
      audienceApp: json['audience_app'] as String? ?? '',
      label: json['label'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      contactUrl: json['contact_url'] as String?,
      serviceHours: json['service_hours'] as String?,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
    );
  }
}

class HelpRequestCreateRequest {
  const HelpRequestCreateRequest({
    required this.category,
    required this.summary,
    this.urgency = 'standard',
    this.details = const {},
    this.visibilityScope = 'private',
  });

  final String category;
  final String urgency;
  final String summary;
  final Map<String, dynamic> details;
  final String visibilityScope;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'category': category,
      'urgency': urgency,
      'summary': summary,
      'details': details,
      'visibility_scope': visibilityScope,
    };
  }
}

class HelpRequestResponse {
  const HelpRequestResponse({
    required this.id,
    required this.requestedByUserId,
    required this.requestChannel,
    required this.category,
    required this.urgency,
    required this.status,
    required this.summary,
    required this.visibilityScope,
    required this.createdAt,
    this.studentProfileId,
    this.requestedForUserId,
    this.details = const {},
  });

  final String id;
  final String? studentProfileId;
  final String requestedByUserId;
  final String? requestedForUserId;
  final String requestChannel;
  final String category;
  final String urgency;
  final String status;
  final String summary;
  final Map<String, dynamic> details;
  final String visibilityScope;
  final DateTime createdAt;

  factory HelpRequestResponse.fromJson(Map<String, dynamic> json) {
    return HelpRequestResponse(
      id: json['id'] as String? ?? '',
      studentProfileId: json['student_profile_id'] as String?,
      requestedByUserId: json['requested_by_user_id'] as String? ?? '',
      requestedForUserId: json['requested_for_user_id'] as String?,
      requestChannel: json['request_channel'] as String? ?? '',
      category: json['category'] as String? ?? '',
      urgency: json['urgency'] as String? ?? '',
      status: json['status'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      details: Map<String, dynamic>.from(json['details'] as Map? ?? const {}),
      visibilityScope: json['visibility_scope'] as String? ?? '',
      createdAt:
          _parseDateTime(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

DateTime? _parseDateTime(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value);
  }
  return null;
}
