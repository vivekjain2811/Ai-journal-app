import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Create a temporary binding access or rely on the caller to know system state.
      // However, usually system brightness is accessed via context.
      // For simplicity in toggle logic, we can default to 'false' or just check against dark.
      // Better to check actual value or just rely on manual toggle.
      // Let's rely on manual toggle explicitly setting light/dark for now to avoid complexity with system
      return _themeMode == ThemeMode.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
