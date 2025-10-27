import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_colors.dart';
import 'dart:ui' as ui;

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({
    super.key,
    this.locales = const [Locale('en'), Locale('ar'), Locale('he')],
    this.iconSize = 20,
  });

  final List<Locale> locales;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final current = context.locale;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Dynamic colors based on theme
    final bgColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = AppColors.getTextColor(isDark);
    final borderColor = isDark 
        ? AppColors.yellow.withOpacity(0.3) 
        : AppColors.yellow.withOpacity(0.15);
    final shadowColor = AppColors.yellow.withOpacity(0.12);

    return PopupMenuButton<Locale>(
      tooltip: 'Change language',
      initialValue: current,
      offset: const Offset(0, 12),
      elevation: 12,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.getDivider(true) : Colors.transparent,
        ),
      ),
      onSelected: (locale) async {
        if (locale.languageCode != current.languageCode) {
          await context.setLocale(locale);
        }
      },
      itemBuilder: (_) => [
        for (final loc in locales) _buildItem(context, loc, current, isDark),
      ],
      // Button face (shows current language)
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.public_rounded,
              color: textColor.withOpacity(0.87),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _codeLabel(current.languageCode),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: textColor.withOpacity(0.54),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<Locale> _buildItem(
    BuildContext context,
    Locale loc,
    Locale current,
    bool isDark,
  ) {
    final selected = current.languageCode == loc.languageCode;
    final isRtl = _isRtl(loc.languageCode);
    final textColor = AppColors.getTextColor(isDark);
    final secondaryTextColor = AppColors.getTextSecondaryColor(isDark);

    final row = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: isRtl
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                _nativeName(loc.languageCode),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Text(
                _englishName(loc.languageCode),
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
        if (selected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, size: 16, color: Colors.black),
                SizedBox(width: 4),
                Text(
                  'Current',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    return PopupMenuItem<Locale>(
      value: loc,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Directionality(
        textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: row,
      ),
    );
  }

  static bool _isRtl(String code) => code == 'ar' || code == 'he';

  static String _codeLabel(String code) {
    switch (code) {
      case 'en':
        return 'EN';
      case 'ar':
        return 'AR';
      case 'he':
        return 'HE';
      default:
        return code.toUpperCase();
    }
  }

  static String _nativeName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      case 'he':
        return 'עברית';
      default:
        return code;
    }
  }

  static String _englishName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ar':
        return 'Arabic';
      case 'he':
        return 'Hebrew';
      default:
        return code;
    }
  }
}