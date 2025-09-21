import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/language_switcher.dart';
import '../auth_provider.dart';

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({super.key});

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage>
    with TickerProviderStateMixin {
  final _resetUrlController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _backgroundController;
  late AnimationController _pulseController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _pulseAnimation;
  bool _isResetPressed = false;

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_backgroundController);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _backgroundController.repeat();
    _pulseController.repeat(reverse: true);

    // Try to get reset URL from clipboard
    _checkClipboard();
  }

  @override
  void dispose() {
    _resetUrlController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _backgroundController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isRtl {
    final locale = context.locale.languageCode;
    return locale == 'ar' || locale == 'he';
  }

  Future<void> _checkClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null &&
          clipboardData!.text!.contains('myshopify.com') &&
          clipboardData.text!.contains('reset')) {
        setState(() {
          _resetUrlController.text = clipboardData.text!;
        });
      }
    } catch (e) {
      // Ignore clipboard errors
    }
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
          body: Stack(
            children: [
              // Animated Background
              AnimatedBuilder(
                animation: _backgroundAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.background,
                          AppColors.primary.withOpacity(0.05),
                        ],
                        stops: [
                          0.0,
                          0.5 + 0.3 * _backgroundAnimation.value,
                          1.0,
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Floating Elements Background
              ...List.generate(20, (index) {
                return Positioned(
                  left: (index * 60.0) % MediaQuery.of(context).size.width,
                  top: (index * 100.0) % MediaQuery.of(context).size.height,
                  child: AnimatedBuilder(
                    animation: _backgroundAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          30 *
                              _backgroundAnimation.value *
                              (index % 2 == 0 ? 1 : -1),
                          40 * _backgroundAnimation.value,
                        ),
                        child: Transform.scale(
                          scale: 0.5 + 0.5 * _backgroundAnimation.value,
                          child: Opacity(
                            opacity: 0.05 + 0.1 * _backgroundAnimation.value,
                            child: Container(
                              width: 6 + (index % 4) * 3,
                              height: 6 + (index % 4) * 3,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(
                                  index % 3 == 0 ? 1 : 0.7,
                                ),
                                shape: index % 2 == 0
                                    ? BoxShape.circle
                                    : BoxShape.rectangle,
                                borderRadius: index % 2 == 1
                                    ? BorderRadius.circular(2)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),

              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenHeight = constraints.maxHeight;

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                      child: Column(
                        children: [
                          // Language Switcher and Back Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () => context.go('/login'),
                                icon: Icon(
                                  _isRtl
                                      ? Icons.arrow_forward_ios
                                      : Icons.arrow_back_ios,
                                  color: AppColors.primary,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.cardBackground,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: LanguageSwitcher(),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.5),

                          // Main content
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(height: screenHeight * 0.02),

                                    // Logo with pulse animation
                                    AnimatedBuilder(
                                      animation: _pulseAnimation,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: _pulseAnimation.value,
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              gradient: RadialGradient(
                                                colors: [
                                                  AppColors.primary.withOpacity(
                                                    0.2,
                                                  ),
                                                  AppColors.primary.withOpacity(
                                                    0.05,
                                                  ),
                                                  AppColors.background,
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: AppColors.cardBackground,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.primary
                                                        .withOpacity(0.3),
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.lock_reset_rounded,
                                                size: 40,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ).animate().fadeIn().scale(),

                                    SizedBox(height: screenHeight * 0.02),

                                    // Title
                                    Text(
                                          tr('auth.reset.title'),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                color: AppColors.textDark,
                                                fontWeight: FontWeight.bold,
                                              ),
                                          textAlign: TextAlign.center,
                                        )
                                        .animate()
                                        .fadeIn(delay: 400.ms)
                                        .slideY(begin: 0.2),

                                    SizedBox(height: screenHeight * 0.01),

                                    // Subtitle
                                    Text(
                                      tr('auth.reset.subtitle'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textDark
                                                .withOpacity(0.7),
                                          ),
                                      textAlign: TextAlign.center,
                                    ).animate().fadeIn(delay: 500.ms),

                                    SizedBox(height: screenHeight * 0.04),

                                    // Reset Form
                                    Container(
                                      constraints: const BoxConstraints(
                                        maxWidth: 400,
                                      ),
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: AppColors.primary.withOpacity(
                                            0.1,
                                          ),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary
                                                .withOpacity(0.1),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Error message
                                            Consumer<AuthProvider>(
                                              builder: (context, auth, _) {
                                                if (auth.errorMessage != null) {
                                                  String localizedError = '';
                                                  switch (auth.errorMessage) {
                                                    case 'reset_failed':
                                                      localizedError = tr(
                                                        'auth.login.reset_failed',
                                                      );
                                                      break;
                                                    case 'reset_link_expired':
                                                      localizedError = tr(
                                                        'auth.login.reset_link_expired',
                                                      );
                                                      break;
                                                    case 'network_error':
                                                      localizedError = tr(
                                                        'auth.login.network_error',
                                                      );
                                                      break;
                                                    default:
                                                      localizedError =
                                                          auth.errorMessage!;
                                                  }

                                                  return Container(
                                                    width: double.infinity,
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    margin:
                                                        const EdgeInsets.only(
                                                          bottom: 16,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.shade50,
                                                      border: Border.all(
                                                        color:
                                                            Colors.red.shade300,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.error_outline,
                                                          color: Colors
                                                              .red
                                                              .shade700,
                                                          size: 20,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            localizedError,
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .red
                                                                  .shade700,
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }
                                                return const SizedBox.shrink();
                                              },
                                            ),

                                            // Reset URL Field
                                            _AdvancedTextField(
                                                  label: tr(
                                                    'auth.reset.reset_url',
                                                  ),
                                                  controller:
                                                      _resetUrlController,
                                                  icon: Icons.link_rounded,
                                                  maxLines: 3,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return tr(
                                                        'auth.validation.required_field',
                                                      );
                                                    }
                                                    if (!value.contains(
                                                          'myshopify.com',
                                                        ) ||
                                                        !value.contains(
                                                          'reset',
                                                        )) {
                                                      return tr(
                                                        'auth.reset.invalid_reset_url',
                                                      );
                                                    }
                                                    return null;
                                                  },
                                                )
                                                .animate()
                                                .fadeIn(delay: 600.ms)
                                                .slideX(begin: -0.3),

                                            const SizedBox(height: 16),

                                            // New Password Field
                                            _AdvancedTextField(
                                                  label: tr(
                                                    'auth.reset.new_password',
                                                  ),
                                                  controller:
                                                      _newPasswordController,
                                                  obscureText: true,
                                                  icon: Icons
                                                      .lock_outline_rounded,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return tr(
                                                        'auth.validation.required_field',
                                                      );
                                                    }
                                                    if (value.length < 6) {
                                                      return tr(
                                                        'auth.validation.password_too_short',
                                                      );
                                                    }
                                                    return null;
                                                  },
                                                )
                                                .animate()
                                                .fadeIn(delay: 700.ms)
                                                .slideX(begin: 0.3),

                                            const SizedBox(height: 16),

                                            // Confirm Password Field
                                            _AdvancedTextField(
                                                  label: tr(
                                                    'auth.reset.confirm_password',
                                                  ),
                                                  controller:
                                                      _confirmPasswordController,
                                                  obscureText: true,
                                                  icon: Icons
                                                      .lock_outline_rounded,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return tr(
                                                        'auth.validation.required_field',
                                                      );
                                                    }
                                                    if (value !=
                                                        _newPasswordController
                                                            .text) {
                                                      return tr(
                                                        'auth.validation.passwords_do_not_match',
                                                      );
                                                    }
                                                    return null;
                                                  },
                                                )
                                                .animate()
                                                .fadeIn(delay: 800.ms)
                                                .slideX(begin: -0.3),
                                          ],
                                        ),
                                      ),
                                    ),

                                    SizedBox(height: screenHeight * 0.04),

                                    // Reset Button
                                    GestureDetector(
                                          onTapDown: (_) => setState(
                                            () => _isResetPressed = true,
                                          ),
                                          onTapUp: (_) => setState(
                                            () => _isResetPressed = false,
                                          ),
                                          onTapCancel: () => setState(
                                            () => _isResetPressed = false,
                                          ),
                                          onTap: () async {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              final authProvider = context
                                                  .read<AuthProvider>();
                                              authProvider.clearError();

                                              final success = await authProvider
                                                  .resetPasswordByUrl(
                                                    resetUrl:
                                                        _resetUrlController.text
                                                            .trim(),
                                                    newPassword:
                                                        _newPasswordController
                                                            .text,
                                                  );

                                              if (success && context.mounted) {
                                                // Show success message
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      tr(
                                                        'auth.reset.success_message',
                                                      ),
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                  ),
                                                );
                                                // Navigate back to login
                                                context.go('/login');
                                              }
                                            }
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 150,
                                            ),
                                            transform: Matrix4.identity()
                                              ..scale(
                                                _isResetPressed ? 0.98 : 1.0,
                                              ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                    horizontal: 32,
                                                  ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    AppColors.primary,
                                                    AppColors.primary
                                                        .withOpacity(0.8),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.primary
                                                        .withOpacity(0.4),
                                                    blurRadius: _isResetPressed
                                                        ? 8
                                                        : 15,
                                                    offset: Offset(
                                                      0,
                                                      _isResetPressed ? 4 : 8,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    tr(
                                                      'auth.reset.reset_button',
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(
                                                    Icons.check_rounded,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                        .animate()
                                        .fadeIn(delay: 900.ms)
                                        .slideY(begin: 0.3),

                                    SizedBox(height: screenHeight * 0.02),

                                    // Back to Login Link
                                    GestureDetector(
                                      onTap: () => context.go('/login'),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          tr('auth.reset.back_to_login'),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ).animate().fadeIn(delay: 1000.ms),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvancedTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final int maxLines;
  final String? Function(String?)? validator;

  const _AdvancedTextField({
    required this.label,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.maxLines = 1,
    this.validator,
  });

  @override
  State<_AdvancedTextField> createState() => _AdvancedTextFieldState();
}

class _AdvancedTextFieldState extends State<_AdvancedTextField> {
  bool _isFocused = false;
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 6),
          decoration: BoxDecoration(
            color: _isFocused
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused
                  ? AppColors.primary.withOpacity(0.5)
                  : AppColors.primary.withOpacity(0.1),
              width: 2,
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            obscureText: widget.obscureText && !_isPasswordVisible,
            maxLines: widget.maxLines,
            validator: widget.validator,
            onTap: () => setState(() => _isFocused = true),
            onTapOutside: (_) => setState(() => _isFocused = false),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle: TextStyle(
                color: _isFocused ? AppColors.primary : Colors.black54,
                fontSize: 14,
                fontWeight: _isFocused ? FontWeight.w600 : FontWeight.normal,
              ),
              prefixIcon: Icon(
                widget.icon,
                color: _isFocused ? AppColors.primary : Colors.black54,
                size: 20,
              ),
              suffixIcon: widget.obscureText
                  ? GestureDetector(
                      onTap: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                      child: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: _isFocused ? AppColors.primary : Colors.black54,
                        size: 20,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
