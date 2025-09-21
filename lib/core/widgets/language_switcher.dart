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

    return PopupMenuButton<Locale>(
      tooltip: 'Change language',
      initialValue: current,
      offset: const Offset(0, 12),
      elevation: 12,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (locale) async {
        if (locale.languageCode != current.languageCode) {
          await context.setLocale(locale);
        }
      },
      itemBuilder: (_) => [
        for (final loc in locales) _buildItem(context, loc, current),
      ],
      // وجه الزر (يظهر اللغة الحالية)
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.public_rounded, color: Colors.black87, size: 20),
            const SizedBox(width: 8),
            Text(
              _codeLabel(current.languageCode),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Colors.black54,
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
  ) {
    final selected = current.languageCode == loc.languageCode;
    final isRtl = _isRtl(loc.languageCode);

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
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                _englishName(loc.languageCode),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        if (selected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent, // Blue background
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                const Text(
                  'Current',
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ),
      ],
    );

    // نجعل اتجاه عنصر القائمة مناسبًا للغة نفسها
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
