import 'package:baha_api_client/baha_api_client.dart';
import 'package:baha_auth_session/baha_auth_session.dart';
import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/material.dart';

import 'app_environment.dart';
import 'prototype/app_theme.dart';
import 'prototype/prototype_widgets.dart';
import 'ui/student_bootstrap_screen.dart';
import 'ui/student_error_screen.dart';
import 'ui/student_identity_screen.dart';
import 'ui/student_waiting_screen.dart';
import 'ui/unified_role_home_screen.dart';

class StudentAppEntryPoint extends StatefulWidget {
  const StudentAppEntryPoint({super.key});

  @override
  State<StudentAppEntryPoint> createState() => _StudentAppEntryPointState();
}

class _StudentAppEntryPointState extends State<StudentAppEntryPoint> {
  late final StudentAppEnvironment _environment;
  late final BahaApiClient _apiClient;
  late final AppSessionController _sessionController;

  @override
  void initState() {
    super.initState();
    _environment = StudentAppEnvironment.fromDefines();
    _apiClient = BahaApiClient(baseUrl: _environment.apiBaseUrl);
    _sessionController = AppSessionController(apiClient: _apiClient)
      ..restoreSession();
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final basePalette = appPaletteForTheme(AppColorTheme.growth);
    return MaterialApp(
      title: 'BAHA',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(basePalette),
      home: AnimatedBuilder(
        animation: _sessionController,
        builder: (context, child) {
          switch (_sessionController.stage) {
            case SessionStage.splash:
              return const _StudentSplashScreen();
            case SessionStage.requiresIdentity:
              return StudentIdentityScreen(
                defaultExternalAuthId: _environment.defaultExternalAuthId,
                defaultPassword: _environment.defaultPassword,
                apiBaseUrl: _environment.apiBaseUrl,
                onSubmit: (identity, mode) => _sessionController.attemptEntry(
                  identity,
                  registerMode: mode == AppEntryMode.register,
                ),
              );
            case SessionStage.requiresBootstrap:
              return StudentBootstrapScreen(
                identity: _sessionController.identity!,
                errorMessage: _sessionController.errorMessage,
                onSubmit: (request) => _sessionController.bootstrap(request),
                onChangeIdentity: _sessionController.clearIdentity,
              );
            case SessionStage.waiting:
              final onboardingState = _sessionController.onboardingState;
              final identity = _sessionController.identity!;
              if (onboardingState?.nextStep == 'link_student' &&
                  identity.requestedRole == AppRequestedRole.guardian) {
                return GuardianLinkWaitingScreen(
                  apiClient: _apiClient,
                  identity: identity,
                  onboardingState: onboardingState,
                  onRefresh: _sessionController.refreshOnboarding,
                  onChangeIdentity: _sessionController.clearIdentity,
                );
              }
              return StudentWaitingScreen(
                onboardingState: onboardingState,
                onRefresh: _sessionController.refreshOnboarding,
                onChangeIdentity: _sessionController.clearIdentity,
              );
            case SessionStage.ready:
              return UnifiedRoleHomeScreen(
                apiClient: _apiClient,
                identity: _sessionController.identity!,
                environment: _environment,
                actor: _sessionController.actor,
                onboardingState: _sessionController.onboardingState,
                onRefresh: _sessionController.refreshOnboarding,
                onClearIdentity: _sessionController.clearIdentity,
              );
            case SessionStage.failure:
              return StudentErrorScreen(
                errorMessage: _sessionController.errorMessage,
                onRetry: _sessionController.refreshOnboarding,
                onResetIdentity: _sessionController.clearIdentity,
              );
          }
        },
      ),
    );
  }
}

class _StudentSplashScreen extends StatelessWidget {
  const _StudentSplashScreen();

  @override
  Widget build(BuildContext context) {
    final palette = appPaletteForTheme(AppColorTheme.growth);
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 24),
              Text('BAHA', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Restoring session and checking onboarding state.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
