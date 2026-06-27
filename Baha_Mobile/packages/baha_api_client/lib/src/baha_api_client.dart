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

  Future<AuthOnboardingState> bootstrapStudent({
    required DevelopmentIdentity identity,
    required StudentBootstrapRequest request,
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
    int limit = 20,
  }) async {
    final queryParameters = <String, String>{
      'limit': '$limit',
      if (audienceApp != null && audienceApp.isNotEmpty)
        'audience_app': audienceApp,
      if (contentType != null && contentType.isNotEmpty)
        'content_type': contentType,
      if (ageCohort != null && ageCohort.isNotEmpty) 'age_cohort': ageCohort,
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
  }) async {
    final response = await _httpClient.get(
      Uri.parse('$_baseUrl/mobile/student/modules'),
      headers: _headers(identity),
    );
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
    final decoded = jsonDecode(response.body);
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
    final decoded = jsonDecode(response.body);
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

  void _ensureSuccess(int statusCode, Map<String, dynamic> payload) {
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }
    throw BahaApiException(
      statusCode: statusCode,
      message: payload['detail'] as String? ?? 'Unexpected API error.',
    );
  }
}
