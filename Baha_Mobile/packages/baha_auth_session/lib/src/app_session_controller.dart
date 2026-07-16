import 'package:baha_api_client/baha_api_client.dart';
import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'session_stage.dart';

class AppSessionController extends ChangeNotifier {
  AppSessionController({required BahaApiClient apiClient})
    // ignore: prefer_initializing_formals
    : _apiClient = apiClient;

  static const _externalAuthIdKey = 'baha.dev.external_auth_id';
  static const _authPasswordKey = 'baha.dev.password';
  static const _requestedRoleKey = 'baha.dev.requested_role';

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
    final password = preferences.getString(_authPasswordKey)?.trim();
    final requestedRole = AppRequestedRole.fromApiValue(
      preferences.getString(_requestedRoleKey),
    );
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
      password: password == null || password.isEmpty ? null : password,
      requestedRole: requestedRole,
    );
    await refreshOnboarding();
  }

  Future<void> saveIdentity(DevelopmentIdentity identity) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_externalAuthIdKey, identity.externalAuthId);
    final password = identity.password?.trim();
    if (password != null && password.isNotEmpty) {
      await preferences.setString(_authPasswordKey, password);
    } else {
      await preferences.remove(_authPasswordKey);
    }
    await preferences.setString(
      _requestedRoleKey,
      identity.requestedRole.apiValue,
    );
    _identity = identity;
    await refreshOnboarding();
  }

  Future<String?> attemptEntry(
    DevelopmentIdentity identity, {
    required bool registerMode,
  }) async {
    try {
      final onboardingState = await _apiClient.getOnboardingState(
        identity: identity,
        entryMode: registerMode ? 'register' : 'sign_in',
      );
      final validationMessage = registerMode
          ? _registrationMessageFor(onboardingState)
          : _signInMessageFor(onboardingState);
      if (validationMessage != null) {
        return validationMessage;
      }
      await saveIdentity(identity);
      return null;
    } on BahaApiException catch (error) {
      return error.message;
    } catch (error) {
      return 'Unexpected authentication error: $error';
    }
  }

  Future<void> clearIdentity() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_externalAuthIdKey);
    await preferences.remove(_authPasswordKey);
    await preferences.remove(_requestedRoleKey);
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
      _onboardingState = await _apiClient.getOnboardingState(
        identity: identity,
      );
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

  Future<void> bootstrap(AppBootstrapRequest request) async {
    final identity = _identity;
    if (identity == null) {
      _setStage(SessionStage.requiresIdentity);
      return;
    }
    try {
      _errorMessage = null;
      _onboardingState = await _apiClient.bootstrapIdentity(
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
      _setStage(SessionStage.requiresBootstrap);
    } catch (error) {
      _errorMessage = 'Unexpected bootstrap error: $error';
      _setStage(SessionStage.failure);
    }
  }

  Future<void> bootstrapStudent(StudentBootstrapRequest request) {
    return bootstrap(request);
  }

  void _setStage(SessionStage stage) {
    _stage = stage;
    notifyListeners();
  }

  String? _signInMessageFor(AuthOnboardingState state) {
    switch (state.identityMatchMode) {
      case 'external_auth_id':
        return null;
      default:
        return 'We could not find an account for this sign-in ID. Check the details or create a new account.';
    }
  }

  String? _registrationMessageFor(AuthOnboardingState state) {
    switch (state.identityMatchMode) {
      case 'external_auth_id':
        if (state.requiresBootstrap) {
          return 'This sign-in ID is already tied to an unfinished BAHA account. Continue with that account or use a different sign-in ID.';
        }
        return 'This sign-in ID is already in use. Sign in instead or choose a different sign-in ID.';
      default:
        return null;
    }
  }
}
