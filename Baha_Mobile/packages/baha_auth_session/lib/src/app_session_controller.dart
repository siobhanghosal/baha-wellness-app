import 'package:baha_api_client/baha_api_client.dart';
import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'session_stage.dart';

class AppSessionController extends ChangeNotifier {
  AppSessionController({
    required BahaApiClient apiClient,
  })
      // ignore: prefer_initializing_formals
      : _apiClient = apiClient;

  static const _externalAuthIdKey = 'baha.dev.external_auth_id';
  static const _authEmailKey = 'baha.dev.auth_email';

  final BahaApiClient _apiClient;

  SessionStage _stage = SessionStage.splash;
  DevelopmentIdentity? _identity;
  AuthOnboardingState? _onboardingState;
  MobileActor? _actor;
  String? _errorMessage;

  SessionStage get stage => _stage;
  DevelopmentIdentity? get identity => _identity;
  AuthOnboardingState? get onboardingState => _onboardingState;
  MobileActor? get actor => _actor;
  String? get errorMessage => _errorMessage;

  Future<void> restoreSession() async {
    _setStage(SessionStage.splash);
    final preferences = await SharedPreferences.getInstance();
    final externalAuthId = preferences.getString(_externalAuthIdKey)?.trim();
    final authEmail = preferences.getString(_authEmailKey)?.trim();
    if (externalAuthId == null || externalAuthId.isEmpty) {
      _identity = null;
      _onboardingState = null;
      _actor = null;
      _errorMessage = null;
      _setStage(SessionStage.requiresIdentity);
      return;
    }
    _identity = DevelopmentIdentity(
      externalAuthId: externalAuthId,
      authEmail: authEmail == null || authEmail.isEmpty ? null : authEmail,
    );
    await refreshOnboarding();
  }

  Future<void> saveIdentity(DevelopmentIdentity identity) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_externalAuthIdKey, identity.externalAuthId);
    final email = identity.authEmail?.trim();
    if (email != null && email.isNotEmpty) {
      await preferences.setString(_authEmailKey, email);
    } else {
      await preferences.remove(_authEmailKey);
    }
    _identity = identity;
    await refreshOnboarding();
  }

  Future<void> clearIdentity() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_externalAuthIdKey);
    await preferences.remove(_authEmailKey);
    _identity = null;
    _onboardingState = null;
    _actor = null;
    _errorMessage = null;
    _setStage(SessionStage.requiresIdentity);
  }

  Future<void> refreshOnboarding() async {
    final identity = _identity;
    if (identity == null) {
      _setStage(SessionStage.requiresIdentity);
      return;
    }
    try {
      _errorMessage = null;
      _onboardingState = await _apiClient.getOnboardingState(identity: identity);
      if (_onboardingState!.isReady) {
        _actor = await _apiClient.getMobileMe(identity: identity);
        _setStage(SessionStage.ready);
        return;
      }
      _actor = null;
      if (_onboardingState!.requiresBootstrap) {
        _setStage(SessionStage.requiresBootstrap);
        return;
      }
      _setStage(SessionStage.waiting);
    } on BahaApiException catch (error) {
      _actor = null;
      _errorMessage = error.message;
      _setStage(SessionStage.failure);
    } catch (error) {
      _actor = null;
      _errorMessage = 'Unexpected session error: $error';
      _setStage(SessionStage.failure);
    }
  }

  Future<void> bootstrapStudent(StudentBootstrapRequest request) async {
    final identity = _identity;
    if (identity == null) {
      _setStage(SessionStage.requiresIdentity);
      return;
    }
    try {
      _errorMessage = null;
      _onboardingState = await _apiClient.bootstrapStudent(
        identity: identity,
        request: request,
      );
      if (_onboardingState!.isReady) {
        _actor = await _apiClient.getMobileMe(identity: identity);
        _setStage(SessionStage.ready);
        return;
      }
      _setStage(
        _onboardingState!.requiresBootstrap
            ? SessionStage.requiresBootstrap
            : SessionStage.waiting,
      );
    } on BahaApiException catch (error) {
      _errorMessage = error.message;
      _setStage(SessionStage.failure);
    } catch (error) {
      _errorMessage = 'Unexpected bootstrap error: $error';
      _setStage(SessionStage.failure);
    }
  }

  void _setStage(SessionStage stage) {
    _stage = stage;
    notifyListeners();
  }
}
