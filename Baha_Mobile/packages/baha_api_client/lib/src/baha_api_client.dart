import 'dart:convert';

import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:http/http.dart' as http;

import 'baha_api_exception.dart';

class BahaApiClient {
  BahaApiClient({required String baseUrl, http.Client? httpClient})
    : _baseUrl = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl,
      _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _httpClient;

  Future<AuthOnboardingState> getOnboardingState({
    required DevelopmentIdentity identity,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/auth/onboarding-state'),
      headers: _headers(identity),
    );
    final payload = _decodeMap(response);
    _ensureSuccess(response.statusCode, payload);
    return AuthOnboardingState.fromJson(payload);
  }

  Future<AuthOnboardingState> bootstrapIdentity({
    required DevelopmentIdentity identity,
    required AppBootstrapRequest request,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/auth/bootstrap'),
      headers: _headers(identity),
      body: jsonEncode(request.toJson()),
    );
    final payload = _decodeMap(response);
    _ensureSuccess(response.statusCode, payload);
    return AuthOnboardingState.fromJson(payload);
  }

  Future<AuthOnboardingState> bootstrapStudent({
    required DevelopmentIdentity identity,
    required StudentBootstrapRequest request,
  }) {
    return bootstrapIdentity(identity: identity, request: request);
  }

  Future<MobileActor> getMobileMe({
    required DevelopmentIdentity identity,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/mobile/me'),
      headers: _headers(identity),
    );
    final payload = _decodeMap(response);
    _ensureSuccess(response.statusCode, payload);
    return MobileActor.fromJson(payload);
  }

  Future<StudentWeeklySummary> getStudentWeeklySummary({
    required DevelopmentIdentity identity,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/mobile/student/weekly-summary/latest'),
      headers: _headers(identity),
    );
    final payload = _decodeMap(response);
    _ensureSuccess(response.statusCode, payload);
    return StudentWeeklySummary.fromJson(payload);
  }

  Future<List<MobileCheckinTemplateSummary>> listStudentCheckinTemplates({
    required DevelopmentIdentity identity,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/mobile/student/checkin-templates'),
      headers: _headers(identity),
    );
    final payload = _decodeList(response);
    return payload
        .map((item) => MobileCheckinTemplateSummary.fromJson(item))
        .toList();
  }

  Future<MobileCheckinTemplateDetail> getStudentCheckinTemplateDetail({
    required DevelopmentIdentity identity,
    required String templateId,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/mobile/student/checkin-templates/$templateId'),
      headers: _headers(identity),
    );
    final payload = _decodeMap(response);
    _ensureSuccess(response.statusCode, payload);
    return MobileCheckinTemplateDetail.fromJson(payload);
  }

  Future<List<StudentCheckinSummary>> listStudentCheckins({
    required DevelopmentIdentity identity,
    int limit = 20,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/mobile/student/checkins',
    ).replace(queryParameters: <String, String>{'limit': '$limit'});
    final response = await _httpClient.get(uri, headers: _headers(identity));
    final payload = _decodeList(response);
    return payload.map((item) => StudentCheckinSummary.fromJson(item)).toList();
  }

  Future<StudentCheckinDetail> getStudentCheckinDetail({
    required DevelopmentIdentity identity,
    required String responseSetId,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/mobile/student/checkins/$responseSetId'),
      headers: _headers(identity),
    );
    final payload = _decodeMap(response);
    _ensureSuccess(response.statusCode, payload);
    return StudentCheckinDetail.fromJson(payload);
  }

  Future<StudentCheckinSummary> submitStudentCheckin({
    required DevelopmentIdentity identity,
    required CheckinSubmissionRequest request,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/mobile/student/checkins'),
      headers: _headers(identity),
      body: jsonEncode(request.toJson()),
    );
    final payload = _decodeMap(response);
    _ensureSuccess(response.statusCode, payload);
    return StudentCheckinSummary.fromJson(payload);
  }

