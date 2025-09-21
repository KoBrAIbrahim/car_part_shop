import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _hasNavigated = false;
  bool _isCheckingAuth = false;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationAndNavigate();
  }

  Future<void> _checkAuthenticationAndNavigate() async {
    // Wait a bit to show the welcome screen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted || _hasNavigated) return;

    setState(() {
      _isCheckingAuth = true;
    });

    // Get the AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Wait for authentication initialization to complete if still loading
    int attempts = 0;
    while (authProvider.authState == AuthState.initial ||
        authProvider.authState == AuthState.loading) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;

      // Prevent infinite waiting (max 5 seconds)
      if (attempts > 25 || !mounted) break;
    }

    if (!mounted || _hasNavigated) return;

    _hasNavigated = true;

    // Check if user is authenticated
    if (authProvider.isAuthenticated) {
      // User has saved login credentials and is authenticated
      print('🔓 User is authenticated, navigating to dashboard');
      context.go('/dashboard');
    } else {
      // User needs to login
      print('🔒 User not authenticated, navigating to login');
      context.go('/login');
    }
  }

  bool get _isRtl {
    final locale = context.locale.languageCode;
    return locale == 'ar' || locale == 'he';
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      // Force light theme for auth pages
      data: ThemeData.light().copyWith(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textDark,
        ),
      ),
      child: Directionality(
        textDirection: _isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/logo.png', width: 200, height: 200)
                      .animate()
                      .fadeIn(duration: const Duration(milliseconds: 800))
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1, 1),
                      ),

                  const SizedBox(height: 40),

                  Text(
                        'welcome.title'.tr(),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                      )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 400))
                      .slideY(begin: 0.5, end: 0),

                  const SizedBox(height: 20),

                  Text(
                        'welcome.subtitle'.tr(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textDark.withOpacity(0.7),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: const Duration(milliseconds: 600))
                      .slideY(begin: 0.5, end: 0),

                  const SizedBox(height: 60),

                  // Show loading indicator when checking authentication
                  if (_isCheckingAuth)
                    Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Checking login status...',
                          style: TextStyle(
                            color: AppColors.textDark.withOpacity(0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
