import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/prototype_models.dart';

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

PrototypePalette studentPalette(
  StudentAgeGroup age,
  StudentGender gender, {
  bool isDark = false,
}) {
  if (!isDark) {
    if (age == StudentAgeGroup.child && gender == StudentGender.male) {
      return const PrototypePalette(
        name: 'Adventure Island',
        background: Color(0xFFF0FBFF),
        surface: Color(0xFFFFFFFF),
        text: Color(0xFF123047),
        muted: Color(0xFF5F7A8C),
        primary: Color(0xFF0284C7),
        secondary: Color(0xFF38BDF8),
        accent: Color(0xFFF59E0B),
        gradient: LinearGradient(
            colors: [Color(0xFF0EA5E9), Color(0xFF22D3EE), Color(0xFFA7F3D0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        heroIcon: Icons.explore_rounded,
        story:
            'Sky islands, treasure maps, clouds, and friendly adventure energy.',
      );
    }
    if (age == StudentAgeGroup.child && gender == StudentGender.female) {
      return const PrototypePalette(
        name: 'Magic Castle',
        background: Color(0xFFFFF7FB),
        surface: Color(0xFFFFFFFF),
        text: Color(0xFF442044),
        muted: Color(0xFF8B5F88),
        primary: Color(0xFFEC4899),
        secondary: Color(0xFFC084FC),
        accent: Color(0xFFFBBF24),
        gradient: LinearGradient(
            colors: [Color(0xFFF9A8D4), Color(0xFFC4B5FD), Color(0xFFFDE68A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        heroIcon: Icons.castle_rounded,
        story:
            'Princess-inspired warmth with lavender, gold, sparkles, and soft magic.',
      );
    }
    if (age == StudentAgeGroup.teen && gender == StudentGender.male) {
      return const PrototypePalette(
        name: 'Neon Quest',
        background: Color(0xFFF4F8FF),
        surface: Color(0xFFFFFFFF),
        text: Color(0xFF132238),
        muted: Color(0xFF5E7492),
        primary: Color(0xFF3B82F6),
        secondary: Color(0xFF8B5CF6),
        accent: Color(0xFF22D3EE),
        gradient: LinearGradient(
            colors: [Color(0xFF60A5FA), Color(0xFF818CF8), Color(0xFF22D3EE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        heroIcon: Icons.sports_esports_rounded,
        story:
            'Gaming-inspired energy with neon gradients, XP cards, and smooth motion.',
      );
    }
    if (age == StudentAgeGroup.teen && gender == StudentGender.female) {
      return const PrototypePalette(
        name: 'Glow Social',
        background: Color(0xFFFFF6FA),
        surface: Color(0xFFFFFFFF),
        text: Color(0xFF331827),
        muted: Color(0xFF9D5C7C),
        primary: Color(0xFFDB2777),
        secondary: Color(0xFF9333EA),
        accent: Color(0xFFFB7185),
        gradient: LinearGradient(
            colors: [Color(0xFFFF6B9E), Color(0xFFA855F7), Color(0xFFFF8A65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        heroIcon: Icons.auto_awesome_rounded,
        story: 'Pinterest-meets-Instagram glassmorphism, vibrant but mature.',
      );
    }
    return const PrototypePalette(
      name: 'Personal Growth',
      background: Color(0xFFF8FAFC),
      surface: Color(0xFFFFFFFF),
      text: Color(0xFF0F172A),
      muted: Color(0xFF64748B),
      primary: Color(0xFF2563EB),
      secondary: Color(0xFF14B8A6),
      accent: Color(0xFF64748B),
      gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      heroIcon: Icons.spa_rounded,
      story:
          'Apple Health inspired clarity with quiet confidence and premium calm.',
    );
  }

  if (age == StudentAgeGroup.child && gender == StudentGender.male) {
    return const PrototypePalette(
      name: 'Adventure Island',
      background: Color(0xFF071B33),
      surface: Color(0xFF0E2A47),
      text: Color(0xFFEAF8FF),
      muted: Color(0xFF9CC9DD),
      primary: Color(0xFF38BDF8),
      secondary: Color(0xFF0EA5E9),
      accent: Color(0xFFFBBF24),
      gradient: LinearGradient(
          colors: [Color(0xFF075985), Color(0xFF0369A1), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      heroIcon: Icons.explore_rounded,
      story:
          'Sky islands, treasure maps, clouds, and friendly adventure energy.',
      isDark: true,
    );
  }
  if (age == StudentAgeGroup.child && gender == StudentGender.female) {
    return const PrototypePalette(
      name: 'Magic Castle',
      background: Color(0xFF2A102A),
      surface: Color(0xFF3B173B),
      text: Color(0xFFFFF2FB),
      muted: Color(0xFFD8A7D7),
      primary: Color(0xFFF472B6),
      secondary: Color(0xFFC084FC),
      accent: Color(0xFFFACC15),
      gradient: LinearGradient(
          colors: [Color(0xFF9D174D), Color(0xFF6D28D9), Color(0xFFB45309)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      heroIcon: Icons.castle_rounded,
      story:
          'Princess-inspired warmth with lavender, gold, sparkles, and soft magic.',
      isDark: true,
    );
  }
  if (age == StudentAgeGroup.teen && gender == StudentGender.male) {
    return const PrototypePalette(
      name: 'Neon Quest',
      background: Color(0xFF070B18),
      surface: Color(0xFF10172A),
      text: Color(0xFFF8FAFC),
      muted: Color(0xFFA5B4FC),
      primary: Color(0xFF60A5FA),
      secondary: Color(0xFFA78BFA),
      accent: Color(0xFF22D3EE),
      gradient: LinearGradient(
          colors: [Color(0xFF172554), Color(0xFF4C1D95), Color(0xFF155E75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      heroIcon: Icons.sports_esports_rounded,
      story:
          'Gaming-inspired energy with neon gradients, XP cards, and smooth motion.',
      isDark: true,
    );
  }
  if (age == StudentAgeGroup.teen && gender == StudentGender.female) {
    return const PrototypePalette(
      name: 'Glow Social',
      background: Color(0xFF251226),
      surface: Color(0xFF351936),
      text: Color(0xFFFFF4FB),
      muted: Color(0xFFE0A4C7),
      primary: Color(0xFFF472B6),
      secondary: Color(0xFFC084FC),
      accent: Color(0xFFFB7185),
      gradient: LinearGradient(
          colors: [Color(0xFF831843), Color(0xFF581C87), Color(0xFFBE123C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight),
      heroIcon: Icons.auto_awesome_rounded,
      story: 'Pinterest-meets-Instagram glassmorphism, vibrant but mature.',
      isDark: true,
    );
  }
  return const PrototypePalette(
    name: 'Personal Growth',
    background: Color(0xFF111816),
    surface: Color(0xFF18231F),
    text: Color(0xFFF5F3EE),
    muted: Color(0xFFA8B8AE),
    primary: Color(0xFF6EE7B7),
    secondary: Color(0xFF2DD4BF),
    accent: Color(0xFFA7B3C2),
    gradient: LinearGradient(
        colors: [Color(0xFF193B35), Color(0xFF0F766E), Color(0xFF334155)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight),
    heroIcon: Icons.spa_rounded,
    story:
        'Apple Health inspired clarity with quiet confidence and premium calm.',
    isDark: true,
  );
}

PrototypePalette rolePalette(AppRole role, {bool isDark = false}) =>
    switch (role) {
      AppRole.student => studentPalette(
          StudentAgeGroup.teen, StudentGender.female,
          isDark: isDark),
      AppRole.parent => isDark
          ? const PrototypePalette(
              name: 'Family Clarity',
              background: Color(0xFF071A20),
              surface: Color(0xFF102A33),
              text: Color(0xFFEAFDFC),
              muted: Color(0xFF9AC8C5),
              primary: Color(0xFF2DD4BF),
              secondary: Color(0xFF38BDF8),
              accent: Color(0xFFFBBF24),
              gradient: LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF0F3B57)]),
              heroIcon: Icons.family_restroom_rounded,
              story: 'Premium parent clarity with consent-first summaries.',
              isDark: true)
          : const PrototypePalette(
              name: 'Family Clarity',
              background: Color(0xFFF8FAFC),
              surface: Colors.white,
              text: Color(0xFF102033),
              muted: Color(0xFF64748B),
              primary: Color(0xFF2563EB),
              secondary: Color(0xFF14B8A6),
              accent: Color(0xFFF59E0B),
              gradient: LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF14B8A6)]),
              heroIcon: Icons.family_restroom_rounded,
              story: 'Premium parent clarity with consent-first summaries.'),
      AppRole.teacher => isDark
          ? const PrototypePalette(
              name: 'School Pulse',
              background: Color(0xFF0B1220),
              surface: Color(0xFF111C31),
              text: Color(0xFFF2F8FF),
              muted: Color(0xFF9DB4D0),
              primary: Color(0xFF818CF8),
              secondary: Color(0xFF38BDF8),
              accent: Color(0xFFF97316),
              gradient: LinearGradient(
                  colors: [Color(0xFF312E81), Color(0xFF0F4C81)]),
              heroIcon: Icons.school_rounded,
              story: 'Modern school dashboard with pastoral calm.',
              isDark: true)
          : const PrototypePalette(
              name: 'School Pulse',
              background: Color(0xFFF6FBFF),
              surface: Colors.white,
              text: Color(0xFF102A43),
              muted: Color(0xFF627D98),
              primary: Color(0xFF0EA5E9),
              secondary: Color(0xFF22C55E),
              accent: Color(0xFFF97316),
              gradient: LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF22C55E)]),
              heroIcon: Icons.school_rounded,
              story: 'Modern school dashboard with pastoral calm.'),
      AppRole.admin => isDark
          ? const PrototypePalette(
              name: 'BAHA Command',
              background: Color(0xFF030712),
              surface: Color(0xFF0B1120),
              text: Color(0xFFF8FAFC),
              muted: Color(0xFF94A3B8),
              primary: Color(0xFF38BDF8),
              secondary: Color(0xFFA78BFA),
              accent: Color(0xFFFBBF24),
              gradient: LinearGradient(colors: [
                Color(0xFF020617),
                Color(0xFF172554),
                Color(0xFF3B0764)
              ]),
              heroIcon: Icons.admin_panel_settings_rounded,
              story: 'Enterprise-grade operational dashboard.',
              isDark: true)
          : const PrototypePalette(
              name: 'BAHA Command',
              background: Color(0xFF070B16),
              surface: Color(0xFF111827),
              text: Color(0xFFF8FAFC),
              muted: Color(0xFF94A3B8),
              primary: Color(0xFF38BDF8),
              secondary: Color(0xFFA78BFA),
              accent: Color(0xFFFBBF24),
              gradient: LinearGradient(colors: [
                Color(0xFF111827),
                Color(0xFF1E3A8A),
                Color(0xFF581C87)
              ]),
              heroIcon: Icons.admin_panel_settings_rounded,
              story: 'Enterprise-grade operational dashboard.',
              isDark: true),
    };

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
    textTheme: GoogleFonts.manropeTextTheme(palette.isDark
            ? ThemeData.dark().textTheme
            : ThemeData.light().textTheme)
        .apply(bodyColor: palette.text, displayColor: palette.text),
  );
  return base.copyWith(
    cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface.withValues(alpha: .8),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide:
                BorderSide(color: palette.primary.withValues(alpha: .18))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide:
                BorderSide(color: palette.primary.withValues(alpha: .12)))),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            minimumSize: const Size(56, 54),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            minimumSize: const Size(56, 54),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)))),
  );
}
