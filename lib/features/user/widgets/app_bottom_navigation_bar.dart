import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/theme_provider.dart';
import 'dart:ui' as ui;

class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap; // Made optional

  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    this.onTap, // No longer required
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isRtl =
        context.locale.languageCode == 'ar' ||
        context.locale.languageCode == 'he';

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.getPrimary(isDark) : AppColors.welcomeBox,
          ),
          padding: EdgeInsets.only(
            left: isSmallScreen ? 8 : 16,
            right: isSmallScreen ? 8 : 16,
            top: isSmallScreen ? 6 : 8,
            bottom:
                MediaQuery.of(context).padding.bottom + (isSmallScreen ? 4 : 6),
          ),
          child: Directionality(
            textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth =
                    (constraints.maxWidth - (isSmallScreen ? 32 : 64)) / 5;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      context: context,
                      index: 0,
                      icon: Icons.home_rounded,
                      label: 'user.nav.home'.tr(),
                      isSelected: currentIndex == 0,
                      isSmallScreen: isSmallScreen,
                      itemWidth: itemWidth,
                      isDark: isDark,
                    ),
                    _buildNavItem(
                      context: context,
                      index: 1,
                      icon: Icons.build_rounded,
                      label: 'user.nav.tools'.tr(),
                      isSelected: currentIndex == 1,
                      isSmallScreen: isSmallScreen,
                      itemWidth: itemWidth,
                      isDark: isDark,
                    ),
                    _buildNavItem(
                      context: context,
                      index: 2,
                      icon: Icons.local_offer_rounded,
                      label: 'user.nav.sales'.tr(),
                      isSelected: currentIndex == 2,
                      isSmallScreen: isSmallScreen,
                      itemWidth: itemWidth,
                      isDark: isDark,
                    ),
                    _buildNavItem(
                      context: context,
                      index: 3,
                      icon: Icons.shopping_cart_rounded,
                      label: 'user.nav.cart'.tr(),
                      isSelected: currentIndex == 3,
                      isSmallScreen: isSmallScreen,
                      itemWidth: itemWidth,
                      isDark: isDark,
                    ),
                    _buildNavItem(
                      context: context,
                      index: 4,
                      icon: Icons.settings_rounded,
                      label: 'user.nav.settings'.tr(),
                      isSelected: currentIndex == 4,
                      isSmallScreen: isSmallScreen,
                      itemWidth: itemWidth,
                      isDark: isDark,
                    ),
                  ],
                );
              },
            ),
          ),
        );
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
    required double itemWidth,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => _handleNavigation(context, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: itemWidth,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 6 : 12,
          vertical: isSmallScreen ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: isDark ? Colors.white : Colors.black,
                  width: 2,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark
                        ? Colors.white.withOpacity(0.6)
                        : Colors.black.withOpacity(0.6)),
              size: isSmallScreen ? 20 : 24,
            ),
            SizedBox(height: isSmallScreen ? 2 : 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 9 : 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark
                          ? Colors.white.withOpacity(0.6)
                          : Colors.black.withOpacity(0.6)),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
