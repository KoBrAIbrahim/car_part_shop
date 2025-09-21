import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/language_switcher.dart';
import '../../../core/widgets/top_notification.dart';
import '../../../core/widgets/auth_loading_overlay.dart';
import '../../../core/utils/phone_validation_utils.dart';
import '../widgets/custom_text_field.dart';
import '../auth_provider.dart';
import '../widgets/country_code_picker.dart';
import '../widgets/city_selector.dart';

class BuyerSignupPage extends StatefulWidget {
  const BuyerSignupPage({super.key});

  @override
  State<BuyerSignupPage> createState() => _BuyerSignupPageState();
}

class _BuyerSignupPageState extends State<BuyerSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  String? _selectedCity;
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedCountryCode = '+972';
  String _loadingMessage = 'auth.loading.creating_account';

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isRtl {
    final locale = context.locale.languageCode;
    return locale == 'ar' || locale == 'he';
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
                backgroundColor: AppColors.background,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => context.go('/signup'),
                  ),
                  title: Text('auth.signup.buyer_title'.tr()),
                  actions: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: LanguageSwitcher(),
                    ),
                  ],
                ),
                body: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),

                          CustomTextField(
                            label: 'auth.signup.full_name'.tr(),
                            controller: _fullNameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'auth.validation.required_field'.tr();
                              }
                              return null;
                            },
                          ).animate().fadeIn().slideX(begin: -0.2),

                          const SizedBox(height: 16),

                          CitySelector(
                            selectedCity: _selectedCity,
                            onCityChanged: (city) {
                              setState(() {
                                _selectedCity = city;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'auth.validation.required_field'.tr();
                              }
                              return null;
                            },
                          ).animate().fadeIn().slideX(begin: 0.2),

                          const SizedBox(height: 16),

                          Row(
                            children: [
                              CountryCodePicker(
                                initialValue: _selectedCountryCode,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCountryCode = value;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CustomTextField(
                                  label: 'auth.signup.mobile'.tr(),
                                  controller: _mobileController,
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'auth.validation.required_field'
                                          .tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ).animate().fadeIn(),

                          const SizedBox(height: 16),

                          CustomTextField(
                            label: 'auth.signup.email'.tr(),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'auth.validation.required_field'.tr();
                              }
                              if (!value.contains('@')) {
                                return 'auth.validation.invalid_email'.tr();
                              }
                              return null;
                            },
                          ).animate().fadeIn().slideX(begin: -0.2),

                          const SizedBox(height: 16),

                          CustomTextField(
                            label: 'auth.signup.password'.tr(),
                            controller: _passwordController,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'auth.validation.required_field'.tr();
                              }
                              if (value.length < 6) {
                                return 'auth.validation.password_too_short'
                                    .tr();
                              }
                              return null;
                            },
                          ).animate().fadeIn().slideX(begin: 0.2),

                          const SizedBox(height: 16),

                          CustomTextField(
                            label: 'auth.signup.confirm_password'.tr(),
                            controller: _confirmPasswordController,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'auth.validation.required_field'.tr();
                              }
                              if (value != _passwordController.text) {
                                return 'auth.validation.passwords_dont_match'
                                    .tr();
                              }
                              return null;
                            },
                          ).animate().fadeIn().slideX(begin: -0.2),

                          const SizedBox(height: 24),

                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                // Validate phone number first and show top notification if invalid
                                final isPhoneValid =
                                    PhoneValidationUtils.validatePhoneAndShowNotification(
                                      context,
                                      phone: _mobileController.text.trim(),
                                      countryCode: _selectedCountryCode,
                                      showNotification: true,
                                    );

                                if (!isPhoneValid) {
                                  return; // Stop execution if phone is invalid
                                }

                                // Update loading message
                                setState(() {
                                  _loadingMessage =
                                      'auth.loading.setting_up_profile';
                                });

                                final authProvider = context
                                    .read<AuthProvider>();

                                // Split full name into first and last name
                                final nameParts = _fullNameController.text
                                    .trim()
                                    .split(' ');
                                final firstName = nameParts.isNotEmpty
                                    ? nameParts.first
                                    : '';
                                final lastName = nameParts.length > 1
                                    ? nameParts.skip(1).join(' ')
                                    : '';

                                final success = await authProvider.signupCustomer(
                                  firstName: firstName,
                                  lastName: lastName,
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                  phoneNumber:
                                      '$_selectedCountryCode${_mobileController.text.trim()}',
                                  city: _selectedCity ?? '',
                                  address:
                                      _selectedCity ??
                                      '', // Use city as address/location
                                );

                                if (success && context.mounted) {
                                  // Navigate to dashboard on successful signup
                                  context.go('/dashboard');
                                } else if (context.mounted) {
                                  // Reset loading message on error
                                  setState(() {
                                    _loadingMessage =
                                        'auth.loading.creating_account';
                                  });

                                  // Check if it's a phone or last name validation error from server
                                  final errorMessage =
                                      authProvider.errorMessage ?? '';
                                  if (errorMessage.contains('phone') ||
                                      errorMessage.contains('Phone') ||
                                      errorMessage ==
                                          'auth.validation.phone_already_used' ||
                                      errorMessage ==
                                          'auth.validation.phone_check_failed' ||
                                      errorMessage ==
                                          'auth.validation.invalid_phone_format' ||
                                      errorMessage.contains('last name') ||
                                      errorMessage.contains('Last name') ||
                                      errorMessage ==
                                          'auth.validation.last_name_required' ||
                                      errorMessage ==
                                          'auth.validation.signup_failed') {
                                    // Show phone/last name/signup error as top notification
                                    TopNotification.show(
                                      context,
                                      message: errorMessage,
                                      type: NotificationType.error,
                                      duration: const Duration(seconds: 4),
                                      shouldTranslate: true,
                                    );
                                  } else {
                                    // Show other errors as SnackBar
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          errorMessage.tr(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: AppColors.error,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textDark,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'auth.signup.signup_button'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ).animate().fadeIn().scale(),

                          const SizedBox(height: 24),

                          TextButton(
                            onPressed: () {
                              context.go('/login');
                            },
                            child: Text(
                              'auth.signup.login_link'.tr(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ).animate().fadeIn(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
