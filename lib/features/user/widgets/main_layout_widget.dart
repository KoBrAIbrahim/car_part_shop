import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'app_header_widget.dart';
import 'app_bottom_navigation_bar.dart';
import 'dart:ui' as ui;

class MainLayoutWidget extends StatelessWidget {
  final Widget child;
  final String? title;
  final int currentIndex;
  final Function(int) onNavigationTap;
  final List<Widget>? headerActions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const MainLayoutWidget({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onNavigationTap,
    this.title,
    this.headerActions,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Listen to locale changes to rebuild the widget immediately
    final currentLocale = context.locale;
    final isRtl =
        currentLocale.languageCode == 'ar' ||
        currentLocale.languageCode == 'he';

    return Directionality(
      textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white, // Changed to white background
        appBar: AppHeaderWidget(
          title: title,
          actions: headerActions,
          showBackButton: showBackButton,
          onBackPressed: onBackPressed,
        ),
        body: Container(
          color: Colors.white, // Use solid white instead of gradient
          child: child,
        ),
        bottomNavigationBar: AppBottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onNavigationTap,
        ),
      ),
    );
  }
}
