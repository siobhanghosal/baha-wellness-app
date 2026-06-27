import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/material.dart';

class StudentWaitingScreen extends StatelessWidget {
  const StudentWaitingScreen({
    required this.onboardingState,
    required this.onRefresh,
    required this.onChangeIdentity,
    super.key,
  });

  final AuthOnboardingState? onboardingState;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onChangeIdentity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final state = onboardingState;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('Waiting on the next step', style: theme.headlineMedium),
              const SizedBox(height: 12),
              Text(_titleForState(state), style: theme.titleLarge),
              const SizedBox(height: 12),
              Text(_detailForState(state), style: theme.bodyLarge),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Backend status', style: theme.titleLarge),
                      const SizedBox(height: 12),
                      Text('next_step: ${state?.nextStep ?? 'unknown'}', style: theme.bodyLarge),
                      const SizedBox(height: 6),
                      Text('consent_status: ${state?.consentStatus ?? 'unknown'}', style: theme.bodyLarge),
                      const SizedBox(height: 6),
                      Text(
                        'guardian_link_status: ${state?.guardianLinkStatus ?? 'unknown'}',
                        style: theme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onRefresh,
                child: const Text('Refresh onboarding state'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onChangeIdentity,
                child: const Text('Switch development identity'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _titleForState(AuthOnboardingState? state) {
    switch (state?.nextStep) {
      case 'await_guardian_link':
        return 'A guardian still needs to link to this student.';
      case 'await_guardian_consent':
        return 'Guardian consent is still pending.';
      case 'await_activation':
        return 'The student profile exists but is not active yet.';
      default:
        return 'This account is not ready for the main app flow yet.';
    }
  }

  String _detailForState(AuthOnboardingState? state) {
    return state?.detail ??
        'The mobile app is respecting the server-side onboarding and consent rules. Once the backend returns `ready`, this flow will unlock automatically.';
  }
}
