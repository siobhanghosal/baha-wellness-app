import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../models/prototype_models.dart';
import '../../themes/app_theme.dart';
import '../../themes/theme_manager.dart';
import '../../widgets/prototype_widgets.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette =
        rolePalette(AppRole.parent, isDark: ThemeScope.of(context).isDark);
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: ListView(padding: const EdgeInsets.all(22), children: [
          HeroHeader(
              palette: palette,
              kicker: 'Choose an experience',
              title: 'Four apps. One trusted wellness ecosystem.',
              subtitle:
                  'This prototype uses fake data, but every interaction is navigable and demo-ready.',
              actions: const [
                Pill(icon: Icons.lock_rounded, label: 'Offline UI'),
                Pill(icon: Icons.bolt_rounded, label: 'Fully clickable')
              ]),
          const SizedBox(height: 22),
          ...AppRole.values.indexed.map((entry) {
            final role = entry.$2;
            final rolePal =
                rolePalette(role, isDark: ThemeScope.of(context).isDark);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GlassPanel(
                palette: palette,
                onTap: () => context.go('/login/${role.slug}'),
                child: Row(children: [
                  Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                          gradient: rolePal.gradient,
                          borderRadius: BorderRadius.circular(20)),
                      child: Icon(role.icon, color: Colors.white)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(role.label,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 5),
                        Text(role.pitch)
                      ])),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                ]),
              )
                  .animate(delay: (entry.$1 * 90).ms)
                  .fadeIn()
                  .slideX(begin: .1, end: 0),
            );
          }),
        ]),
      ),
    );
  }
}
