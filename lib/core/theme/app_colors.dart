import 'package:flutter/material.dart';
import 'package:sadeem_ui/sadeem_ui.dart';

/// ألوان التطبيق: أسماء محلية تشير لألوان سديم المشتركة (sadeem_ui)، فتغيير اللون يتم في مكان واحد.
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color primary = SColors.brand;
  static const Color primaryDark = SColors.brandDark;
  static const Color primaryLight = SColors.brandSoft;

  // Status & Operational Colors
  static const Color onlineGreen = SColors.emerald500;
  static const Color onlineGreenLight = Color(0xFFE6F9F0);
  static const Color offlineRed = SColors.red500;
  static const Color offlineRedLight = SColors.red100;
  static const Color busyOrange = SColors.amber500;
  static const Color busyOrangeLight = SColors.amber100;

  // Background & Surface
  static const Color background = SColors.slate50;
  static const Color surface = Colors.white;
  static const Color darkCard = SColors.slate900;
  static const Color darkCardSecondary = SColors.slate800;

  // Text Colors
  static const Color textPrimary = SColors.slate900;
  static const Color textSecondary = SColors.slate500;
  static const Color textLight = SColors.slate400;
  static const Color textWhite = Colors.white;

  // Borders & Accents
  static const Color border = SColors.slate200;
  static const Color borderLight = SColors.slate100;
  static const Color divider = SColors.slate200;

  // Functional Accents
  static const Color gold = SColors.amber500;
  static const Color cyan = SColors.cyan500;
  static const Color purple = SColors.violet500;
}
