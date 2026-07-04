import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class GameApi {
  GameApi({required this.baseUrl, required this.playerKey, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final String playerKey;
  final http.Client _client;

  Uri _uri(String path) =>
      Uri.parse('${baseUrl.replaceFirst(RegExp(r'/$'), '')}$path');

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'X-Story-Player-Key': playerKey,
  };

  Future<Map<String, dynamic>> bootstrap({
    required String displayName,
    required int ageYears,
  }) {
    return _request(
      'POST',
      '/game/players/bootstrap',
      body: {
        'player_key': playerKey,
        'display_name': displayName,
        'age_years': ageYears,
      },
      includeGameHeader: false,
    );
  }

  Future<Map<String, dynamic>> getState() => _request('GET', '/game/state');

  Future<Map<String, dynamic>> getScene(String locationId) =>
      _request('GET', '/game/stories/$locationId');

  Future<Map<String, dynamic>> submitChoice({
    required String locationId,
    required String answer,
    required int expectedChapter,
  }) {
    return _request(
      'POST',
      '/game/choices',
      body: {
        'location_id': locationId,
        'answer': answer,
        'is_custom': true,
        'expected_chapter': expectedChapter,
      },
    );
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool includeGameHeader = true,
  }) async {
    final headers = includeGameHeader
        ? _headers
        : const {'Content-Type': 'application/json'};
    late http.Response response;
    try {
      response = await switch (method) {
        'GET' => _client.get(_uri(path), headers: headers),
        'POST' => _client.post(
          _uri(path),
          headers: headers,
          body: jsonEncode(body),
        ),
        _ => throw UnsupportedError('Unsupported HTTP method $method'),
      }.timeout(const Duration(seconds: 8));
    } on TimeoutException {
      throw const GameApiException('Story server timed out.');
    } on http.ClientException catch (error) {
      throw GameApiException(
        'Could not reach the story server: ${error.message}',
      );
    }

    Map<String, dynamic> decoded = {};
    if (response.body.isNotEmpty) {
      final value = jsonDecode(response.body);
      if (value is Map<String, dynamic>) {
        decoded = value;
      }
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail =
          decoded['detail']?.toString() ??
          'Backend returned ${response.statusCode}';
      throw GameApiException(detail, statusCode: response.statusCode);
    }
    return decoded;
  }

  void close() => _client.close();
}

class GameApiException implements Exception {
  const GameApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