  Future<List<MobileContentSummary>> listMobileContentFeed({
    required DevelopmentIdentity identity,
    String? audienceApp,
    String? contentType,
    String? ageCohort,
    String? theme,
    String? topic,
    String? subtopic,
    int limit = 20,
  }) async {
    final queryParameters = <String, String>{
      'limit': '$limit',
      if (audienceApp != null && audienceApp.isNotEmpty)
        'audience_app': audienceApp,
      if (contentType != null && contentType.isNotEmpty)
        'content_type': contentType,
      if (ageCohort != null && ageCohort.isNotEmpty) 'age_cohort': ageCohort,
      if (theme != null && theme.isNotEmpty) 'theme': theme,
      if (topic != null && topic.isNotEmpty) 'topic': topic,
      if (subtopic != null && subtopic.isNotEmpty) 'subtopic': subtopic,
    };
    final uri = Uri.parse(
      '$_baseUrl/mobile/content/feed',
    ).replace(queryParameters: queryParameters);
    final response = await _httpClient.get(uri, headers: _headers(identity));
    final payload = _decodeList(response);
    return payload.map((item) => MobileContentSummary.fromJson(item)).toList();
  }

  Future<MobileContentDetail> getMobileContentDetail({
    required DevelopmentIdentity identity,
    required String contentItemId,
    String? audienceApp,
    String? ageCohort,
  }) async {
    final queryParameters = <String, String>{
      if (audienceApp != null && audienceApp.isNotEmpty)
        'audience_app': audienceApp,
      if (ageCohort != null && ageCohort.isNotEmpty) 'age_cohort': ageCohort,
    };
    final uri = Uri.parse(
      '$_baseUrl/mobile/content/$contentItemId',
    ).replace(queryParameters: queryParameters);
    final response = await _httpClient.get(uri, headers: _headers(identity));
    final payload = _decodeMap(response);
    _ensureSuccess(response.statusCode, payload);
    return MobileContentDetail.fromJson(payload);
  }

  Future<List<StudentModuleSummary>> listStudentModules({
    required DevelopmentIdentity identity,
    String? theme,
  }) async {
    final uri = Uri.parse('$_baseUrl/mobile/student/modules').replace(
      queryParameters: <String, String>{
        if (theme != null && theme.isNotEmpty) 'theme': theme,
      },
    );
    final response = await _httpClient.get(uri, headers: _headers(identity));
    final payload = _decodeList(response);
    return payload.map((item) => StudentModuleSummary.fromJson(item)).toList();
  }

  Future<ModuleProgressUpsertResponse> upsertStudentModuleProgress({
    required DevelopmentIdentity identity,
    required String moduleId,
    required ModuleProgressUpsertRequest request,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/mobile/student/modules/$moduleId/progress'),
      headers: _headers(identity),
      body: jsonEncode(request.toJson()),
    );
    final payload = _decodeMap(response);
    _ensureSuccess(response.statusCode, payload);
    return ModuleProgressUpsertResponse.fromJson(payload);
  }

  Future<StoryWorldState> getStoryWorldState({
    required DevelopmentIdentity identity,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/mobile/student/games/story-world/state'),
      headers: _headers(identity),
    );
    final payload = _decodeMap(response);
    _ensureSuccess(response.statusCode, payload);
    return StoryWorldState.fromJson(payload);
  }

  Future<StoryWorldScene> getStoryWorldScene({
    required DevelopmentIdentity identity,
    required String locationId,
  }) async {
    final response = await _httpClient.get(
      Uri.parse(
        '$_baseUrl/mobile/student/games/story-world/scenes/$locationId',
      ),
      headers: _headers(identity),
    );
    final payload = _decodeMap(response);
    _ensureSuccess(response.statusCode, payload);
    return StoryWorldScene.fromJson(payload);
  }

  Future<StoryWorldTurnResponse> submitStoryWorldTurn({
    required DevelopmentIdentity identity,
    required StoryWorldTurnRequest request,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/mobile/student/games/story-world/turns'),
      headers: _headers(identity),
      body: jsonEncode(request.toJson()),
    );
    final payload = _decodeMap(response);
    _ensureSuccess(response.statusCode, payload);
    return StoryWorldTurnResponse.fromJson(payload);
  }

