import 'package:flutter/material.dart';

class AppColors {
  // ==================== LIGHT MODE ====================
  static const Color lightBackground = Colors.white; // خلفية بيضاء نقية
  static const Color lightSurface = Color(0xFFF8F8F8); // رمادي فاتح جداً للأسطح
  static const Color lightCardBackground = Colors.white;
  static const Color lightText = Colors.black; // نص أسود
  static const Color lightTextSecondary = Color(0xFF666666); // نص ثانوي رمادي
  
  // ==================== DARK MODE ====================
  static const Color darkBackground = Colors.black; // خلفية سوداء نقية
  static const Color darkSurface = Color(0xFF1A1A1A); // سطح داكن قليلاً
  static const Color darkCardBackground = Color(0xFF2A2A2A); // خلفية البطاقات
  static const Color darkText = Colors.white; // نص أبيض
  static const Color darkTextSecondary = Color(0xFFBBBBBB); // نص ثانوي رمادي فاتح

  // ==================== COMMON COLORS ====================
  // Yellow - للهيدر والفوتر
  static const Color yellow = Color(0xFFFDD435); // أصفر ذهبي
  static const Color yellowDark = Color(0xFFE5C030); // أصفر أغمق قليلاً للتفاعل
  static const Color yellowLight = Color(0xFFFEE680); // أصفر فاتح
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50); // أخضر نجاح
  static const Color successDark = Color(0xFF388E3C); // أخضر غامق
  static const Color successLight = Color(0xFF81C784); // أخضر فاتح
  
  static const Color error = Color(0xFFF44336); // أحمر خطأ
  static const Color errorDark = Color(0xFFD32F2F); // أحمر غامق
  static const Color errorLight = Color(0xFFE57373); // أحمر فاتح
  
  static const Color warning = Color(0xFFFF9800); // برتقالي تحذير
  static const Color info = Color(0xFF2196F3); // أزرق معلومات

  // ==================== HELPER METHODS ====================
  
  // Background
  static Color getBackground(bool isDark) =>
      isDark ? darkBackground : lightBackground;
  
  // Surface
  static Color getSurface(bool isDark) =>
      isDark ? darkSurface : lightSurface;
  
  // Card Background
  static Color getCardBackground(bool isDark) =>
      isDark ? darkCardBackground : lightCardBackground;
  
  // Text Colors
  static Color getTextColor(bool isDark) =>
      isDark ? darkText : lightText;
  
  static Color getTextSecondaryColor(bool isDark) =>
      isDark ? darkTextSecondary : lightTextSecondary;
  
  // Divider
  static Color getDivider(bool isDark) =>
      isDark ? Color(0xFF333333) : Color(0xFFE0E0E0);
  
  // Disabled States
  static Color getDisabledColor(bool isDark) =>
      isDark ? Color(0xFF555555) : Color(0xFFBDBDBD);

  // ==================== GRADIENTS ====================
  static const List<Color> yellowGradient = [
    yellow,
    yellowDark,
  ];
  
  static const List<Color> successGradient = [
    successLight,
    success,
  ];
  
  static const List<Color> errorGradient = [
    errorLight,
    error,
  ];

  // ==================== LEGACY SUPPORT ====================
  static Color get background => lightBackground;
  static Color get surface => lightSurface;
  static Color get cardBackground => lightCardBackground;
  static Color get textDark => lightText;
  static Color get primary => yellow;
}