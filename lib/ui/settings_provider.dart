import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _enableSmoke = true;

  ThemeMode get themeMode => _themeMode;
  bool get enableSmoke => _enableSmoke;

  SettingsProvider() {
    _loadSettings();
  }

  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkTheme', isDark);
  }

  void toggleSmoke(bool isEnable) async {
    _enableSmoke = isEnable ? true : false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isSmokeEnabled', isEnable);
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkTheme') ?? false;
    final isEnabled = prefs.getBool('isSmokeEnabled') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _enableSmoke = isEnabled ? true : false;
    notifyListeners();
  }
}
