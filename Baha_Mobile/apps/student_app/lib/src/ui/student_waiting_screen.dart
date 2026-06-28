import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/material.dart';

import '../prototype/app_theme.dart';
import '../prototype/prototype_models.dart';
import '../prototype/prototype_widgets.dart';

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
    final state = onboardingState;
    final palette = studentPalette(StudentAgeGroup.teen, StudentGender.female);
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            HeroHeader(
              palette: palette,
              kicker: 'Onboarding',
              title: _titleForState(state),
              subtitle: _detailForState(state),
              actions: const [
                Pill(icon: Icons.hourglass_top_rounded, label: 'Waiting'),
                Pill(icon: Icons.verified_user_rounded, label: 'Server gated'),
              ],
            ),
            const SizedBox(height: 18),
            GlassPanel(
              palette: palette,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Backend status',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('next_step: ${state?.nextStep ?? 'unknown'}'),
                  const SizedBox(height: 6),
                  Text('consent_status: ${state?.consentStatus ?? 'unknown'}'),
                  const SizedBox(height: 6),
                  Text(
                    'guardian_link_status: ${state?.guardianLinkStatus ?? 'unknown'}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AnimatedPrimaryButton(
              label: 'Refresh onboarding state',
              icon: Icons.refresh_rounded,
              onPressed: onRefresh,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onChangeIdentity,
              child: const Text('Switch development identity'),
            ),
          ],
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
