import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'prototype_models.dart';

class PrototypePalette {
  const PrototypePalette({
    required this.name,
    required this.background,
    required this.surface,
    required this.text,
    required this.muted,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.gradient,
    required this.heroIcon,
    required this.story,
    this.isDark = false,
  });

  final String name;
  final Color background;
  final Color surface;
  final Color text;
  final Color muted;
  final Color primary;
  final Color secondary;
  final Color accent;
  final LinearGradient gradient;
  final IconData heroIcon;
  final String story;
  final bool isDark;
}

enum AppColorTheme {
  growth('growth', 'Growth'),
  ocean('ocean', 'Ocean'),
  sunrise('sunrise', 'Sunrise'),
  dusk('dusk', 'Dusk'),
  ember('ember', 'Ember');

  const AppColorTheme(this.storageKey, this.label);

  final String storageKey;
  final String label;

  static AppColorTheme fromStorageKey(String? value) {
    return AppColorTheme.values.firstWhere(
      (theme) => theme.storageKey == value,
      orElse: () => AppColorTheme.growth,
    );
  }
}

PrototypePalette appPaletteForTheme(
  AppColorTheme theme, {
  bool isDark = false,
}) {
  switch (theme) {
    case AppColorTheme.growth:
      return isDark
          ? const PrototypePalette(
              name: 'Growth',
              background: Color(0xFF111816),
              surface: Color(0xFF18231F),
              text: Color(0xFFF5F3EE),
              muted: Color(0xFFA8B8AE),
              primary: Color(0xFF6EE7B7),
              secondary: Color(0xFF2DD4BF),
              accent: Color(0xFFA7F3D0),
              gradient: LinearGradient(
                colors: [
                  Color(0xFF183B35),
                  Color(0xFF0F766E),
                  Color(0xFF1E3A2F),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              heroIcon: Icons.spa_rounded,
              story: 'Calm, grounded, and clean.',
              isDark: true,
            )
          : const PrototypePalette(
              name: 'Growth',
              background: Color(0xFFF5FBF8),
              surface: Color(0xFFFFFFFF),
              text: Color(0xFF123328),
              muted: Color(0xFF5E7D73),
              primary: Color(0xFF239B72),
              secondary: Color(0xFF4CBF9F),
              accent: Color(0xFF9FE3CC),
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4DBA8A),
                  Color(0xFF21A67A),
                  Color(0xFF8FDCC0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              heroIcon: Icons.spa_rounded,
              story: 'Calm, grounded, and clean.',
            );
    case AppColorTheme.ocean:
      return isDark
          ? const PrototypePalette(
              name: 'Ocean',
              background: Color(0xFF0B1824),
              surface: Color(0xFF122235),
              text: Color(0xFFF3F9FF),
              muted: Color(0xFFA7C2D8),
              primary: Color(0xFF58B8F5),
              secondary: Color(0xFF2DD4BF),
              accent: Color(0xFF93C5FD),
              gradient: LinearGradient(
                colors: [
                  Color(0xFF12395F),
                  Color(0xFF0E7490),
                  Color(0xFF155E75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              heroIcon: Icons.waves_rounded,
              story: 'Cool, airy, and focused.',
              isDark: true,
            )
          : const PrototypePalette(
              name: 'Ocean',
              background: Color(0xFFF4FAFF),
              surface: Color(0xFFFFFFFF),
              text: Color(0xFF16324A),
              muted: Color(0xFF64829B),
              primary: Color(0xFF1783D1),
              secondary: Color(0xFF29B8B1),
              accent: Color(0xFFA9D7F7),
              gradient: LinearGradient(
                colors: [
                  Color(0xFF2D9CDB),
                  Color(0xFF4FC3F7),
                  Color(0xFF7DD3C7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              heroIcon: Icons.waves_rounded,
              story: 'Cool, airy, and focused.',
            );
    case AppColorTheme.sunrise:
      return isDark
          ? const PrototypePalette(
              name: 'Sunrise',
              background: Color(0xFF23150F),
              surface: Color(0xFF312018),
              text: Color(0xFFFFF4ED),
              muted: Color(0xFFDDB69E),
              primary: Color(0xFFFF8A5B),
              secondary: Color(0xFFF8B84E),
              accent: Color(0xFFFEC89A),
              gradient: LinearGradient(
                colors: [
                  Color(0xFF7C2D12),
                  Color(0xFFB45309),
                  Color(0xFF92400E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              heroIcon: Icons.wb_sunny_rounded,
              story: 'Warm, optimistic, and bright.',
              isDark: true,
            )
          : const PrototypePalette(
              name: 'Sunrise',
              background: Color(0xFFFFF8F3),
              surface: Color(0xFFFFFFFF),
              text: Color(0xFF4B2315),
              muted: Color(0xFF9A6C56),
              primary: Color(0xFFF26C3D),
              secondary: Color(0xFFF3AE3D),
              accent: Color(0xFFFDD5A1),
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFF8A5B),
                  Color(0xFFF6B04C),
                  Color(0xFFFAD7A0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              heroIcon: Icons.wb_sunny_rounded,
              story: 'Warm, optimistic, and bright.',
            );
    case AppColorTheme.dusk:
      return isDark
          ? const PrototypePalette(
              name: 'Dusk',
              background: Color(0xFF171328),
              surface: Color(0xFF241D3A),
              text: Color(0xFFF8F5FF),
              muted: Color(0xFFC6BBE8),
              primary: Color(0xFFA78BFA),
              secondary: Color(0xFFF472B6),
              accent: Color(0xFFC4B5FD),
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4C1D95),
                  Color(0xFF6D28D9),
                  Color(0xFF9D174D),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              heroIcon: Icons.nights_stay_rounded,
              story: 'Soft, moody, and expressive.',
              isDark: true,
            )
          : const PrototypePalette(
              name: 'Dusk',
              background: Color(0xFFFBF8FF),
              surface: Color(0xFFFFFFFF),
              text: Color(0xFF322149),
              muted: Color(0xFF7F6A9A),
              primary: Color(0xFF8665E8),
              secondary: Color(0xFFE46AAE),
              accent: Color(0xFFD7CCFB),
              gradient: LinearGradient(
                colors: [
                  Color(0xFFA78BFA),
                  Color(0xFFF472B6),
                  Color(0xFFC4B5FD),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              heroIcon: Icons.nights_stay_rounded,
              story: 'Soft, moody, and expressive.',
            );
    case AppColorTheme.ember:
      return isDark
          ? const PrototypePalette(
              name: 'Ember',
              background: Color(0xFF1E1613),
              surface: Color(0xFF2A1F1A),
              text: Color(0xFFFFF7F3),
              muted: Color(0xFFD9B8A8),
              primary: Color(0xFFFF7A59),
              secondary: Color(0xFFE85757),
              accent: Color(0xFFF7B267),
              gradient: LinearGradient(
                colors: [
                  Color(0xFF7F1D1D),
                  Color(0xFFB91C1C),
                  Color(0xFF9A3412),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              heroIcon: Icons.local_fire_department_rounded,
              story: 'Energetic, bold, and vivid.',
              isDark: true,
            )
          : const PrototypePalette(
              name: 'Ember',
              background: Color(0xFFFFF8F5),
              surface: Color(0xFFFFFFFF),
              text: Color(0xFF4A271D),
              muted: Color(0xFF9B6B5C),
              primary: Color(0xFFF1643E),
              secondary: Color(0xFFE14C56),
              accent: Color(0xFFF5C27A),
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFF7A59),
                  Color(0xFFF15A5A),
                  Color(0xFFF4B860),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              heroIcon: Icons.local_fire_department_rounded,
              story: 'Energetic, bold, and vivid.',
            );
  }
}

PrototypePalette studentPalette(
  StudentAgeGroup age,
  StudentGender gender, {
  bool isDark = false,
}) {
  return appPaletteForTheme(AppColorTheme.growth, isDark: isDark);
}

ThemeData buildTheme(PrototypePalette palette) {
  final scheme = ColorScheme.fromSeed(
    seedColor: palette.primary,
    brightness: palette.isDark ? Brightness.dark : Brightness.light,
    primary: palette.primary,
    secondary: palette.secondary,
    surface: palette.surface,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.background,
    textTheme: GoogleFonts.manropeTextTheme(
      palette.isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    ).apply(bodyColor: palette.text, displayColor: palette.text),
  );
  return base.copyWith(
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface.withValues(alpha: .8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: palette.primary.withValues(alpha: .18)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(color: palette.primary.withValues(alpha: .12)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(56, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(56, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
  );
}
