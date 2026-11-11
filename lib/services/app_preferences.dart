import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class AppPreferences {
  static const _boxName = 'app_preferences';
  static const _darkModeKey = 'dark_mode_v2';
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.dark,
  );

  static Future<void> initialize() async {
    final box = await Hive.openBox(_boxName);
    // The previous key was initialized with the old light appearance. Start
    // the cockpit redesign in dark mode without reusing that stale value.
    themeMode.value = box.get(_darkModeKey, defaultValue: true) == true
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  static Future<void> setDarkMode(bool enabled) async {
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
    await Hive.box(_boxName).put(_darkModeKey, enabled);
  }
}
