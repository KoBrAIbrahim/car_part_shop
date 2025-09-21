import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  late SharedPreferences _prefs;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      await _prefs.setBool('isDarkMode', _isDarkMode);
      notifyListeners();
    }
  }

  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.lightPrimary,
    scaffoldBackgroundColor: AppColors.lightBackground,
    cardColor: AppColors.lightCardBackground,
    dividerColor: AppColors.divider,
    colorScheme: ColorScheme.light(
      primary: AppColors.lightPrimary,
      secondary: AppColors.accent,
      surface: AppColors.lightSurface,
      background: AppColors.lightBackground,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.lightTextDark),
      bodyMedium: TextStyle(color: AppColors.lightTextDark),
      titleLarge: TextStyle(color: AppColors.lightTextDark),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white, // White background for light mode
      foregroundColor: Colors.black, // Black text for light mode
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white, // White background for light mode
      selectedItemColor: Colors.black, // Black for selected items
      unselectedItemColor: Colors.black54, // Dark gray for unselected items
    ),
  );

  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.darkPrimary,
    scaffoldBackgroundColor: AppColors.darkBackground,
    cardColor: AppColors.darkCardBackground,
    dividerColor: AppColors.darkDivider,
    colorScheme: ColorScheme.dark(
      primary: AppColors.darkPrimary,
      secondary: AppColors.accent,
      surface: AppColors.darkSurface,
      background: AppColors.darkBackground,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.darkTextLight),
      bodyMedium: TextStyle(color: AppColors.darkTextLight),
      titleLarge: TextStyle(color: AppColors.darkTextLight),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkPrimary,
      foregroundColor: AppColors.darkTextLight,
      elevation: 0,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkPrimary,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white.withOpacity(0.6),
    ),
  );
}
