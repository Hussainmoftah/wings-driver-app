import 'package:flutter/material.dart';

/// ألوان تصميم السائق بنسختين، نهارية وليلية، وكلها بتباين 4.5:1 على الأقل للنص.
/// الشاشات تأخذ ألوانها من هنا بدل ألوان ثابتة فاتحة (كانت النصوص تختفي في الوضع الليلي).
class DriverPalette {
  final Color ground; // خلفية الشاشة
  final Color surface; // البطاقات
  final Color surfaceMuted; // صناديق داخل البطاقات
  final Color ink; // النص الأساسي
  final Color body; // النص العادي
  final Color muted; // العناوين الصغيرة والشروح
  final Color line; // الحدود والفواصل
  final Color field; // خلفية خانات الإدخال
  final Color fieldBorder;
  final Color navy; // الأزرار الرئيسية (نص أبيض)
  final Color navyCard; // بطاقة المال
  final Color navySoft; // شرائط وأزرار ثانوية
  final Color navyInk; // نص فوق navySoft وحدود الأزرار الثانوية
  final Color onNavyMuted; // نص ثانوي فوق الكحلي
  final Color cash; // إطار المبلغ المطلوب تحصيله
  final Color cashText;
  final Color cashSoft;
  final Color readySoft;
  final Color readyText;
  final Color successSoft;
  final Color successText;
  final Color successCard; // بطاقة "مستحق لك"
  final Color errorSoft;
  final Color errorText;
  final Color disabled;
  final Color disabledText;

  const DriverPalette._({
    required this.ground,
    required this.surface,
    required this.surfaceMuted,
    required this.ink,
    required this.body,
    required this.muted,
    required this.line,
    required this.field,
    required this.fieldBorder,
    required this.navy,
    required this.navyCard,
    required this.navySoft,
    required this.navyInk,
    required this.onNavyMuted,
    required this.cash,
    required this.cashText,
    required this.cashSoft,
    required this.readySoft,
    required this.readyText,
    required this.successSoft,
    required this.successText,
    required this.successCard,
    required this.errorSoft,
    required this.errorText,
    required this.disabled,
    required this.disabledText,
  });

  static const light = DriverPalette._(
    ground: Color(0xFFF5F6FA),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF1F3F8),
    ink: Color(0xFF0F172A),
    body: Color(0xFF334155),
    muted: Color(0xFF475569),
    line: Color(0xFFE2E6F0),
    field: Color(0xFFFFFFFF),
    fieldBorder: Color(0xFFCBD2E1),
    navy: Color(0xFF283A75),
    navyCard: Color(0xFF283A75),
    navySoft: Color(0xFFE8ECF7),
    navyInk: Color(0xFF283A75),
    onNavyMuted: Color(0xFFDCE2F5),
    cash: Color(0xFFB4401A),
    cashText: Color(0xFF7C2D12),
    cashSoft: Color(0xFFFDEBE3),
    readySoft: Color(0xFFFEF3C7),
    readyText: Color(0xFF78350F),
    successSoft: Color(0xFFE6F4EE),
    successText: Color(0xFF065F46),
    successCard: Color(0xFF065F46),
    errorSoft: Color(0xFFFEE2E2),
    errorText: Color(0xFF991B1B),
    disabled: Color(0xFFE2E6F0),
    disabledText: Color(0xFF334155),
  );

  static const dark = DriverPalette._(
    ground: Color(0xFF0B1020),
    surface: Color(0xFF141A2E),
    surfaceMuted: Color(0xFF1C2338),
    ink: Color(0xFFF1F5F9),
    body: Color(0xFFCBD5E1),
    muted: Color(0xFFA3B0C5),
    line: Color(0xFF2A3450),
    field: Color(0xFF1C2338),
    fieldBorder: Color(0xFF3A4566),
    navy: Color(0xFF3B4F96),
    navyCard: Color(0xFF1E2A54),
    navySoft: Color(0xFF1E2747),
    navyInk: Color(0xFFB9C4EE),
    onNavyMuted: Color(0xFFC7D0F0),
    cash: Color(0xFFF08A5D),
    cashText: Color(0xFFFDBA9A),
    cashSoft: Color(0xFF3A1F14),
    readySoft: Color(0xFF3A2E0B),
    readyText: Color(0xFFFCD34D),
    successSoft: Color(0xFF0F2A22),
    successText: Color(0xFF6EE7B7),
    successCard: Color(0xFF0F3D2E),
    errorSoft: Color(0xFF3B1414),
    errorText: Color(0xFFFCA5A5),
    disabled: Color(0xFF2A3450),
    disabledText: Color(0xFFCBD5E1),
  );

  static DriverPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

extension DriverPaletteContext on BuildContext {
  DriverPalette get dp => DriverPalette.of(this);
}
