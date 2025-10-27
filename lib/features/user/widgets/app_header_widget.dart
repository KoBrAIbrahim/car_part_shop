import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/theme_provider.dart';
import 'dart:ui' as ui;

class AppHeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const AppHeaderWidget({
    super.key,
    this.title,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Listen to locale changes to rebuild the widget
    context.locale;

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;
    
    final isRtl = context.locale.languageCode == 'ar' ||
        context.locale.languageCode == 'he';

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        // Header background changes based on theme
        final headerBg = isDark ? AppColors.darkCardBackground : Colors.white;

        return Container(
          decoration: BoxDecoration(
            color: headerBg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Directionality(
              textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 28 : (isTablet ? 20 : 12),
                  // Reduce vertical padding to make header smaller
                  vertical: isSmallScreen ? 6 : 8,
                ),
                // Use a Stack so we can center the title while keeping leading
                // (logo/back) and actions aligned to the sides.
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button or Logo (left)
                        if (showBackButton)
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.yellow,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.yellowDark,
                                width: 2,
                              ),
                            ),
                            child: IconButton(
                              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                              icon: Icon(
                                isRtl
                                    ? Icons.arrow_forward_ios_rounded
                                    : Icons.arrow_back_ios_rounded,
                                color: Colors.black,
                                size: isSmallScreen ? 20 : 24,
                              ),
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                              constraints: const BoxConstraints(),
                            ),
                          )
                        else
                          // Logo without box - standalone (increased size)
                          Image.asset(
                            'assets/logo1.png',
                            // Increased logo sizes: desktop/tablet/phone
                            width: isDesktop ? 80 : (isTablet ? 64 : 60),
                            height: isDesktop ? 80 : (isTablet ? 64 : 60),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.directions_car_rounded,
                                size: isDesktop ? 80 : (isTablet ? 64 : 60),
                                color: AppColors.yellow,
                              );
                            },
                          ),

                        // Actions (right)
                        if (actions != null)
                          Row(
                            children: [
                              ...actions!.map((action) => Padding(
                                    padding: EdgeInsets.only(
                                      left: isRtl ? 0 : 8,
                                      right: isRtl ? 8 : 0,
                                    ),
                                    child: action,
                                  )),
                            ],
                          )
                        else
                          // reserve space so title stays centered when no actions
                          SizedBox(width: isDesktop ? 64 : (isTablet ? 56 : 52)),
                      ],
                    ),

                    // Centered title with constrained width to avoid overlapping side widgets
                    if (title != null)
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: screenWidth * 0.6),
                          child: Text(
                            title!.tr(),
                            style: TextStyle(
                              color: AppColors.getTextColor(isDark),
                              fontWeight: FontWeight.bold,
                              fontSize: isDesktop ? 24 : (isTablet ? 22 : 20),
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);
}