  Future<List<MobileSupportContact>> listSupportContacts({
    required DevelopmentIdentity identity,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/mobile/support-contacts'),
      headers: _headers(identity),
    );
    final payload = _decodeList(response);
    return payload.map((item) => MobileSupportContact.fromJson(item)).toList();
  }

  Future<HelpRequestResponse> createStudentHelpRequest({
    required DevelopmentIdentity identity,
    required HelpRequestCreateRequest request,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/mobile/student/help-requests'),
      headers: _headers(identity),
      body: jsonEncode(request.toJson()),
    );
    final payload = _decodeMap(response);
    _ensureSuccess(response.statusCode, payload);
    return HelpRequestResponse.fromJson(payload);
  }

  Future<List<ChatSessionSummary>> listChatSessions({
    required DevelopmentIdentity identity,
    int limit = 20,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/mobile/chat/sessions',
    ).replace(queryParameters: <String, String>{'limit': '$limit'});
    final response = await _httpClient.get(uri, headers: _headers(identity));
    final payload = _decodeList(response);
    return payload.map((item) => ChatSessionSummary.fromJson(item)).toList();
  }

  Future<ChatSessionSummary> createChatSession({
    required DevelopmentIdentity identity,
    ChatSessionCreateRequest request = const ChatSessionCreateRequest(),
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/mobile/chat/sessions'),
      headers: _headers(identity),
      body: jsonEncode(request.toJson()),
    );
    final payload = _decodeMap(response);
    _ensureSuccess(response.statusCode, payload);
    return ChatSessionSummary.fromJson(payload);
  }

  Future<List<MobileChatMessage>> listChatMessages({
    required DevelopmentIdentity identity,
    required String sessionId,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/mobile/chat/sessions/$sessionId/messages'),
      headers: _headers(identity),
    );
    final payload = _decodeList(response);
    return payload.map((item) => MobileChatMessage.fromJson(item)).toList();
  }

  Future<MobileChatExchangeResponse> createChatMessage({
    required DevelopmentIdentity identity,
    required String sessionId,
    required MobileChatMessageCreateRequest request,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/mobile/chat/sessions/$sessionId/messages'),
      headers: _headers(identity),
      body: jsonEncode(request.toJson()),
    );
    final payload = _decodeMap(response);
    _ensureSuccess(response.statusCode, payload);
    return MobileChatExchangeResponse.fromJson(payload);
  }

  Future<List<MobileLinkedStudentSummary>> listParentStudents({
    required DevelopmentIdentity identity,
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/mobile/parent/students'),
      headers: _headers(identity),
    );
    final payload = _decodeList(response);
    return payload
        .map((item) => MobileLinkedStudentSummary.fromJson(item))
        .toList();
  }

  Future<AuthOnboardingState> linkGuardianStudent({
    required DevelopmentIdentity identity,
    required GuardianLinkStudentRequest request,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/auth/guardian/link-student'),
      headers: _headers(identity),
      body: jsonEncode(request.toJson()),
    );
    final payload = _decodeMap(response);
    _ensureSuccess(response.statusCode, payload);
    return AuthOnboardingState.fromJson(payload);
  }

  Future<ParentWeeklySummary> getParentWeeklySummary({
    required DevelopmentIdentity identity,
    required String studentProfileId,
  }) async {
    final response = await _httpClient.get(
      Uri.parse(
        '$_baseUrl/mobile/parent/students/$studentProfileId/weekly-summary/latest',
      ),
      headers: _headers(identity),
    );
    final payload = _decodeMap(response);
    _ensureSuccess(response.statusCode, payload);
    return ParentWeeklySummary.fromJson(payload);
  }

  Future<ParentSummaryConsentStatus> getParentSummaryConsentStatus({
    required DevelopmentIdentity identity,
    required String studentProfileId,
  }) async {
    final response = await _httpClient.get(
      Uri.parse(
        '$_baseUrl/auth/guardian/consent/parent-summary-sharing/$studentProfileId',
      ),
      headers: _headers(identity),
    );
    final payload = _decodeMap(response);
    _ensureSuccess(response.statusCode, payload);
    return ParentSummaryConsentStatus.fromJson(payload);
  }

