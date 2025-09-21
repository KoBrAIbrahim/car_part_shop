import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../auth/auth_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Garage-specific controllers
  final _garageNameController = TextEditingController();
  final _garageAddressController = TextEditingController();
  final _vatNumberController = TextEditingController();

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isEditing = false;
  bool _isLoading = false;
  Map<String, dynamic>? _customerMetafields;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _scaleController.forward();

    // Load user data
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _garageNameController.dispose();
    _garageAddressController.dispose();
    _vatNumberController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  bool get _isRtl {
    final locale = context.locale.languageCode;
    return locale == 'ar' || locale == 'he';
  }

  void _loadUserData() {
    final authProvider = context.read<AuthProvider>();
    final customerInfo = authProvider.customerInfo;

    if (customerInfo != null) {
      _firstNameController.text = customerInfo['firstName'] ?? '';
      _lastNameController.text = customerInfo['lastName'] ?? '';
      _emailController.text = customerInfo['email'] ?? '';
      _phoneController.text = customerInfo['phone'] ?? '';
    }

    // Load metafields for garage owners
    _loadCustomerMetafields();
  }

  Future<void> _loadCustomerMetafields() async {
    final authProvider = context.read<AuthProvider>();

    // First update customer type from metafields
    await authProvider.updateCustomerTypeFromMetafields();

    // Then check if user is garage owner
    bool isGarage = authProvider.isGarageOwner();

    // If still not detected as garage owner, try checking metafields directly
    if (!isGarage) {
      isGarage = await authProvider.hasGarageMetafields();
    }

    if (isGarage) {
      print('🏪 Loading garage owner metafields...');

      try {
        final metafields = await authProvider.getCustomerMetafields();

        if (metafields != null && mounted) {
          setState(() {
            _customerMetafields = metafields;
          });

          // Parse metafields and populate controllers
          final metafieldsList = metafields['metafields']?['edges'] ?? [];

          for (final edge in metafieldsList) {
            final metafield = edge['node'];
            final key = metafield['key'];
            final value = metafield['value'];

            switch (key) {
              case 'garage_name':
                _garageNameController.text = value ?? '';
                break;
              case 'garage_address':
                _garageAddressController.text = value ?? '';
                break;
              case 'vat_number':
                _vatNumberController.text = value ?? '';
                break;
              case 'customer_city':
                _cityController.text = value ?? '';
                break;
              case 'phone':
                // Update phone controller if not already populated from customer info
                if (_phoneController.text.isEmpty) {
                  _phoneController.text = value ?? '';
                }
                break;
              case 'email':
                // Update email controller if not already populated from customer info
                if (_emailController.text.isEmpty) {
                  _emailController.text = value ?? '';
                }
                break;
              case 'full_name':
                // Split full name if individual names are not available
                if (_firstNameController.text.isEmpty &&
                    _lastNameController.text.isEmpty) {
                  final nameParts = (value ?? '').toString().split(' ');
                  if (nameParts.isNotEmpty) {
                    _firstNameController.text = nameParts.first;
                    if (nameParts.length > 1) {
                      _lastNameController.text = nameParts.skip(1).join(' ');
                    }
                  }
                }
                break;
            }
          }

          print('✅ Metafields loaded and controllers populated');

          // Trigger a rebuild to show garage information
          setState(() {});
        }
      } catch (e) {
        print('❌ Error loading metafields: $e');
      }
    } else {
      print('ℹ️ User is not a garage owner, checking for basic metafields...');

      // Even for non-garage customers, try to load metafields for phone, email, etc.
      try {
        final metafields = await authProvider.getCustomerMetafields();

        if (metafields != null && mounted) {
          setState(() {
            _customerMetafields = metafields;
          });

          // Parse metafields and populate controllers for basic info
          final metafieldsList = metafields['metafields']?['edges'] ?? [];

          for (final edge in metafieldsList) {
            final metafield = edge['node'];
            final key = metafield['key'];
            final value = metafield['value'];

            switch (key) {
              case 'customer_city':
                _cityController.text = value ?? '';
                break;
              case 'phone':
                // Update phone controller if not already populated from customer info
                if (_phoneController.text.isEmpty) {
                  _phoneController.text = value ?? '';
                }
                break;
              case 'email':
                // Update email controller if not already populated from customer info
                if (_emailController.text.isEmpty) {
                  _emailController.text = value ?? '';
                }
                break;
              case 'full_name':
                // Split full name if individual names are not available
                if (_firstNameController.text.isEmpty &&
                    _lastNameController.text.isEmpty) {
                  final nameParts = (value ?? '').toString().split(' ');
                  if (nameParts.isNotEmpty) {
                    _firstNameController.text = nameParts.first;
                    if (nameParts.length > 1) {
                      _lastNameController.text = nameParts.skip(1).join(' ');
                    }
                  }
                }
                break;
            }
          }

          print('✅ Basic metafields loaded for regular customer');
          setState(() {});
        }
      } catch (e) {
        print('❌ Error loading metafields for regular customer: $e');
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();

      // Prepare data for update (excluding email and phone)
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final city = _cityController.text.trim();

      // Garage-specific data
      final garageName = _garageNameController.text.trim();
      final garageAddress = _garageAddressController.text.trim();
      final vatNumber = _vatNumberController.text.trim();

      print('🔄 Updating profile with data:');
      print('First Name: $firstName');
      print('Last Name: $lastName');
      print('City: $city');
      print('Garage Name: $garageName');
      print('Garage Address: $garageAddress');
      print('VAT Number: $vatNumber');

      // Update customer profile via AuthProvider
      final success = await authProvider.updateCustomerProfile(
        firstName: firstName.isNotEmpty ? firstName : null,
        lastName: lastName.isNotEmpty ? lastName : null,
        city: city.isNotEmpty ? city : null,
        garageName: garageName.isNotEmpty ? garageName : null,
        garageAddress: garageAddress.isNotEmpty ? garageAddress : null,
        vatNumber: vatNumber.isNotEmpty ? vatNumber : null,
      );

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('profile.update_success')),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('profile.update_failed')),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('profile.update_failed')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _resetPassword() async {
    final authProvider = context.read<AuthProvider>();
    final customerInfo = authProvider.customerInfo;
    final email = customerInfo?['email'] as String?;

    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('auth.login.no_email_found')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await authProvider.sendPasswordReset(email);

      setState(() => _isLoading = false);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('auth.login.reset_email_sent')),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('auth.login.reset_failed')),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error sending password reset: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('auth.login.reset_failed')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Directionality(
          textDirection: _isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: Scaffold(
            backgroundColor: AppColors.getBackground(isDark),
            body: SafeArea(
              child: Column(
                children: [
                  // Custom App Bar
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.getCardBackground(isDark),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => context.pop(),
                                icon: Icon(
                                  _isRtl
                                      ? Icons.arrow_forward_ios
                                      : Icons.arrow_back_ios,
                                  color: AppColors.getTextColor(isDark),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tr('profile.title'),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.getTextColor(isDark),
                                  ),
                                ),
                              ),
                              if (!_isEditing)
                                IconButton(
                                  onPressed: () =>
                                      setState(() => _isEditing = true),
                                  icon: Icon(
                                    Icons.edit_rounded,
                                    color: AppColors.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Content
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Profile Avatar
                                  Consumer<AuthProvider>(
                                    builder: (context, auth, _) {
                                      return Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.primary,
                                              AppColors.primary.withOpacity(
                                                0.7,
                                              ),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withOpacity(0.3),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            _getInitials(auth.customerInfo),
                                            style: const TextStyle(
                                              fontSize: 40,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ).animate().scale(delay: 200.ms);
                                    },
                                  ),

                                  const SizedBox(height: 30),

                                  // Customer Type Badge
                                  Consumer<AuthProvider>(
                                    builder: (context, auth, _) {
                                      // Debug info
                                      print(
                                        '🔍 Current customer type: ${auth.customerType}',
                                      );
                                      print(
                                        '🔍 Is garage owner: ${auth.isGarageOwner()}',
                                      );

                                      return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.accent
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: AppColors.accent
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  auth.customerType ==
                                                          CustomerType
                                                              .garageCustomer
                                                      ? Icons.build_rounded
                                                      : Icons.person_rounded,
                                                  color: AppColors.accent,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  auth.customerType ==
                                                          CustomerType
                                                              .garageCustomer
                                                      ? tr(
                                                          'profile.garage_owner',
                                                        )
                                                      : tr(
                                                          'profile.regular_buyer',
                                                        ),
                                                  style: TextStyle(
                                                    color: AppColors.accent,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                          .animate()
                                          .fadeIn(delay: 300.ms)
                                          .slideX(begin: 0.3);
                                    },
                                  ),

                                  const SizedBox(height: 40),

                                  // Profile Form
                                  _buildProfileCard(isDark),

                                  const SizedBox(height: 30),

                                  // Garage Information Card (for garage types only)
                                  Consumer<AuthProvider>(
                                    builder: (context, auth, _) {
                                      if (auth.isAnyGarageType()) {
                                        return Column(
                                          children: [
                                            // Garage Status Banner
                                            _buildGarageStatusBanner(
                                              isDark,
                                              auth,
                                            ),
                                            const SizedBox(height: 20),
                                            // Garage Info Card
                                            _buildGarageInfoCard(isDark, auth),
                                            const SizedBox(height: 30),
                                          ],
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),

                                  const SizedBox(height: 30),

                                  // Action Buttons
                                  if (_isEditing) _buildActionButtons(isDark),
                                ],
                              ),
                            ),
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
      },
    );
  }

  Widget _buildProfileCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                tr('profile.personal_info'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // First Name
          _buildProfileField(
            label: tr('profile.first_name'),
            controller: _firstNameController,
            icon: Icons.person_outline,
            enabled: _isEditing,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return tr('validation.required_field');
              }
              return null;
            },
          ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.3),

          const SizedBox(height: 20),

          // Last Name
          _buildProfileField(
            label: tr('profile.last_name'),
            controller: _lastNameController,
            icon: Icons.person_outline,
            enabled: _isEditing,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return tr('validation.required_field');
              }
              return null;
            },
          ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.3),

          const SizedBox(height: 20),

          // Email
          _buildProfileField(
            label: tr('profile.email'),
            controller: _emailController,
            icon: Icons.email_outlined,
            enabled: false, // Email usually shouldn't be editable
            keyboardType: TextInputType.emailAddress,
          ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.3),

          const SizedBox(height: 20),

          // Phone
          _buildProfileField(
            label: tr('profile.phone'),
            controller: _phoneController,
            icon: Icons.phone_outlined,
            enabled: false, // Phone is read-only
            keyboardType: TextInputType.phone,
          ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.3),

          const SizedBox(height: 20),

          // Reset Password Button
          _buildResetPasswordButton(
            isDark,
          ).animate().fadeIn(delay: 750.ms).slideY(begin: 0.3),

          const SizedBox(height: 20),

          // City
          _buildProfileField(
            label: tr('profile.city'),
            controller: _cityController,
            icon: Icons.location_city_outlined,
            enabled: _isEditing,
            keyboardType: TextInputType.text,
            validator: (value) {
              // City is optional, no validation required
              print('🏙️ City field validator called with value: $value');
              return null;
            },
          ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.3),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.3);
  }

  Widget _buildGarageStatusBanner(bool isDark, AuthProvider auth) {
    print(
      '🔍 DEBUG: Building garage status banner for customerType: ${auth.customerType}',
    );
    print('🔍 DEBUG: isGarageOwner: ${auth.isGarageOwner}');
    print('🔍 DEBUG: isGaragePending: ${auth.isGaragePending}');
    print('🔍 DEBUG: isGarageRejected: ${auth.isGarageRejected}');
    print('🔍 DEBUG: canEditGarageInfo: ${auth.canEditGarageInfo}');

    Color bannerColor;
    IconData bannerIcon;
    String titleKey;
    String messageKey;
    bool showWhatsApp = false;

    switch (auth.customerType) {
      case CustomerType.garagePending:
        print('🟡 DEBUG: Showing PENDING banner');
        bannerColor = Colors.orange;
        bannerIcon = Icons.schedule_rounded;
        titleKey = 'profile.garage_status_pending';
        messageKey = 'profile.garage_status_pending_message';
        break;
      case CustomerType.garageRejected:
        print('🔴 DEBUG: Showing REJECTED banner');
        bannerColor = Colors.red;
        bannerIcon = Icons.cancel_rounded;
        titleKey = 'profile.garage_status_rejected';
        messageKey = 'profile.garage_status_rejected_message';
        showWhatsApp = true;
        break;
      case CustomerType.garageCustomer:
        print('🟢 DEBUG: Showing APPROVED banner');
        bannerColor = Colors.green;
        bannerIcon = Icons.check_circle_rounded;
        titleKey = 'profile.garage_status_approved';
        messageKey = 'profile.garage_status_approved_message';
        break;
      default:
        print('⚪ DEBUG: No banner - customerType: ${auth.customerType}');
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(bannerIcon, color: bannerColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tr(titleKey),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: bannerColor,
                  ),
                ),
              ),
              // Refresh button
              InkWell(
                onTap: () => _refreshAccountStatus(auth),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bannerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.refresh, color: bannerColor, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tr(messageKey),
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextColor(isDark),
              height: 1.4,
            ),
          ),
          if (showWhatsApp) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _openWhatsApp(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tr('profile.contact_admin'),
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.3);
  }

  void _openWhatsApp() {
    final whatsappNumber = tr('profile.whatsapp_number');
    final message = Uri.encodeComponent(
      'مرحبا، أحتاج مساعدة بخصوص حساب الكراج المرفوض',
    );
    final url = 'https://wa.me/$whatsappNumber?text=$message';

    // You would typically use url_launcher package here
    print('Opening WhatsApp: $url');
    // Launch URL implementation would go here
  }

  Future<void> _refreshAccountStatus(AuthProvider auth) async {
    print('🔄 Refreshing account status...');

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('profile.refreshing_status')),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    try {
      // Refresh customer info from Shopify
      await auth.refreshCustomerInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('profile.status_refreshed')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error refreshing status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('profile.refresh_failed')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildGarageInfoCard(bool isDark, AuthProvider auth) {
    // Check if user can edit garage info based on status
    bool canEdit = _isEditing && auth.canEditGarageInfo();
    print(
      '🔍 DEBUG: Garage info card - _isEditing: $_isEditing, canEditGarageInfo: ${auth.canEditGarageInfo()}, final canEdit: $canEdit',
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store_outlined, color: AppColors.accent, size: 24),
              const SizedBox(width: 12),
              Text(
                tr('profile.garage_info'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // VAT Number
          _buildProfileField(
            label: tr('profile.vat_number'),
            controller: _vatNumberController,
            icon: Icons.receipt_long_outlined,
            enabled: canEdit,
            keyboardType: TextInputType.number,
          ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.3),

          const SizedBox(height: 20),

          // Garage Name
          _buildProfileField(
            label: tr('profile.garage_name'),
            controller: _garageNameController,
            icon: Icons.business_outlined,
            enabled: canEdit,
            validator: (value) {
              if (canEdit && (value == null || value.isEmpty)) {
                return tr('validation.required_field');
              }
              return null;
            },
          ).animate().fadeIn(delay: 900.ms).slideX(begin: 0.3),

          const SizedBox(height: 20),

          // Garage Address
          _buildProfileField(
            label: tr('profile.garage_address'),
            controller: _garageAddressController,
            icon: Icons.location_on_outlined,
            enabled: canEdit,
            maxLines: 2,
            validator: (value) {
              if (canEdit && (value == null || value.isEmpty)) {
                return tr('validation.required_field');
              }
              return null;
            },
          ).animate().fadeIn(delay: 1000.ms).slideX(begin: -0.3),

          // Garage Image Display
          if (_customerMetafields != null) ...[
            const SizedBox(height: 20),
            _buildGarageImageSection(isDark),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.3);
  }

  Widget _buildGarageImageSection(bool isDark) {
    // Find garage image metafield
    final metafieldsList = _customerMetafields!['metafields']?['edges'] ?? [];
    String? garageImageValue;

    for (final edge in metafieldsList) {
      final metafield = edge['node'];
      if (metafield['key'] == 'garage_image') {
        garageImageValue = metafield['value'];
        break;
      }
    }

    // Debug logging
    print('🖼️ Garage image value found: $garageImageValue');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image_outlined, color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            Text(
              tr('profile.garage_image'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextColor(isDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Dynamic content based on image availability
        if (garageImageValue != null && garageImageValue.isNotEmpty) ...[
          if (garageImageValue.startsWith('gid://shopify/')) ...[
            // Show GID conversion widget
            _buildGidImageWidget(garageImageValue, isDark),
          ] else if (_isValidImageUrl(garageImageValue)) ...[
            // Show normal image
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  garageImageValue,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('❌ Image load error: $error');
                    return _buildImageErrorWidget();
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ] else ...[
            _buildInvalidImageWidget(garageImageValue, isDark),
          ],
        ] else ...[
          _buildNoImageWidget(),
        ],
      ],
    );
  }

  Widget _buildProfileField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLines,
  }) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines ?? 1,
          style: TextStyle(color: AppColors.getTextColor(isDark), fontSize: 16),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(
              icon,
              color: enabled ? AppColors.primary : Colors.grey,
            ),
            filled: true,
            fillColor: enabled
                ? AppColors.primary.withOpacity(0.05)
                : Colors.grey.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            labelStyle: TextStyle(
              color: enabled ? AppColors.primary : Colors.grey,
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() => _isEditing = false);
                    _loadUserData(); // Reset form
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              tr('profile.cancel'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    tr('profile.save'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.5);
  }

  Widget _buildResetPasswordButton(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _resetPassword,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.lock_reset, size: 20),
        label: Text(
          tr('profile.reset.reset_button'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  String _getInitials(Map<String, dynamic>? customerInfo) {
    if (customerInfo == null) return 'U';

    final firstName = customerInfo['firstName']?.toString() ?? '';
    final lastName = customerInfo['lastName']?.toString() ?? '';

    String initials = '';
    if (firstName.isNotEmpty) initials += firstName[0].toUpperCase();
    if (lastName.isNotEmpty) initials += lastName[0].toUpperCase();

    // If no name available, try email
    if (initials.isEmpty) {
      final email = customerInfo['email']?.toString() ?? '';
      if (email.isNotEmpty) {
        initials = email[0].toUpperCase();
      }
    }

    return initials.isEmpty ? 'U' : initials;
  }

  /// Check if a URL is a valid image URL
  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;

    print('🔍 Checking image URL validity: $url');

    // Check if it's a Shopify GID (needs to be converted to actual URL)
    if (url.startsWith('gid://shopify/')) {
      print('⚠️ Found Shopify GID, attempting conversion: $url');
      // Try to convert GID to URL
      final convertedUrl = _convertShopifyGidToUrl(url);
      if (convertedUrl != null && convertedUrl.isNotEmpty) {
        print('✅ GID converted successfully to: $convertedUrl');
        return _isValidImageUrl(
          convertedUrl,
        ); // Recursive check on converted URL
      } else {
        print('❌ GID conversion failed, treating as invalid');
        return false;
      }
    }

    // Check if it's a valid URL pattern
    final urlPattern = RegExp(r'^https?://');
    if (!urlPattern.hasMatch(url)) {
      print('❌ Invalid URL pattern: $url');
      return false;
    }

    // Check for common image extensions
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    final lowerUrl = url.toLowerCase();

    // Check if URL ends with image extension or contains common image hosting patterns
    final isValid =
        imageExtensions.any((ext) => lowerUrl.contains(ext)) ||
        lowerUrl.contains('shopify') ||
        lowerUrl.contains('cdn') ||
        lowerUrl.contains('image');

    print('✅ URL validation result: $isValid for $url');
    return isValid;
  }

  /// Build error widget for failed image loading
  Widget _buildImageErrorWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            tr('profile.image_load_error'),
            style: TextStyle(
              color: Colors.red.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check network connection',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Build widget for no image available
  Widget _buildNoImageWidget() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 40,
            color: Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            tr('profile.no_garage_image'),
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// Convert Shopify GID to actual image URL
  String? _convertShopifyGidToUrl(String gid) {
    try {
      print('🔄 Converting Shopify GID: $gid');

      // For now, return null to show "no image" since we can't resolve GID to URL
      // without making an API call to Shopify

      // TODO: Implement proper GID to URL conversion via Shopify API
      // This would require querying Shopify with the file GID to get the actual URL

      print('⚠️ GID conversion not implemented, showing no image placeholder');
      return null;
    } catch (e) {
      print('❌ Error converting GID: $e');
      return null;
    }
  }

  Widget _buildGidImageWidget(String gid, bool isDark) {
    return FutureBuilder<String?>(
      future: _convertGidToUrl(gid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.accent),
                  const SizedBox(height: 12),
                  Text(
                    tr('profile.loading_image'),
                    style: TextStyle(
                      color: AppColors.getTextColor(isDark),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          print('❌ GID conversion error: ${snapshot.error}');
          return _buildImageErrorWidget();
        }

        final imageUrl = snapshot.data;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppColors.accent,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('❌ Image load error: $error');
                  return _buildImageErrorWidget();
                },
              ),
            ),
          );
        }

        return _buildImageErrorWidget();
      },
    );
  }

  Widget _buildInvalidImageWidget(String imageValue, bool isDark) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
          const SizedBox(height: 12),
          Text(
            tr('profile.invalid_image_format'),
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Value: $imageValue',
              style: TextStyle(color: Colors.red.shade600, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _convertGidToUrl(String gid) async {
    try {
      print('🔄 Converting GID to URL: $gid');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Use the shopify admin service to convert GID to URL
      final imageUrl = await authProvider.adminService.getFileUrl(gid);

      if (imageUrl != null) {
        print('✅ GID converted successfully: $imageUrl');
        return imageUrl;
      } else {
        print('❌ Failed to convert GID to URL');
        return null;
      }
    } catch (e) {
      print('❌ Error converting GID: $e');
      return null;
    }
  }
}
