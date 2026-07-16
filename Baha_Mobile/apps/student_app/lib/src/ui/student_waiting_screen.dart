import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/material.dart';

import '../prototype/app_theme.dart';
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
    final palette = appPaletteForTheme(AppColorTheme.growth);
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
            if (state?.nextStep == 'await_guardian_link') ...[
              const SizedBox(height: 18),
              GlassPanel(
                palette: palette,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Give these two details to your parent or guardian',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _WaitingCodeRow(
                      label: 'Student ID',
                      value: state?.studentCode ?? 'Not available yet',
                    ),
                    const SizedBox(height: 10),
                    _WaitingCodeRow(
                      label: 'Verification code',
                      value:
                          state?.guardianLinkVerificationCode ??
                          'Generating...',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your parent or guardian will use these in their BAHA account to link with you and approve access.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            AnimatedPrimaryButton(
              label: 'Refresh onboarding state',
              icon: Icons.refresh_rounded,
              onPressed: onRefresh,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onChangeIdentity,
              child: const Text('Log out and switch account'),
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
        'This account is still waiting for setup or approval. As soon as that is complete, the main app will unlock automatically.';
  }
}

class _WaitingCodeRow extends StatelessWidget {
  const _WaitingCodeRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
