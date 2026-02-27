import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _isMonochromeKey = 'is_monochrome';

  ThemeMode _themeMode = ThemeMode.system;
  bool _isMonochrome = false;
  late SharedPreferences _prefs;

  ThemeMode get themeMode => _themeMode;
  bool get isMonochrome => _isMonochrome;

  // Initialize the service and load saved preferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadThemeSettings();
  }

  // Load theme settings from SharedPreferences
  Future<void> _loadThemeSettings() async {
    final themeModeIndex = _prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeModeIndex];
    _isMonochrome = _prefs.getBool(_isMonochromeKey) ?? false;
    notifyListeners();
  }

  // Toggle between normal and monochrome themes
  Future<void> toggleMonochrome() async {
    _isMonochrome = !_isMonochrome;
    await _prefs.setBool(_isMonochromeKey, _isMonochrome);
    notifyListeners();
  }

  // Set monochrome state directly
  Future<void> setMonochrome(bool isMonochrome) async {
    if (_isMonochrome != isMonochrome) {
      _isMonochrome = isMonochrome;
      await _prefs.setBool(_isMonochromeKey, _isMonochrome);
      notifyListeners();
    }
  }

  // Set theme mode (light, dark, system)
  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (_themeMode != themeMode) {
      _themeMode = themeMode;
      await _prefs.setInt(_themeKey, themeMode.index);
      notifyListeners();
    }
  }

  // Get current effective brightness based on theme mode and system setting
  Brightness getEffectiveBrightness(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness;
    }
  }

  // Check if current theme should be dark
  bool isDarkMode(BuildContext context) {
    return getEffectiveBrightness(context) == Brightness.dark;
  }

  // Get current theme description for UI display
  String get themeDescription {
    if (_isMonochrome) {
      return 'Monochrome';
    }
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  // Reset all theme settings to default
  Future<void> resetToDefaults() async {
    _themeMode = ThemeMode.system;
    _isMonochrome = false;
    await _prefs.setInt(_themeKey, _themeMode.index);
    await _prefs.setBool(_isMonochromeKey, _isMonochrome);
    notifyListeners();
  }
}
