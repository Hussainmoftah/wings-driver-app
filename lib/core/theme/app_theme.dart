import 'package:flutter/material.dart';
import 'package:sadeem_ui/sadeem_ui.dart';

/// ثيم التطبيق = الثيم الموحد لسديم (sadeem_ui) حتى تتطابق التطبيقات الأربعة.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => SadeemTheme.light();

  /// الوضع الليلي: يتبع إعداد الجوال (مريح للعين أثناء السواقة بالليل)
  static ThemeData get darkTheme => SadeemTheme.dark();
}