  Future<PlatformParticipationConsentStatus>
  getPlatformParticipationConsentStatus({
    required DevelopmentIdentity identity,
    required String studentProfileId,
  }) async {
    final response = await _httpClient.get(
      Uri.parse(
        '$_baseUrl/auth/guardian/consent/platform-participation/$studentProfileId',
      ),
      headers: _headers(identity),
    );
    final payload = _decodeMap(response);
    _ensureSuccess(response.statusCode, payload);
    return PlatformParticipationConsentStatus.fromJson(payload);
  }

  Future<ParentSummaryConsentStatus> updateParentSummaryConsent({
    required DevelopmentIdentity identity,
    required ParentSummaryConsentRequest request,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/auth/guardian/consent/parent-summary-sharing'),
      headers: _headers(identity),
      body: jsonEncode(request.toJson()),
    );
    final payload = _decodeMap(response);
    _ensureSuccess(response.statusCode, payload);
    return ParentSummaryConsentStatus.fromJson(payload);
  }

  Future<AuthOnboardingState> updatePlatformParticipationConsent({
    required DevelopmentIdentity identity,
    required PlatformParticipationConsentRequest request,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/auth/guardian/consent/platform-participation'),
      headers: _headers(identity),
      body: jsonEncode(request.toJson()),
    );
    final payload = _decodeMap(response);
    _ensureSuccess(response.statusCode, payload);
    return AuthOnboardingState.fromJson(payload);
  }

  Map<String, String> _headers(DevelopmentIdentity identity) {
    return <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...identity.toHeaders(),
    };
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    if (response.body.trim().isEmpty) {
      return const <String, dynamic>{};
    }
    final decoded = _decodeJsonBody(response);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw BahaApiException(
      statusCode: response.statusCode,
      message: 'Expected a JSON object response.',
    );
  }

  List<Map<String, dynamic>> _decodeList(http.Response response) {
    if (response.body.trim().isEmpty) {
      return const <Map<String, dynamic>>[];
    }
    final decoded = _decodeJsonBody(response);
    if (decoded is List) {
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw BahaApiException(
          statusCode: response.statusCode,
          message: 'Expected an error object response.',
        );
      }
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }
    if (decoded is Map<String, dynamic>) {
      _ensureSuccess(response.statusCode, decoded);
      throw BahaApiException(
        statusCode: response.statusCode,
        message: 'Expected a JSON list response.',
      );
    }
    throw BahaApiException(
      statusCode: response.statusCode,
      message: 'Expected a JSON list response.',
    );
  }

  Object _decodeJsonBody(http.Response response) {
    try {
      return jsonDecode(response.body);
    } on FormatException {
      final rawBody = response.body.trim();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw BahaApiException(
          statusCode: response.statusCode,
          message: rawBody.isEmpty ? 'Unexpected API error.' : rawBody,
        );
      }
      throw BahaApiException(
        statusCode: response.statusCode,
        message: 'Expected a JSON response body.',
      );
    }
  }

  void _ensureSuccess(int statusCode, Map<String, dynamic> payload) {
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }
    throw BahaApiException(
      statusCode: statusCode,
      message: _extractErrorMessage(payload['detail']),
    );
  }

  String _extractErrorMessage(Object? detail) {
    if (detail is String && detail.trim().isNotEmpty) {
      return detail;
    }
    if (detail is List) {
      final messages = detail
          .map<String>((item) {
            if (item is Map) {
              final location = (item['loc'] as List<dynamic>? ?? const [])
                  .whereType<Object>()
                  .map((value) => value.toString())
                  .join(' -> ');
              final message = item['msg']?.toString().trim();
              if (message != null && message.isNotEmpty) {
                return location.isEmpty ? message : '$location: $message';
              }
            }
            return item.toString();
          })
          .where((message) => message.trim().isNotEmpty)
          .toList();
      if (messages.isNotEmpty) {
        return messages.join('\n');
      }
    }
    return 'Unexpected API error.';
  }
}
