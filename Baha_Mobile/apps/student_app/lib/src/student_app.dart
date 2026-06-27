import 'package:baha_api_client/baha_api_client.dart';
import 'package:baha_auth_session/baha_auth_session.dart';
import 'package:baha_design_system/baha_design_system.dart';
import 'package:flutter/material.dart';

import 'app_environment.dart';
import 'ui/student_bootstrap_screen.dart';
import 'ui/student_error_screen.dart';
import 'ui/student_identity_screen.dart';
import 'ui/student_ready_screen.dart';
import 'ui/student_waiting_screen.dart';

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
    return MaterialApp(
      title: 'BAHA Student',
      debugShowCheckedModeBanner: false,
      theme: BahaTheme.light(),
      home: AnimatedBuilder(
        animation: _sessionController,
        builder: (context, child) {
          switch (_sessionController.stage) {
            case SessionStage.splash:
              return const _StudentSplashScreen();
            case SessionStage.requiresIdentity:
              return StudentIdentityScreen(
                defaultExternalAuthId: _environment.defaultExternalAuthId,
                defaultAuthEmail: _environment.defaultAuthEmail,
                apiBaseUrl: _environment.apiBaseUrl,
                onSubmit: (identity) =>
                    _sessionController.saveIdentity(identity),
              );
            case SessionStage.requiresBootstrap:
              return StudentBootstrapScreen(
                initialEmail: _sessionController.identity?.authEmail,
                externalAuthId:
                    _sessionController.identity?.externalAuthId ?? '',
                onSubmit: (request) =>
                    _sessionController.bootstrapStudent(request),
                onChangeIdentity: _sessionController.clearIdentity,
              );
            case SessionStage.waiting:
              return StudentWaitingScreen(
                onboardingState: _sessionController.onboardingState,
                onRefresh: _sessionController.refreshOnboarding,
                onChangeIdentity: _sessionController.clearIdentity,
              );
            case SessionStage.ready:
              return StudentReadyScreen(
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
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF6F0E6), Color(0xFFE4EEF2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
              Text('BAHA Student', style: theme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Restoring session and checking onboarding state.',
                style: theme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
