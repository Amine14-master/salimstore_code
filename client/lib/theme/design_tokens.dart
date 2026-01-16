import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFFF6F9FE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF9FAFB);

  static const Color primary = Color(0xFF10AA2E);
  static const Color primarySoft = Color(0xFFE6F6EB);
  static const Color accent = Color(0xFF3B82F6);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFEFF1F5);

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
  static const double lg = 20;
  static const double xl = 28;
  static const double xxl = 40;
}

class AppRadii {
  AppRadii._();

  static const double xs = 10;
  static const double sm = 14;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 30;
}

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> raised = <BoxShadow>[
    BoxShadow(
      color: Color(0x1416273B),
      offset: Offset(0, 10),
      blurRadius: 30,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> subtle = <BoxShadow>[
    BoxShadow(
      color: Color(0x0F1F2937),
      offset: Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];
}

class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 140);
  static const Duration medium = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 360);
}
