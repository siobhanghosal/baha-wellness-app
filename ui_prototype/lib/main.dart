import 'package:flutter/material.dart';

import 'models/prototype_models.dart';
import 'navigation/app_router.dart';
import 'themes/app_theme.dart';
import 'themes/theme_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = ThemeController();
  await themeController.load();
  runApp(ThemeScope(
      controller: themeController, child: const BahaUiPrototypeApp()));
}

class BahaUiPrototypeApp extends StatelessWidget {
  const BahaUiPrototypeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.of(context);
    final palette =
        rolePalette(AppRole.student, isDark: themeController.isDark);
    return AnimatedTheme(
      data: buildTheme(palette),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      child: MaterialApp.router(
        title: 'BAHA UI Prototype',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(rolePalette(AppRole.student)),
        darkTheme: buildTheme(rolePalette(AppRole.student, isDark: true)),
        themeMode: themeController.themeMode,
        routerConfig: appRouter,
      ),
    );
  }
}
