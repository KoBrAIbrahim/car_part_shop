import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/language_switcher.dart';
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
    final isRtl =
        context.locale.languageCode == 'ar' ||
        context.locale.languageCode == 'he';

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Container(
          padding: EdgeInsets.fromLTRB(
            isSmallScreen ? 12 : 16,
            isSmallScreen ? 8 : 12,
            isSmallScreen ? 12 : 16,
            isSmallScreen ? 8 : 12,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.getPrimary(isDark)
                : AppColors
                      .welcomeBox, // Use new welcome box color for light mode
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? AppColors.getPrimary(isDark).withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: SafeArea(
            child: Directionality(
              textDirection: isRtl
                  ? ui.TextDirection.rtl
                  : ui.TextDirection.ltr,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Row(
                    children: [
                      // Back button or logo
                      if (showBackButton)
                        IconButton(
                          onPressed:
                              onBackPressed ??
                              () => Navigator.of(context).pop(),
                          icon: Icon(
                            isRtl
                                ? Icons.arrow_forward_ios_rounded
                                : Icons.arrow_back_ios_rounded,
                            color: isDark
                                ? Colors.white
                                : Colors
                                      .black, // Black for light mode, white for dark mode
                            size: isSmallScreen ? 20 : 24,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.getCardBackground(
                              isDark,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                          decoration: BoxDecoration(
                            color: AppColors.getCardBackground(isDark),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/logo.png',
                            height: isSmallScreen ? 32 : 40,
                            width: isSmallScreen ? 32 : 40,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.car_repair_rounded,
                                size: isSmallScreen ? 32 : 40,
                                color: isDark
                                    ? Colors.white
                                    : Colors
                                          .black, // Black for light mode, white for dark mode
                              );
                            },
                          ),
                        ),

                      SizedBox(width: isSmallScreen ? 8 : 16),

                      // Title - with proper localization
                      if (title != null)
                        Expanded(
                          child: Text(
                            title!.tr(), // Ensure title is translated
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: isDark
                                      ? Colors.white
                                      : Colors
                                            .black, // Black for light mode, white for dark mode
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 18 : 24,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: isRtl ? TextAlign.right : TextAlign.left,
                            textDirection: isRtl
                                ? ui.TextDirection.rtl
                                : ui.TextDirection.ltr,
                          ),
                        )
                      else
                        const Spacer(),

                      // Actions
                      if (actions != null) ...actions!,

                      // Language switcher - enhanced with animation
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: AppColors.getCardBackground(isDark),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                          child: const LanguageSwitcher(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
