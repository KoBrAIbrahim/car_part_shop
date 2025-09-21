// The complete updated file content will be here, fixing the layout issues and making it more responsive
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/language_switcher.dart';
import '../../../core/widgets/auth_loading_overlay.dart';
import '../auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _backgroundController;
  late AnimationController _pulseController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _pulseAnimation;
  bool _isLoginPressed = false;
  String _loadingMessage = 'auth.loading.verifying_credentials';

  @override
  void initState() {
    super.initState();

    // Initialize controllers first
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Initialize animations after controllers are ready
    _backgroundAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_backgroundController);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations after they're initialized
    _backgroundController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _backgroundController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isRtl {
    final locale = context.locale.languageCode;
    return locale == 'ar' || locale == 'he';
  }

  void _showForgotPasswordBottomSheet(BuildContext context) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: _isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: DraggableScrollableSheet(
            initialChildSize: 0.8,
            maxChildSize: 0.9,
            minChildSize: 0.6,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_reset_rounded,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        tr('auth.login.reset_password'),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Text(
                        tr('auth.login.reset_password_desc'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textDark.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Email form
                      Form(
                        key: formKey,
                        child: _AdvancedTextField(
                          label: 'auth.login.email'.tr(),
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          icon: Icons.email_outlined,
                          isCompact: false,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'auth.validation.required_field'.tr();
                            }
                            if (!RegExp(
                              r'^[^@]+@[^@]+\.[^@]+',
                            ).hasMatch(value)) {
                              return 'auth.validation.invalid_email'.tr();
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Send button
                      SizedBox(
                        width: double.infinity,
                        child: Consumer<AuthProvider>(
                          builder: (context, auth, _) {
                            return ElevatedButton(
                              onPressed: auth.isLoading
                                  ? null
                                  : () async {
                                      if (formKey.currentState!.validate()) {
                                        final success = await context
                                            .read<AuthProvider>()
                                            .sendPasswordReset(
                                              emailController.text,
                                            );

                                        Navigator.of(context).pop();

                                        if (success) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                tr(
                                                  'auth.login.reset_email_sent',
                                                ),
                                              ),
                                              backgroundColor: Colors.green,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        } else {
                                          final errorMessage =
                                              context
                                                  .read<AuthProvider>()
                                                  .errorMessage ??
                                              tr('auth.login.reset_failed');
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(errorMessage),
                                              backgroundColor: Colors.red,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: auth.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      tr('auth.login.send_reset_link'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Link to full reset page
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/password-reset');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.link_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tr('auth.reset.use_reset_link'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return AuthLoadingOverlay(
          isVisible: authProvider.isLoading,
          message: _loadingMessage,
          child: Theme(
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
              textDirection: _isRtl
                  ? ui.TextDirection.rtl
                  : ui.TextDirection.ltr,
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
                        left:
                            (index * 60.0) % MediaQuery.of(context).size.width,
                        top:
                            (index * 100.0) %
                            MediaQuery.of(context).size.height,
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
                                  opacity:
                                      0.05 + 0.1 * _backgroundAnimation.value,
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
                          final isCompact = screenHeight < 700;

                          return Padding(
                            padding: const EdgeInsets.fromLTRB(
                              16.0,
                              8.0,
                              16.0,
                              16.0,
                            ),
                            child: Column(
                              children: [
                                // Language Switcher at top
                                Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: AppColors
                                                .cardBackground, // Use class color instead of Colors.white
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withOpacity(0.1),
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
                                    )
                                    .animate()
                                    .fadeIn(delay: 200.ms)
                                    .slideY(begin: -0.5),

                                // Main content
                                Expanded(
                                  child: Center(
                                    child: SingleChildScrollView(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(height: screenHeight * 0.02),

                                          // Logo with pulse animation (smaller size)
                                          AnimatedBuilder(
                                            animation: _pulseAnimation,
                                            builder: (context, child) {
                                              return Transform.scale(
                                                scale: _pulseAnimation.value,
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    gradient: RadialGradient(
                                                      colors: [
                                                        AppColors.primary
                                                            .withOpacity(0.2),
                                                        AppColors.primary
                                                            .withOpacity(0.05),
                                                        AppColors
                                                            .background, // Use class color instead of Colors.transparent
                                                      ],
                                                    ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors
                                                          .cardBackground, // Use class color instead of Colors.white
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: AppColors
                                                              .primary
                                                              .withOpacity(0.3),
                                                          blurRadius: 15,
                                                          offset: const Offset(
                                                            0,
                                                            6,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Icon(
                                                      Icons.car_repair_rounded,
                                                      size: 40,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ).animate().fadeIn().scale(),

                                          SizedBox(height: screenHeight * 0.01),

                                          Text(
                                                'auth.login.title'.tr(),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineSmall
                                                    ?.copyWith(
                                                      color: AppColors.textDark,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                textAlign: TextAlign.center,
                                              )
                                              .animate()
                                              .fadeIn(delay: 400.ms)
                                              .slideY(begin: 0.2),

                                          SizedBox(height: screenHeight * 0.03),

                                          // Login Form
                                          Container(
                                            constraints: const BoxConstraints(
                                              maxWidth: 400,
                                            ),
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              border: Border.all(
                                                color: AppColors.primary
                                                    .withOpacity(0.1),
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
                                                  // Error message above email field
                                                  Consumer<AuthProvider>(
                                                    builder: (context, auth, _) {
                                                      if (auth.errorMessage !=
                                                          null) {
                                                        String localizedError =
                                                            '';
                                                        switch (auth
                                                            .errorMessage) {
                                                          case 'invalid_credentials':
                                                            localizedError =
                                                                'auth.login.invalid_credentials'
                                                                    .tr();
                                                            break;
                                                          case 'network_error':
                                                            localizedError =
                                                                'auth.login.network_error'
                                                                    .tr();
                                                            break;
                                                          case 'login_failed':
                                                            localizedError =
                                                                'auth.login.login_failed'
                                                                    .tr();
                                                            break;
                                                          default:
                                                            localizedError = auth
                                                                .errorMessage!;
                                                        }

                                                        return Container(
                                                          width:
                                                              double.infinity,
                                                          padding:
                                                              const EdgeInsets.all(
                                                                12,
                                                              ),
                                                          margin:
                                                              const EdgeInsets.only(
                                                                bottom: 16,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors
                                                                .red
                                                                .shade50,
                                                            border: Border.all(
                                                              color: Colors
                                                                  .red
                                                                  .shade300,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .error_outline,
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
                                                                    fontSize:
                                                                        14,
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

                                                  _AdvancedTextField(
                                                        label:
                                                            'auth.login.email'
                                                                .tr(),
                                                        controller:
                                                            _emailController,
                                                        keyboardType:
                                                            TextInputType
                                                                .emailAddress,
                                                        icon: Icons
                                                            .email_outlined,
                                                        isCompact: isCompact,
                                                        validator: (value) {
                                                          if (value == null ||
                                                              value.isEmpty) {
                                                            return 'auth.validation.required_field'
                                                                .tr();
                                                          }
                                                          return null;
                                                        },
                                                      )
                                                      .animate()
                                                      .fadeIn(delay: 500.ms)
                                                      .slideX(begin: -0.3),

                                                  const SizedBox(height: 16),

                                                  _AdvancedTextField(
                                                        label:
                                                            'auth.login.password'
                                                                .tr(),
                                                        controller:
                                                            _passwordController,
                                                        obscureText: true,
                                                        icon: Icons
                                                            .lock_outline_rounded,
                                                        isCompact: isCompact,
                                                        validator: (value) {
                                                          if (value == null ||
                                                              value.isEmpty) {
                                                            return 'auth.validation.required_field'
                                                                .tr();
                                                          }
                                                          return null;
                                                        },
                                                      )
                                                      .animate()
                                                      .fadeIn(delay: 600.ms)
                                                      .slideX(begin: 0.3),

                                                  const SizedBox(height: 16),

                                                  // Remember Me and Forgot Password on same row
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      // Remember Me
                                                      Consumer<AuthProvider>(
                                                        builder: (context, auth, _) => GestureDetector(
                                                          onTap: () => auth
                                                              .setRememberMe(
                                                                !auth
                                                                    .rememberMe,
                                                              ),
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  8,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  auth.rememberMe
                                                                  ? AppColors
                                                                        .primary
                                                                        .withOpacity(
                                                                          0.1,
                                                                        )
                                                                  : Colors
                                                                        .transparent,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                              border: Border.all(
                                                                color:
                                                                    auth.rememberMe
                                                                    ? AppColors
                                                                          .primary
                                                                          .withOpacity(
                                                                            0.3,
                                                                          )
                                                                    : Colors
                                                                          .transparent,
                                                              ),
                                                            ),
                                                            child: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                AnimatedContainer(
                                                                  duration:
                                                                      const Duration(
                                                                        milliseconds:
                                                                            200,
                                                                      ),
                                                                  width: 16,
                                                                  height: 16,
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        auth.rememberMe
                                                                        ? AppColors
                                                                              .primary
                                                                        : Colors
                                                                              .transparent,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          4,
                                                                        ),
                                                                    border: Border.all(
                                                                      color: AppColors
                                                                          .primary,
                                                                      width: 2,
                                                                    ),
                                                                  ),
                                                                  child:
                                                                      auth.rememberMe
                                                                      ? const Icon(
                                                                          Icons
                                                                              .check,
                                                                          size:
                                                                              12,
                                                                          color:
                                                                              Colors.white,
                                                                        )
                                                                      : null,
                                                                ),
                                                                const SizedBox(
                                                                  width: 8,
                                                                ),
                                                                Text(
                                                                  tr(
                                                                    'auth.login.remember_me',
                                                                  ),
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    color: AppColors
                                                                        .textDark,
                                                                    fontWeight:
                                                                        auth.rememberMe
                                                                        ? FontWeight
                                                                              .w600
                                                                        : FontWeight
                                                                              .normal,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ).animate().fadeIn(delay: 650.ms).slideX(begin: -0.3),

                                                      // Forgot Password Link
                                                      GestureDetector(
                                                        onTap: () =>
                                                            _showForgotPasswordBottomSheet(
                                                              context,
                                                            ),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 12,
                                                                vertical: 8,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: AppColors
                                                                .primary
                                                                .withOpacity(
                                                                  0.1,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            tr(
                                                              'auth.login.forgot_password',
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 14,
                                                                  color: Colors
                                                                      .black54,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal,
                                                                ),
                                                          ),
                                                        ),
                                                      ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.3),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          SizedBox(height: screenHeight * 0.03),

                                          // Login Button
                                          GestureDetector(
                                            onTapDown: (_) => setState(
                                              () => _isLoginPressed = true,
                                            ),
                                            onTapUp: (_) => setState(
                                              () => _isLoginPressed = false,
                                            ),
                                            onTapCancel: () => setState(
                                              () => _isLoginPressed = false,
                                            ),
                                            onTap: () async {
                                              if (_formKey.currentState!
                                                  .validate()) {
                                                final authProvider = context
                                                    .read<AuthProvider>();

                                                // Update loading message to logging in
                                                setState(() {
                                                  _loadingMessage =
                                                      'auth.loading.logging_in';
                                                });

                                                // Clear any previous errors
                                                authProvider.clearError();

                                                final success =
                                                    await authProvider.login(
                                                      email: _emailController
                                                          .text
                                                          .trim(),
                                                      password:
                                                          _passwordController
                                                              .text,
                                                    );

                                                if (success &&
                                                    context.mounted) {
                                                  // Navigate to dashboard on successful login
                                                  context.go('/dashboard');
                                                } else {
                                                  // Reset loading message back to verifying
                                                  setState(() {
                                                    _loadingMessage =
                                                        'auth.loading.verifying_credentials';
                                                  });
                                                }
                                                // Error messages are now displayed automatically
                                                // via the Consumer widget above the email field
                                              }
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 150,
                                              ),
                                              transform: Matrix4.identity()
                                                ..scale(
                                                  _isLoginPressed ? 0.98 : 1.0,
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
                                                      blurRadius:
                                                          _isLoginPressed
                                                          ? 8
                                                          : 15,
                                                      offset: Offset(
                                                        0,
                                                        _isLoginPressed ? 4 : 8,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      tr(
                                                        'auth.login.login_button',
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
                                                      Icons
                                                          .arrow_forward_rounded,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),

                                          SizedBox(height: screenHeight * 0.02),

                                          // Sign Up Link
                                          GestureDetector(
                                            onTap: () => context.go('/signup'),
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: RichText(
                                                textAlign: TextAlign.center,
                                                text: TextSpan(
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: AppColors.textDark
                                                        .withOpacity(0.7),
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text: tr(
                                                        'auth.login.signup_link',
                                                      ),
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        decoration:
                                                            TextDecoration.none,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ).animate().fadeIn(delay: 900.ms),
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
          ),
        );
      },
    );
  }
}

class _AdvancedTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData icon;
  final bool isCompact;
  final String? Function(String?)? validator;

  const _AdvancedTextField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.isCompact,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
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
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText && !_isPasswordVisible,
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
