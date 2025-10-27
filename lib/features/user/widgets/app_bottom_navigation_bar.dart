import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/localization/translation_keys.dart';
import 'dart:ui' as ui;

class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isRtl = context.locale.languageCode == 'ar' ||
        context.locale.languageCode == 'he';

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final navBarBg = isDark ? AppColors.darkCardBackground : Colors.white;

        // Outer container fills the bottom area; set its color so the area
        // behind the rounded nav box is black in dark mode.
        return Container(
          color: isDark ? Colors.black : Colors.transparent,
          child: Container(
            margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 16,
              vertical: isSmallScreen ? 8 : 12,
            ),
            decoration: BoxDecoration(
              // Keep the inner rounded box color (navBarBg) — this makes the
              // rounded card contrast against the black background in dark mode.
              color: navBarBg,
              borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: AppColors.yellow.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 0),
                spreadRadius: 2,
              ),
            ],
          ),
          child: SafeArea(
            child: Directionality(
              textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    context: context,
                    index: 0,
                    icon: Icons.home_rounded,
                      label: TranslationKeys.bottomNavHome.tr(),
                    isSelected: currentIndex == 0,
                    isSmallScreen: isSmallScreen,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 1,
                    icon: Icons.build_rounded,
                      label: TranslationKeys.bottomNavTools.tr(),
                    isSelected: currentIndex == 1,
                    isSmallScreen: isSmallScreen,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 2,
                    icon: Icons.local_offer_rounded,
                      label: TranslationKeys.bottomNavSales.tr(),
                    isSelected: currentIndex == 2,
                    isSmallScreen: isSmallScreen,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 3,
                    icon: Icons.shopping_cart_rounded,
                      label: TranslationKeys.bottomNavCart.tr(),
                    isSelected: currentIndex == 3,
                    isSmallScreen: isSmallScreen,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    context: context,
                    index: 4,
                    icon: Icons.settings_rounded,
                      label: TranslationKeys.bottomNavSettings.tr(),
                    isSelected: currentIndex == 4,
                    isSmallScreen: isSmallScreen,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ));
      },
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isSmallScreen,
    required bool isDark,
  }) {
    final textColor = AppColors.getTextColor(isDark);
    final secondaryTextColor = AppColors.getTextSecondaryColor(isDark);

    return Expanded(
      flex: isSelected ? 2 : 1, // Selected item takes 2x width
      child: GestureDetector(
        onTap: () => _handleNavigation(context, index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2 : 4),
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 6 : 10,
            vertical: isSmallScreen ? 8 : 10,
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.yellow // Yellow background for selected
                : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.yellow.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(
                icon,
                color: isSelected
                    ? Colors.black // Black icon on yellow background
                    : secondaryTextColor, // Secondary color when not selected
                size: isSmallScreen ? 22 : 26,
              ),
              
              // Label - only show for selected item on mobile, always show on larger screens
              if (isSelected || !isSmallScreen) ...[
                SizedBox(width: isSmallScreen ? 6 : 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? Colors.black // Black text on yellow background
                          : secondaryTextColor, // Secondary color when not selected
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Handle navigation based on index
  void _handleNavigation(BuildContext context, int index) {
    // If custom onTap callback is provided, use it
    if (onTap != null) {
      onTap!(index);
      return;
    }

    // Default navigation using GoRouter
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/tools');
        break;
      case 2:
        context.go('/sales');
        break;
      case 3:
        context.go('/cart');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }
}