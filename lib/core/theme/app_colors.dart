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
  // درجات أغمق: نص أبيض فوقها يتجاوز تباين 4.5:1 (كان الأخضر والبرتقالي الفاتحان يصعب قراءتهما)
  static const Color onlineGreen = SColors.emerald700;
  static const Color onlineGreenLight = Color(0xFFE6F4EE);
  static const Color offlineRed = SColors.red500;
  static const Color offlineRedLight = SColors.red100;
  static const Color busyOrange = SColors.amber700;
  static const Color busyOrangeLight = SColors.amber100;

  // Background & Surface
  static const Color background = Color(0xFFF5F6FA);
  static const Color surface = Colors.white;
  static const Color darkCard = SColors.slate900;
  static const Color darkCardSecondary = SColors.slate800;

  // Text Colors
  static const Color textPrimary = SColors.slate900;
  static const Color textSecondary = SColors.slate600;
  static const Color textLight = SColors.slate500;
  static const Color textWhite = Colors.white;

  // Borders & Accents
  static const Color border = SColors.slate200;
  static const Color borderLight = SColors.slate100;
  static const Color divider = SColors.slate200;

  // Functional Accents
  static const Color gold = SColors.amber700;
  static const Color cyan = SColors.cyan500;
  static const Color purple = SColors.violet500;

  // ألوان التصميم الجديد
  static const Color navy = Color(0xFF283A75); // الأزرار الرئيسية وبطاقات المال
  static const Color navySoft = Color(0xFFE8ECF7);
  static const Color navyText = Color(0xFFDCE2F5); // نص ثانوي فوق الكحلي
  static const Color cash = Color(0xFFB4401A); // المبلغ المطلوب تحصيله
  static const Color cashText = Color(0xFF7C2D12);
  static const Color cashSoft = Color(0xFFFDEBE3);
  static const Color readySoft = Color(0xFFFEF3C7); // شريط "جاهز للاستلام"
  static const Color readyText = Color(0xFF78350F);
  static const Color successText = Color(0xFF065F46);
  static const Color line = Color(0xFFE2E6F0);
}
