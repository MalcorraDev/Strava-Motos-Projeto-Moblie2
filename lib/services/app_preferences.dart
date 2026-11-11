import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class AppPreferences {
  static const _boxName = 'app_preferences';
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.dark,
  );

  static Future<void> initialize() async {
    final box = await Hive.openBox(_boxName);
    themeMode.value = box.get('dark_mode', defaultValue: true) == true
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  static Future<void> setDarkMode(bool enabled) async {
    themeMode.value = enabled ? ThemeMode.dark : ThemeMode.light;
    await Hive.box(_boxName).put('dark_mode', enabled);
  }
}
