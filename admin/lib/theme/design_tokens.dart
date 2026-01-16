import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Bases
  static const Color background = Color(0xFFF6F9FE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0F6FF);

  // Brand
  static const Color primary = Color(0xFF10AA2E);
  static const Color primarySoft = Color(0xFFDFF8E5);
  static const Color accent = Color(0xFF0B8837);

  // Neutrals
  static const Color textPrimary = Color(0xFF1F2933);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFEDEFF2);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);
}

class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadii {
  AppRadii._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
}

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> primary = <BoxShadow>[
    BoxShadow(
      color: Color(0x14212535),
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> subtle = <BoxShadow>[
    BoxShadow(
      color: Color(0x0F1F2937),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];
}

class AppDurations {
  AppDurations._();

  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
}
