import 'package:flutter/material.dart';

import '../prototype/app_theme.dart';
import '../prototype/prototype_widgets.dart';

class StudentErrorScreen extends StatelessWidget {
  const StudentErrorScreen({
    required this.errorMessage,
    required this.onRetry,
    required this.onResetIdentity,
    super.key,
  });

  final String? errorMessage;
  final Future<void> Function() onRetry;
  final Future<void> Function() onResetIdentity;

  @override
  Widget build(BuildContext context) {
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
              kicker: 'Session error',
              title: 'The student app could not open cleanly.',
              subtitle:
                  errorMessage ??
                  'The app could not complete the startup flow.',
              actions: const [
                Pill(icon: Icons.warning_rounded, label: 'Retry needed'),
                Pill(icon: Icons.medical_information_rounded, label: 'Backend'),
              ],
            ),
            const SizedBox(height: 18),
            AnimatedPrimaryButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onResetIdentity,
              child: const Text('Reset development identity'),
            ),
          ],
        ),
      ),
    );
  }
}
