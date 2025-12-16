// lib/theme_notifier.dart (Updated for Theme Persistence)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 1. Import SharedPreferences

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode;

  // 2. Key used to store theme preference
  static const String _themeKey = 'userThemeMode';

  ThemeNotifier(this._themeMode);

  ThemeMode get themeMode => _themeMode;

  // --- NEW: Static method to load theme from storage ---
  static Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    // Get the saved theme index (ThemeMode.light is 1, ThemeMode.dark is 2)
    // Default to 1 (Light) if no preference is found
    final themeIndex = prefs.getInt(_themeKey) ?? 1;

    // Convert the saved index back to ThemeMode enum
    // We use .clamp to ensure the index is safe (0, 1, or 2)
    return ThemeMode.values.elementAt(themeIndex.clamp(1, 2));
  }

  // --- UPDATED: Method to set theme and save to storage ---
  void setThemeMode(ThemeMode mode) async {
    if (mode != _themeMode) {
      _themeMode = mode;
      notifyListeners();

      // Save the new theme mode index to storage
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt(_themeKey, mode.index);
      debugPrint('Theme mode saved: ${mode.toString()}');
    }
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;
}