import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مظهر التطبيق (تلقائي حسب الجهاز، نهاري، ليلي)، محفوظ على الجهاز.
class ThemeModeController extends ValueNotifier<ThemeMode> {
  ThemeModeController._() : super(ThemeMode.system);

  static final instance = ThemeModeController._();
  static const _key = 'driver_theme_mode';

  Future<void> load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getString(_key);
      value = ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system);
    } catch (_) {
      value = ThemeMode.system;
    }
  }

  Future<void> set(ThemeMode mode) async {
    value = mode;
    try {
      await (await SharedPreferences.getInstance()).setString(_key, mode.name);
    } catch (_) {}
  }
}
