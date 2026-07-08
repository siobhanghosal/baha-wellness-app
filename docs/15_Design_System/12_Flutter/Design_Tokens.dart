import 'package:flutter/material.dart';

class BahaSpacing {
  static const double s0 = 0;
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
  static const double s16 = 64;
}

class BahaRadius {
  static const BorderRadius sm = BorderRadius.all(Radius.circular(8));
  static const BorderRadius md = BorderRadius.all(Radius.circular(12));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(24));
}

class BahaColors {
  static const Color primary = Color(0xFF155EEF);
  static const Color primaryDark = Color(0xFF84ADFF);
  static const Color calm = Color(0xFF0F766E);
  static const Color textPrimary = Color(0xFF101828);
  static const Color canvas = Color(0xFFF8F6F2);
  static const Color card = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF127A4B);
  static const Color warning = Color(0xFFB54708);
  static const Color danger = Color(0xFFB42318);
  static const Color info = Color(0xFF175CD3);
}

class BahaMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 280);
  static const Curve standard = Curves.easeOutCubic;
}

class BahaElevation {
  static const double level0 = 0;
  static const double level1 = 1;
  static const double level2 = 2;
  static const double level3 = 4;
  static const double level4 = 8;
}
