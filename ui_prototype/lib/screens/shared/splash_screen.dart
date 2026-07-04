import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../models/prototype_models.dart';
import '../../themes/app_theme.dart';
import '../../themes/theme_manager.dart';
import '../../widgets/prototype_widgets.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette =
        rolePalette(AppRole.student, isDark: ThemeScope.of(context).isDark);
    Future.delayed(1800.ms, () {
      if (context.mounted) context.go('/roles');
    });
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                        gradient: palette.gradient,
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: [
                          BoxShadow(
                              color: palette.primary.withValues(alpha: .32),
                              blurRadius: 50)
                        ]),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 54))
                .animate()
                .scale(duration: 800.ms, curve: Curves.easeOutBack)
                .then()
                .shimmer(duration: 900.ms),
            const SizedBox(height: 24),
            Text('BAHA Wellness',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w900))
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: .2, end: 0),
            const SizedBox(height: 8),
            Text('Support before crisis. Awareness before intervention.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge)
                .animate()
                .fadeIn(delay: 400.ms),
          ]),
        ),
      ),
    );
  }
}
