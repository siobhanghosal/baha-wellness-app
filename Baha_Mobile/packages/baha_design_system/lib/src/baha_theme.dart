import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BahaTheme {
  static ThemeData light() {
    const baseInk = Color(0xFF14323F);
    const baseSand = Color(0xFFF6F0E6);
    const accent = Color(0xFFEF7D57);
    const softBlue = Color(0xFF8FB8C9);
    final textTheme = GoogleFonts.manropeTextTheme().copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 46,
        fontWeight: FontWeight.w700,
        color: baseInk,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: baseInk,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: baseInk,
      ),
      bodyLarge: GoogleFonts.manrope(
        fontSize: 16,
        height: 1.4,
        color: baseInk,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        height: 1.35,
        color: baseInk.withValues(alpha: 0.84),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: baseSand,
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
        primary: baseInk,
        secondary: accent,
        surface: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: Colors.white,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: softBlue.withValues(alpha: 0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: baseInk, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: baseInk,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}
