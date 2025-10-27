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

  // ==================== LIGHT THEME ====================
  ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.yellow,
        scaffoldBackgroundColor: AppColors.lightBackground,
        cardColor: AppColors.lightCardBackground,
        dividerColor: AppColors.getDivider(false),
        
        colorScheme: ColorScheme.light(
          primary: AppColors.yellow,
          secondary: AppColors.yellowDark,
          surface: AppColors.lightSurface,
          background: AppColors.lightBackground,
          error: AppColors.error,
          onPrimary: Colors.black, // Text on yellow
          onSecondary: Colors.black,
          onSurface: AppColors.lightText,
          onBackground: AppColors.lightText,
          onError: Colors.white,
        ),
        
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.lightText),
          bodyMedium: TextStyle(color: AppColors.lightText),
          bodySmall: TextStyle(color: AppColors.lightTextSecondary),
          titleLarge: TextStyle(color: AppColors.lightText, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: AppColors.lightText, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: AppColors.lightText),
        ),
        
        // AppBar - Yellow Header
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.yellow,
          foregroundColor: Colors.black,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        // Bottom Navigation Bar - Yellow Footer
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.yellow,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black54,
          elevation: 8,
        ),
        
        // Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.yellow,
            foregroundColor: Colors.black,
            elevation: 2,
          ),
        ),
        
        // Text Buttons
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.yellow,
          ),
        ),
        
        // Input Fields
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.getDivider(false)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.getDivider(false)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.yellow, width: 2),
          ),
          errorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.error),
          ),
          labelStyle: const TextStyle(color: AppColors.lightTextSecondary),
          hintStyle: const TextStyle(color: AppColors.lightTextSecondary),
        ),
      );

  // ==================== DARK THEME ====================
  ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.yellow,
        scaffoldBackgroundColor: AppColors.darkBackground,
        cardColor: AppColors.darkCardBackground,
        dividerColor: AppColors.getDivider(true),
        
        colorScheme: ColorScheme.dark(
          primary: AppColors.yellow,
          secondary: AppColors.yellowDark,
          surface: AppColors.darkSurface,
          background: AppColors.darkBackground,
          error: AppColors.error,
          onPrimary: Colors.black, // Text on yellow
          onSecondary: Colors.black,
          onSurface: AppColors.darkText,
          onBackground: AppColors.darkText,
          onError: Colors.white,
        ),
        
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.darkText),
          bodyMedium: TextStyle(color: AppColors.darkText),
          bodySmall: TextStyle(color: AppColors.darkTextSecondary),
          titleLarge: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(color: AppColors.darkText),
        ),
        
        // AppBar - Yellow Header
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.yellow,
          foregroundColor: Colors.black,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        // Bottom Navigation Bar - Yellow Footer
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.yellow,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black54,
          elevation: 8,
        ),
        
        // Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.yellow,
            foregroundColor: Colors.black,
            elevation: 2,
          ),
        ),
        
        // Text Buttons
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.yellow,
          ),
        ),
        
        // Input Fields
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.getDivider(true)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.getDivider(true)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.yellow, width: 2),
          ),
          errorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.error),
          ),
          labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
          hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
        ),
      );
}