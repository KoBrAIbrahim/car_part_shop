import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors
  static const Color lightBackground = Color(0xFFFDFDFD); // شبه أبيض
  static const Color lightSurface = Color(
    0xFFF5F5F5,
  ); // رمادي فاتح للخلفيات الثانوية
  static const Color lightCardBackground = Colors.white;
  static const Color lightTextDark = Color(0xFF212121); // رمادي غامق للنصوص
  static const Color lightPrimary = Color.fromARGB(
    255,
    253,
    213,
    52,
  ); // أصفر ذهبي للوضع الفاتح

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF121212); // خلفية داكنة
  static const Color darkSurface = Color(0xFF1E1E1E); // سطح داكن
  static const Color darkCardBackground = Color(
    0xFF2D2D2D,
  ); // خلفية البطاقات الداكنة
  static const Color darkTextLight = Color(0xFFE0E0E0); // نص فاتح للوضع الداكن
  static const Color darkPrimary = Color(0xFF000000); // أسود للوضع الداكن

  // Common colors (same for both modes)
  static const Color secondary = Color(0xFF000000); // أسود رئيسي
  static const Color accent = Color(0xFF1E88E5); // أزرق لإضافة توازن
  static const Color textLight = Colors.white; // نصوص فوق الأسود أو الأزرق
  static const Color welcomeBox = Color.fromARGB(
    255,
    253,
    213,
    52,
  ); // أصفر ذهبي للوضع الفاتح

  // ألوان حالة
  static const Color error = Color(0xFFE53935); // أحمر
  static const Color success = Color(0xFF43A047); // أخضر نجاح
  static const Color warning = Color(0xFFFFA000); // برتقالي تحذير

  // العناصر
  static const Color divider = Color(0xFFE0E0E0);
  static const Color darkDivider = Color(0xFF424242);

  // حالات Disabled
  static const Color disabledButton = Color(0xFFBDBDBD);
  static const Color disabledText = Color(0xFF9E9E9E);

  // Gradient أساسي (أصفر → أسود للوضع الفاتح)
  static const List<Color> lightPrimaryGradient = [lightPrimary, secondary];
  static const List<Color> darkPrimaryGradient = [darkPrimary, secondary];

  // Helper methods to get theme-specific colors
  static Color getBackground(bool isDark) =>
      isDark ? darkBackground : lightBackground;
  static Color getSurface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color getCardBackground(bool isDark) =>
      isDark ? darkCardBackground : lightCardBackground;
  static Color getTextColor(bool isDark) =>
      isDark ? darkTextLight : lightTextDark;
  static Color getPrimary(bool isDark) => isDark ? darkPrimary : lightPrimary;
  static Color getDivider(bool isDark) => isDark ? darkDivider : divider;

  // Legacy support - use light theme as default
  static Color get background => lightBackground;
  static Color get surface => lightSurface;
  static Color get cardBackground => lightCardBackground;
  static Color get textDark => lightTextDark;
  static Color get primary => lightPrimary;
  static Color get currentDivider => divider;
}
