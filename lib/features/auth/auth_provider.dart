import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/services/shopify_auth_service.dart';
import '../../core/services/shopify_admin_service.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/services/hive_storage_service.dart';

enum CustomerType { customer, garageCustomer, garagePending, garageRejected }

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  // Shopify Configuration from environment variables
  static String get _shopDomain => dotenv.env['SHOPIFY_STORE_DOMAIN'] ?? '';
  static String get _apiVersion =>
      dotenv.env['SHOPIFY_API_VERSION'] ?? '2025-01';
  static String get _shopUrl =>
      'https://$_shopDomain/api/$_apiVersion/graphql.json';
  static String get _adminShopUrl =>
      'https://$_shopDomain/admin/api/$_apiVersion/graphql.json';
  static String get _storefrontAccessToken =>
      dotenv.env['SHOPIFY_STOREFRONT_ACCESS_TOKEN'] ?? '';
  static String get _adminAccessToken =>
      dotenv.env['SHOPIFY_ADMIN_API_ACCESS_TOKEN'] ?? '';

  late final ShopifyAuthService _authService;
  late final ShopifyAdminService _adminService;

  // State variables
  AuthState _authState = AuthState.initial;
  CustomerType? _customerType;
  Map<String, dynamic>? _customerInfo;
  String? _accessToken;
  String? _errorMessage;
  bool _rememberMe = false;

  // Getters
  AuthState get authState => _authState;
  CustomerType? get customerType => _customerType;
  Map<String, dynamic>? get customerInfo => _customerInfo;
  String? get accessToken => _accessToken;
  String? get errorMessage => _errorMessage;
  bool get rememberMe => _rememberMe;
  bool get isAuthenticated => _authState == AuthState.authenticated;
  bool get isLoading => _authState == AuthState.loading;

  // Expose admin service for file operations
  ShopifyAdminService get adminService => _adminService;

  AuthProvider() {
    _authService = ShopifyAuthService(
      shopUrl: _shopUrl,
      storefrontAccessToken: _storefrontAccessToken,
    );
    _adminService = ShopifyAdminService(
      shopUrl: _adminShopUrl,
      adminAccessToken: _adminAccessToken,
    );
    _initializeAuth();
  }

  /// Initialize authentication from stored data
  Future<void> _initializeAuth() async {
    try {
      _setAuthState(AuthState.loading);

      // Check if user wants to stay logged in (isLogining flag)
      final isLogining = await SecureStorageService.getIsLogining();

      if (isLogining) {
        // Only auto-login if user previously chose "Remember Me"
        final isLoggedIn = await SecureStorageService.isLoggedIn();

        if (isLoggedIn) {
          _accessToken = await SecureStorageService.getAccessToken();
          final customerTypeString =
              await SecureStorageService.getCustomerType();
          _customerInfo = await SecureStorageService.getCustomerInfo();

          if (customerTypeString != null) {
            _customerType = customerTypeString == 'garageCustomer'
                ? CustomerType.garageCustomer
                : CustomerType.customer;
          }

          // Check if token needs refresh
          if (await SecureStorageService.isTokenExpired()) {
            await _refreshToken();
          } else {
            _setAuthState(AuthState.authenticated);
          }
        } else {
          _setAuthState(AuthState.unauthenticated);
        }
      } else {
        // User doesn't want to stay logged in, go to login page
        _setAuthState(AuthState.unauthenticated);
      }

      // Load settings
      final settings = HiveStorageService.getSettings();
      _rememberMe = settings.rememberMe;
    } catch (e) {
      _setError('Failed to initialize authentication: $e');
    }
  }

  /// Set authentication state
  void _setAuthState(AuthState state) {
    _authState = state;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    // Map server-side phone error messages to our translation keys
    if (message == 'Phone is invalid' ||
        message.toLowerCase().contains('phone is invalid') ||
        message.toLowerCase().contains('invalid phone') ||
        message.toLowerCase().contains('phone format')) {
      _errorMessage = 'auth.validation.invalid_phone_format';
    } else if (message.toLowerCase().contains('phone') &&
        (message.toLowerCase().contains('taken') ||
            message.toLowerCase().contains('already') ||
            message.toLowerCase().contains('exists'))) {
      _errorMessage = 'auth.validation.phone_already_used';
    } else if (message == 'Last name can\'t be blank' ||
        message.toLowerCase().contains('last name can\'t be blank') ||
        message.toLowerCase().contains('last name cannot be blank') ||
        message.toLowerCase().contains('lastname can\'t be blank')) {
      _errorMessage = 'auth.validation.last_name_required';
    } else {
      _errorMessage = message;
    }
    _setAuthState(AuthState.error);
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Set remember me
  void setRememberMe(bool value) {
    _rememberMe = value;
    HiveStorageService.updateSetting(rememberMe: value);
    notifyListeners();
  }

  /// Customer Login
  Future<bool> login({required String email, required String password}) async {
    try {
      _setAuthState(AuthState.loading);
      clearError();

      print('🔐 Starting login for: $email');

      final response = await _authService.loginCustomer(
        email: email,
        password: password,
      );

      print('📥 Login response: $response');

      final data = response['data']['customerAccessTokenCreate'];
      final errors = data['customerUserErrors'] as List;

      if (errors.isNotEmpty) {
        final errorMessage = errors.first['message'];
        print('❌ Login error: $errorMessage');
        // Map specific error messages
        if (errorMessage.toLowerCase().contains('unidentified')) {
          _setError('invalid_credentials');
        } else {
          _setError('login_failed');
        }
        return false;
      }

      final tokenData = data['customerAccessToken'];
      if (tokenData == null) {
        print('❌ No access token in response');
        _setError('login_failed');
        return false;
      }

      _accessToken = tokenData['accessToken'];
      final expiresAt = DateTime.parse(tokenData['expiresAt']);

      print('✅ Access token received: ${_accessToken?.substring(0, 10)}...');

      // Get customer info initially from Storefront API
      final customerResponse = await _authService.getCustomerInfo(
        accessToken: _accessToken!,
      );

      print('📥 Customer info response: $customerResponse');

      _customerInfo = customerResponse['data']['customer'];

      if (_customerInfo == null) {
        print('❌ No customer info in response');
        _setError('login_failed');
        return false;
      }

      // Get customer info with tags from Admin API if available
      if (_adminAccessToken != '') {
        try {
          print('🔍 Getting customer info with tags from Admin API...');
          final adminCustomerResponse = await _adminService
              .getCustomerInfoWithTags(customerId: _customerInfo!['id']);

          final adminCustomerInfo = adminCustomerResponse['data']['customer'];
          if (adminCustomerInfo != null) {
            // Use the Admin API customer info which includes tags
            _customerInfo = adminCustomerInfo;
            print(
              '✅ Customer info updated with tags: ${adminCustomerInfo['tags']}',
            );
          }
        } catch (e) {
          print('⚠️ Could not get customer info with tags: $e');
          // Continue with Storefront API data
        }
      }

      // Determine customer type (check metafields if admin token is configured)
      _customerType = CustomerType.customer; // Default

      // Try to determine customer type from metafields (if admin token is available)
      if (_adminAccessToken != '') {
        try {
          print('🔍 Checking customer metafields for type...');

          // Get customer metafields to determine type
          final metafieldsData = await _adminService.getCustomerMetafields(
            _customerInfo!['id'],
          );

          if (metafieldsData != null) {
            final metafieldsList = metafieldsData['metafields']?['edges'] ?? [];

            // Check for garage-specific metafields or account type
            bool isGarageOwner = false;

            for (final edge in metafieldsList) {
              final metafield = edge['node'];
              final key = metafield['key'];
              final value = metafield['value']?.toString() ?? '';

              // Check account_type metafield
              if (key == 'account_type' && value.contains('garage_owner')) {
                isGarageOwner = true;
                print('✅ Found garage owner account type in metafields');
                break;
              }

              // Check for garage-specific fields
              if ([
                    'garage_name',
                    'garage_address',
                    'vat_number',
                  ].contains(key) &&
                  value.isNotEmpty) {
                isGarageOwner = true;
                print('✅ Found garage metafield: $key');
                break;
              }
            }

            if (isGarageOwner) {
              _customerType = CustomerType.garageCustomer;
              print('🏪 Customer identified as garage owner from metafields');
            }
          }
        } catch (e) {
          print('⚠️ Could not check metafields: $e');
        }
      }

      // Also check customer tags for garage_owner_
      final tags = _customerInfo!['tags']?.toString() ?? '';
      if (tags.contains('garage_owner_')) {
        _customerType = CustomerType.garageCustomer;
        print('🏪 Customer identified as garage owner from tags');
      }

      // Check if we have stored customer type from previous sessions (as fallback)
      if (_customerType == CustomerType.customer) {
        final storedCustomerType = await SecureStorageService.getCustomerType();
        if (storedCustomerType != null) {
          try {
            _customerType = CustomerType.values.firstWhere(
              (type) => type.name == storedCustomerType,
              orElse: () => CustomerType.customer,
            );
            print('📋 Using stored customer type: ${_customerType!.name}');
          } catch (e) {
            print('⚠️ Invalid stored customer type: $storedCustomerType');
            _customerType = CustomerType.customer;
          }
        }
      }

      // Save authentication data based on Remember Me setting
      await SecureStorageService.saveAuthData(
        accessToken: _accessToken!,
        customerType: _customerType!.name,
        customerInfo: _customerInfo!,
        expiresAt: expiresAt,
        isLogining:
            _rememberMe, // Only stay logged in if Remember Me is checked
      );

      if (_rememberMe) {
        // Save settings if Remember Me is checked
        await HiveStorageService.updateSetting(
          lastLoginEmail: email,
          rememberMe: true,
        );
        print('💾 Full user data saved with Remember Me enabled');
      } else {
        // Clear remember me setting if unchecked
        await HiveStorageService.updateSetting(rememberMe: false);
        print(
          '💾 User data saved but Remember Me disabled - will not auto-login',
        );
      }

      _setAuthState(AuthState.authenticated);
      print('✅ Login successful for customer: ${_customerInfo!['email']}');
      return true;
    } catch (e) {
      print('💥 Login exception: $e');
      _setError('login_failed');
      return false;
    }
  }

  // AuthProvider.dart (داخل الكلاس AuthProvider أو كـ static helper)
  String _normalizePhone(String raw, {String defaultCountryCode = '+972'}) {
    var s = raw.trim();
    if (s.startsWith('00')) s = '+${s.substring(2)}';
    s = s.replaceAll(RegExp(r'[\s\-()]'), '');
    if (!s.startsWith('+')) s = '$defaultCountryCode$s';
    return s;
  }

  /// Customer Signup
  Future<bool> signupCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phoneNumber,
    String? city,
    String? address,
    String? gender,
    int? age,
  }) async {
    try {
      _setAuthState(AuthState.loading);
      clearError();

      print('📝 Starting signup for: $email');

      // ───────── فحص تكرار الهاتف (مع التطبيع) ─────────
      String? normalizedPhone;
      if (phoneNumber != null &&
          phoneNumber.isNotEmpty &&
          _adminAccessToken.isNotEmpty) {
        normalizedPhone = _normalizePhone(phoneNumber);
        print('📞 [PHONE CHECK] Checking normalized: $normalizedPhone');
        try {
          final exists = await _adminService.isPhoneNumberUsed(normalizedPhone);
          if (exists) {
            _setError(
              'auth.validation.phone_already_used',
            ); // أضف ترجمتها في i18n
            _setAuthState(AuthState.unauthenticated);
            return false;
          }
        } catch (e) {
          print('💥 phone exists check failed: $e');
          _setError('auth.validation.phone_check_failed');
          _setAuthState(AuthState.error);
          return false;
        }
      } else {
        print('⚠️ [PHONE CHECK] Skipped (no phone or no admin token).');
      }

      // ───────── فحص تكرار البريد الإلكتروني ─────────
      if (email.isNotEmpty && _adminAccessToken.isNotEmpty) {
        print('📧 [EMAIL CHECK] Checking email: $email');
        try {
          final exists = await _adminService.isEmailUsed(email);
          if (exists) {
            _setError('auth.validation.email_already_used');
            _setAuthState(AuthState.unauthenticated);
            return false;
          }
        } catch (e) {
          print('💥 email exists check failed: $e');
          _setError('auth.validation.email_check_failed');
          _setAuthState(AuthState.error);
          return false;
        }
      } else {
        print('⚠️ [EMAIL CHECK] Skipped (no email or no admin token).');
      }

      final response = await _authService.signupCustomer(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: normalizedPhone, // إضافة رقم الهاتف المُطبع مباشرة
      );

      print('📥 Signup response: $response');

      final data = response['data']['customerCreate'];
      final errors = data['customerUserErrors'] as List;

      if (errors.isNotEmpty) {
        final errorMessage = errors.first['message'];
        print('❌ Signup error: $errorMessage');
        _setError(errorMessage);
        return false;
      }

      final customerId = data['customer']['id'];
      print('✅ Customer created with ID: $customerId');

      // Try to add additional customer info via metafields if admin token is available
      if (_adminAccessToken != '' && customerId != null) {
        try {
          print('📝 Adding customer metafields...');
          print('🔧 Admin token: ${_adminAccessToken.substring(0, 10)}...');
          print('👤 Customer ID: $customerId');

          final metafieldsToAdd = <Map<String, String>>[];

          // Add email as metafield
          if (email.isNotEmpty) {
            metafieldsToAdd.add({
              'namespace': 'custom',
              'key': 'email',
              'value': email,
              'type': 'single_line_text_field',
            });
            print('📧 Adding email: $email');
          }

          // Add full name as metafield
          final fullName = '$firstName $lastName'.trim();
          if (fullName.isNotEmpty) {
            metafieldsToAdd.add({
              'namespace': 'custom',
              'key': 'full_name',
              'value': fullName,
              'type': 'multi_line_text_field',
            });
            print('👤 Adding full name: $fullName');
          }

          // Add phone as metafield
          if (normalizedPhone != null && normalizedPhone.isNotEmpty) {
            metafieldsToAdd.add({
              'namespace': 'custom',
              'key': 'phone',
              'value': normalizedPhone,
              'type': 'multi_line_text_field',
            });
            print('📱 Adding phone: $normalizedPhone');
          }

          // Add original email as metafield for reference (removed unique email logic)

          // Add phone number
          if (phoneNumber != null && phoneNumber.isNotEmpty) {
            metafieldsToAdd.add({
              'namespace': 'custom',
              'key': 'phone_number',
              'value': phoneNumber,
              'type': 'multi_line_text_field',
            });
            print('📱 Adding phone: $phoneNumber');
          }

          // Add city as customer_city metafield
          if (city != null && city.isNotEmpty) {
            metafieldsToAdd.add({
              'namespace': 'custom',
              'key': 'customer_city',
              'value': city,
              'type': 'multi_line_text_field',
            });
            print('🏙️ Adding customer_city: $city');
          }

          // Add gender
          if (gender != null && gender.isNotEmpty) {
            metafieldsToAdd.add({
              'namespace': 'custom',
              'key': 'gender',
              'value': gender,
              'type': 'multi_line_text_field',
            });
            print('👤 Adding gender: $gender');
          }

          // Add age
          if (age != null) {
            metafieldsToAdd.add({
              'namespace': 'custom',
              'key': 'age',
              'value': age.toString(),
              'type': 'number_integer',
            });
            print('🎂 Adding age: $age');
          }

          // Add customer type
          metafieldsToAdd.add({
            'namespace': 'custom',
            'key': 'account_type',
            'value': 'regular_owner',
            'type': 'multi_line_text_field',
          });
          print('🏷️ Adding account type: regular_owner');

          // Add simplified type field
          metafieldsToAdd.add({
            'namespace': 'custom',
            'key': 'type',
            'value': 'regular',
            'type': 'multi_line_text_field',
          });
          print('🔖 Adding type: regular');

          print('📋 Total metafields to add: ${metafieldsToAdd.length}');

          // Update customer with metafields
          if (metafieldsToAdd.isNotEmpty) {
            final metafieldsResponse = await _adminService
                .updateCustomerMetafields(
                  customerId: customerId,
                  metafields: metafieldsToAdd,
                );
            print('📥 Metafields API response: $metafieldsResponse');

            // Check for errors
            final errors =
                metafieldsResponse['data']?['metafieldsSet']?['userErrors']
                    as List?;
            if (errors != null && errors.isNotEmpty) {
              print('❌ Metafields errors: $errors');
            } else {
              print('✅ Metafields saved successfully');
            }
          }

          print('✅ Customer metafields processing completed');
        } catch (e) {
          print('💥 Metafields error details: $e');
          // Don't fail the signup if metafields fail
        }
      } else {
        print(
          '⚠️ Skipping metafields - Admin token not configured or customer ID missing',
        );
        if (_adminAccessToken == '') {
          print('❌ Admin token is placeholder value');
        }
        if (customerId == null) {
          print('❌ Customer ID is null');
        }
      }

      print('✅ Customer created successfully, attempting auto-login...');

      // Auto-login after successful signup
      final loginSuccess = await login(email: email, password: password);

      if (loginSuccess) {
        // رقم الهاتف تم إضافته مباشرة أثناء إنشاء المستخدم
        print('✅ User created with phone number: $normalizedPhone');

        // Create address using Storefront API if city is provided
        if (city != null && city.isNotEmpty) {
          try {
            print('🏠 Creating customer address...');
            final addressResponse = await _authService.customerAddressCreate(
              accessToken: _accessToken!,
              address: {
                'address1': city, // Use city as the main address
                'city': city,
              },
            );

            final addressErrors =
                addressResponse['data']?['customerAddressCreate']?['userErrors']
                    as List? ??
                [];
            if (addressErrors.isNotEmpty) {
              print(
                '⚠️ Address creation error: ${addressErrors.first['message']}',
              );
            } else {
              print('✅ Customer address created successfully');
            }
          } catch (e) {
            print('💥 Address creation error: $e');
          }
        }
      }

      return loginSuccess;
    } catch (e) {
      print('💥 Signup exception: $e');
      _setError('auth.validation.signup_failed');
      return false;
    }
  }

  /// Garage Customer Signup with Metafields
  Future<bool> signupGarageCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String garageName,
    required String garageAddress,
    required String city,
    required String vatNumber,
    String? phoneNumber, // Add phone number parameter
    File? garagePhoto,
  }) async {
    try {
      _setAuthState(AuthState.loading);
      clearError();

      print('🏢 Starting garage customer signup for: $email');

      // ───────── فحص تكرار الهاتف (مع التطبيع) ─────────
      String? normalizedPhone;
      if (phoneNumber != null &&
          phoneNumber.isNotEmpty &&
          _adminAccessToken.isNotEmpty) {
        normalizedPhone = _normalizePhone(phoneNumber);
        print('📞 [GARAGE PHONE CHECK] Checking normalized: $normalizedPhone');
        try {
          final exists = await _adminService.isPhoneNumberUsed(normalizedPhone);
          if (exists) {
            _setError('auth.validation.phone_already_used');
            _setAuthState(AuthState.unauthenticated);
            return false;
          }
        } catch (e) {
          print('💥 garage phone exists check failed: $e');
          _setError('auth.validation.phone_check_failed');
          _setAuthState(AuthState.error);
          return false;
        }
      } else {
        print('⚠️ [GARAGE PHONE CHECK] Skipped (no phone or no admin token).');
      }

      // ───────── فحص تكرار البريد الإلكتروني للكراج ─────────
      if (email.isNotEmpty && _adminAccessToken.isNotEmpty) {
        print('📧 [GARAGE EMAIL CHECK] Checking email: $email');
        try {
          final exists = await _adminService.isEmailUsed(email);
          if (exists) {
            _setError('auth.validation.email_already_used');
            _setAuthState(AuthState.unauthenticated);
            return false;
          }
        } catch (e) {
          print('💥 garage email exists check failed: $e');
          _setError('auth.validation.email_check_failed');
          _setAuthState(AuthState.error);
          return false;
        }
      } else {
        print('⚠️ [GARAGE EMAIL CHECK] Skipped (no email or no admin token).');
      }

      // First, create the customer
      final signupResponse = await _authService.signupCustomer(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: normalizedPhone, // إضافة رقم الهاتف المُطبع مباشرة
      );

      print('📥 Garage signup response: $signupResponse');

      final signupData = signupResponse['data']['customerCreate'];
      final signupErrors = signupData['customerUserErrors'] as List;

      if (signupErrors.isNotEmpty) {
        final errorMessage = signupErrors.first['message'];
        print('❌ Garage signup error: $errorMessage');
        _setError(errorMessage);
        return false;
      }

      final customerId = signupData['customer']['id'];
      print('✅ Customer created with ID: $customerId');

      // Check if admin access token is properly configured
      if (_adminAccessToken == '') {
        print('⚠️ Admin access token not configured - skipping metafields');
        print(
          '📝 Garage info would be: $garageName, $garageAddress, $city, $vatNumber',
        );

        // Set customer type to garage even without metafields
        _customerType = CustomerType.garageCustomer;

        // Auto-login after successful signup
        final loginSuccess = await login(email: email, password: password);

        if (loginSuccess) {
          // Update customer type in storage
          await SecureStorageService.saveAuthData(
            accessToken: _accessToken!,
            customerType: CustomerType.garageCustomer.name,
            customerInfo: _customerInfo!,
            expiresAt:
                await SecureStorageService.getTokenExpiry() ??
                DateTime.now().add(const Duration(hours: 24)),
            isLogining: _rememberMe, // Use current rememberMe setting
          );
        }

        return loginSuccess;
      }

      // Upload garage photo if provided
      String? photoReference;
      if (garagePhoto != null) {
        print('📸 Uploading garage photo and creating file record...');
        print('📄 Image file path: ${garagePhoto.path}');
        print('📏 Image file size: ${await garagePhoto.length()} bytes');
        print(' Admin token available: ${_adminAccessToken.isNotEmpty}');

        photoReference = await _adminService.uploadAndCreateFile(
          file: garagePhoto,
          filename: 'garage_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: 'IMAGE',
        );
        print('📸 Photo upload and file creation result: $photoReference');

        if (photoReference == null) {
          print('❌ Failed to upload garage image - continuing without image');
        } else {
          print('✅ Image uploaded successfully with GID: $photoReference');
        }
      } else {
        print('❌ No garage photo provided');
      }

      // Validate and parse VAT number
      final vatNumberInt = int.tryParse(
        vatNumber.replaceAll(RegExp(r'[^0-9]'), ''),
      );
      final vatNumberValue = vatNumberInt?.toString() ?? '0';

      print('📝 VAT Number original: $vatNumber');
      print('📝 VAT Number parsed: $vatNumberValue');

      // Prepare metafields (location removed - will be handled via Storefront API like email/phone)
      final metafields = <Map<String, String>>[
        // Add email as metafield
        {
          'namespace': 'custom',
          'key': 'email',
          'type': 'single_line_text_field',
          'value': email,
        },
        // Add full name as metafield
        {
          'namespace': 'custom',
          'key': 'full_name',
          'type': 'multi_line_text_field',
          'value': '$firstName $lastName'.trim(),
        },
        // Add phone as metafield (normalized)
        if (normalizedPhone != null && normalizedPhone.isNotEmpty)
          {
            'namespace': 'custom',
            'key': 'phone',
            'type': 'multi_line_text_field',
            'value': normalizedPhone,
          },
        // Add customer city metafield
        {
          'namespace': 'custom',
          'key': 'customer_city',
          'type': 'multi_line_text_field',
          'value': city,
        },
        {
          'namespace': 'custom',
          'key': 'garage_name',
          'type': 'multi_line_text_field',
          'value': garageName,
        },
        {
          'namespace': 'custom',
          'key': 'garage_address',
          'type': 'multi_line_text_field',
          'value': garageAddress,
        },
        {
          'namespace': 'custom',
          'key': 'vat_number',
          'type': 'number_integer',
          'value': vatNumberValue,
        },
        {
          'namespace': 'custom',
          'key': 'account_type',
          'type': 'multi_line_text_field',
          'value': 'garage_owner_pending',
        },
        {
          'namespace': 'custom',
          'key': 'type',
          'type': 'single_line_text_field',
          'value': 'garage',
        },
      ];

      print('📧 Adding email to garage metafields: $email');
      print(
        '👤 Adding full name to garage metafields: ${firstName.trim()} ${lastName.trim()}',
      );
      if (normalizedPhone != null && normalizedPhone.isNotEmpty) {
        print(
          '📱 Adding normalized phone to garage metafields: $normalizedPhone',
        );
      }

      // Add phone number if provided
      print('📱 Phone number received: "$phoneNumber"');
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        metafields.add({
          'namespace': 'custom',
          'key': 'phone_number',
          'type': 'multi_line_text_field', // خليه multi-line لو عرّفته هيك
          'value': phoneNumber,
        });
        print('✅ Phone number added to metafields: $phoneNumber');
      } else {
        print('❌ Phone number is null or empty');
      }

      print('📸 Photo reference received: "$photoReference"');
      if (photoReference != null) {
        metafields.add({
          'namespace': 'custom',
          'key': 'garage_image',
          'type': 'file_reference',
          'value': photoReference, // لازم GID (شوف الملاحظة تحت)
        });
        print('✅ Garage image added to metafields: $photoReference');
      } else {
        print('❌ Photo reference is null');
      }

      // Update customer with metafields
      print('📝 Adding metafields to customer...');
      print('👤 Customer ID: $customerId');
      print('📋 Metafields to add: ${metafields.length}');
      for (final field in metafields) {
        print('  - ${field['namespace']}.${field['key']}: ${field['value']}');
      }

      final metafieldsResponse = await _adminService.updateCustomerMetafields(
        customerId: customerId,
        metafields: metafields,
      );

      print('� Metafields response: $metafieldsResponse');

      final metafieldsErrors =
          metafieldsResponse['data']?['metafieldsSet']?['userErrors']
              as List? ??
          [];
      if (metafieldsErrors.isNotEmpty) {
        final errorMessage = metafieldsErrors.first['message'];
        print('❌ Metafields error: $errorMessage');
        _setError('Failed to save garage information: $errorMessage');
        return false;
      } else {
        print('✅ All garage metafields saved successfully');
      }

      // Set customer type to garage
      _customerType = CustomerType.garageCustomer;

      // Auto-login after successful signup
      print('🔑 Starting auto-login after garage signup...');
      final loginSuccess = await login(email: email, password: password);

      if (loginSuccess) {
        // رقم الهاتف تم إضافته مباشرة أثناء إنشاء المستخدم
        print('✅ Garage customer created with phone number: $normalizedPhone');
      }

      if (loginSuccess) {
        // Create address using Storefront API
        try {
          print('🏠 Creating garage address...');
          final addressResponse = await _authService.customerAddressCreate(
            accessToken: _accessToken!,
            address: {
              'address1': garageAddress,
              'city': city,
              'company': garageName,
            },
          );

          final addressErrors =
              addressResponse['data']?['customerAddressCreate']?['userErrors']
                  as List? ??
              [];
          if (addressErrors.isNotEmpty) {
            print(
              '⚠️ Address creation error: ${addressErrors.first['message']}',
            );
          } else {
            print('✅ Garage address created successfully');
          }
        } catch (e) {
          print('💥 Address creation error: $e');
        }
      }

      if (loginSuccess) {
        print('✅ Auto-login successful, updating storage...');
        // Update customer type in storage
        await SecureStorageService.saveAuthData(
          accessToken: _accessToken!,
          customerType: CustomerType.garageCustomer.name,
          customerInfo: _customerInfo!,
          expiresAt:
              await SecureStorageService.getTokenExpiry() ??
              DateTime.now().add(const Duration(hours: 24)),
          isLogining: _rememberMe, // Use current rememberMe setting
        );
      } else {
        print('❌ Auto-login failed after garage signup');
      }

      print('✅ Garage customer signup completed successfully');
      return loginSuccess;
    } catch (e) {
      _setError('auth.validation.signup_failed');
      return false;
    }
  }

  /// Refresh access token
  Future<bool> _refreshToken() async {
    try {
      if (_accessToken == null) return false;

      final response = await _authService.refreshAccessToken(
        accessToken: _accessToken!,
      );

      final data = response['data']['customerAccessTokenRenew'];
      final errors = data['customerUserErrors'] as List;

      if (errors.isNotEmpty) {
        await logout();
        return false;
      }

      final tokenData = data['customerAccessToken'];
      _accessToken = tokenData['accessToken'];
      final expiresAt = DateTime.parse(tokenData['expiresAt']);

      // Update storage
      await SecureStorageService.saveAuthData(
        accessToken: _accessToken!,
        customerType: _customerType?.name ?? 'customer',
        customerInfo: _customerInfo ?? {},
        expiresAt: expiresAt,
        isLogining:
            await SecureStorageService.getIsLogining(), // Preserve isLogining flag
      );

      _setAuthState(AuthState.authenticated);
      return true;
    } catch (e) {
      await logout();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      print('🚪 Starting logout process...');

      // Logout from Shopify if we have a token
      if (_accessToken != null) {
        try {
          print('📤 Logging out from Shopify...');
          await _authService.logoutCustomer(accessToken: _accessToken!);
          print('✅ Shopify logout successful');
        } catch (e) {
          // Continue with logout even if Shopify logout fails
          print('⚠️ Shopify logout error: $e');
        }
      }
    } catch (e) {
      print('💥 Logout error: $e');
    }

    // Always clear local data, even if remote logout fails
    try {
      print('🧹 Clearing all local storage data...');

      // Clear secure storage (access token, customer info, etc.)
      await SecureStorageService.clearAuthData();
      print('✅ Secure storage cleared');

      // Clear Hive settings (remember me, last login email, etc.)
      await HiveStorageService.clearSettings();
      print('✅ Hive settings cleared');

      // Reset all state variables
      _accessToken = null;
      _customerType = null;
      _customerInfo = null;
      _errorMessage = null;
      _rememberMe = false;

      print('✅ All local data cleared - logout complete');
      _setAuthState(AuthState.unauthenticated);
    } catch (e) {
      print('💥 Error clearing local data: $e');
      // Even if clearing fails, set state to unauthenticated
      _setAuthState(AuthState.unauthenticated);
      rethrow; // Re-throw so UI can handle the error
    }
  }

  /// Send Password Reset Email
  Future<bool> sendPasswordReset(String email) async {
    try {
      // Don't change auth state - keep user logged in
      clearError();

      print('📧 Sending password reset for: $email');

      final response = await _authService.customerRecover(email: email.trim());
      final errors =
          response['data']?['customerRecover']?['customerUserErrors']
              as List? ??
          [];

      if (errors.isNotEmpty) {
        // Handle Shopify error messages: "Customer not found", etc.
        final errorMessage = errors.first['message'] ?? 'reset_failed';
        print('❌ Password reset error: $errorMessage');
        _setError(
          errorMessage.contains('not found')
              ? 'customer_not_found'
              : 'reset_failed',
        );
        return false;
      }

      print('✅ Password reset email sent successfully');
      return true;
    } catch (e) {
      print('❌ Error sending password reset: $e');
      _setError('reset_failed');
      return false;
    }
  }

  /// Reset Password using URL from email
  Future<bool> resetPasswordByUrl({
    required String resetUrl,
    required String newPassword,
  }) async {
    try {
      _setAuthState(AuthState.loading);
      clearError();

      print('🔑 Resetting password with URL: ${resetUrl.substring(0, 50)}...');

      final response = await _authService.customerResetByUrl(
        resetUrl: resetUrl,
        newPassword: newPassword,
      );

      final errors =
          response['data']?['customerResetByUrl']?['customerUserErrors']
              as List? ??
          [];

      _setAuthState(AuthState.unauthenticated);

      if (errors.isNotEmpty) {
        final errorMessage = errors.first['message'] ?? 'reset_failed';
        print('❌ Password reset by URL error: $errorMessage');
        _setError(
          errorMessage.contains('expired')
              ? 'reset_link_expired'
              : 'reset_failed',
        );
        return false;
      }

      final customer = response['data']?['customerResetByUrl']?['customer'];
      if (customer == null) {
        print('❌ No customer data in reset response');
        _setError('reset_failed');
        return false;
      }

      print('✅ Password reset successful for customer: ${customer['id']}');
      return true;
    } catch (e) {
      print('💥 Password reset by URL exception: $e');
      _setError('network_error');
      _setAuthState(AuthState.unauthenticated);
      return false;
    }
  }

  /// Pick image from gallery or camera
  Future<File?> pickImage({required ImageSource source}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      _setError('Failed to pick image: $e');
      return null;
    }
  }

  /// Get last login email from settings
  String? getLastLoginEmail() {
    final settings = HiveStorageService.getSettings();
    return settings.lastLoginEmail;
  }

  /// Get customer metafields (garage owner specific data)
  Future<Map<String, dynamic>?> getCustomerMetafields() async {
    if (!isAuthenticated || _customerInfo == null) {
      print('❌ Not authenticated or no customer info available');
      return null;
    }

    try {
      final customerId = _customerInfo!['id'];
      if (customerId == null) {
        print('❌ No customer ID available');
        return null;
      }

      print('🔍 Getting metafields for customer: $customerId');

      // Check if admin service is available
      if (_adminAccessToken.isEmpty) {
        print('❌ Admin access token not available');
        return _createFallbackMetafields();
      }

      // First try GraphQL API (metafields only, no PII)
      var result = await _adminService.getCustomerMetafields(customerId);

      // If GraphQL fails, try REST API as fallback
      if (result == null) {
        print('🔄 GraphQL failed, trying REST API...');
        result = await _adminService.getCustomerMetafieldsRest(customerId);
      }

      if (result != null) {
        print('✅ Customer metafields retrieved successfully');
        return result;
      } else {
        print('❌ Both GraphQL and REST APIs failed - using fallback data');
        return _createFallbackMetafields();
      }
    } catch (e) {
      print('💥 Error getting customer metafields: $e');

      // Check if it's a permissions error
      final errorString = e.toString();
      if (errorString.contains('ACCESS_DENIED') ||
          errorString.contains('not approved to access') ||
          errorString.contains('PII')) {
        print('🔒 Access denied to customer data - using fallback metafields');
        return _createFallbackMetafields();
      }

      return null;
    }
  }

  /// Create fallback metafields when Shopify access is limited
  Map<String, dynamic> _createFallbackMetafields() {
    // Check if user is garage owner from stored customer type
    final isGarage = _customerType == CustomerType.garageCustomer;

    print(
      '🔄 Creating fallback metafields for ${isGarage ? 'garage owner' : 'regular customer'}',
    );

    // Create basic metafields structure
    final metafields = <Map<String, dynamic>>[];

    // Add basic customer info from stored data
    final customerInfo = _customerInfo ?? {};

    if (customerInfo['email'] != null) {
      metafields.add({
        'key': 'email',
        'value': customerInfo['email'],
        'namespace': 'custom',
      });
    }

    final firstName = customerInfo['firstName'] ?? '';
    final lastName = customerInfo['lastName'] ?? '';
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      metafields.add({
        'key': 'full_name',
        'value': '$firstName $lastName'.trim(),
        'namespace': 'custom',
      });
    }

    if (customerInfo['phone'] != null) {
      metafields.add({
        'key': 'phone',
        'value': customerInfo['phone'],
        'namespace': 'custom',
      });
    }

    // Add customer_city metafield (with placeholder if not available)
    metafields.add({
      'key': 'customer_city',
      'value': customerInfo['city'] ?? '', // Empty string if not available
      'namespace': 'custom',
    });

    // Add garage-specific metafields if it's a garage customer
    if (isGarage) {
      metafields.addAll([
        {
          'key': 'account_type',
          'value': 'garage_owner_pending',
          'namespace': 'custom',
        },
        {
          'key': 'garage_name',
          'value': 'Sample Garage', // Placeholder
          'namespace': 'custom',
        },
        {
          'key': 'garage_address',
          'value': 'Sample Address', // Placeholder
          'namespace': 'custom',
        },
        {'key': 'vat_number', 'value': '0', 'namespace': 'custom'},
        {
          'key': 'garage_image',
          'value': '', // Empty string indicates no image available
          'namespace': 'custom',
          'type': 'file_reference',
        },
      ]);
    }

    // Return in Shopify GraphQL format
    return {
      'metafields': {
        'edges': metafields.map((field) => {'node': field}).toList(),
      },
    };
  }

  /// Check if customer is garage owner based on metafields
  bool isGarageOwner() {
    final result = _customerType == CustomerType.garageCustomer;
    print(
      '🔍 DEBUG: isGarageOwner() - customerType: $_customerType, result: $result',
    );
    return result;
  }

  bool isGaragePending() {
    final result = _customerType == CustomerType.garagePending;
    print(
      '🔍 DEBUG: isGaragePending() - customerType: $_customerType, result: $result',
    );
    return result;
  }

  bool isGarageRejected() {
    final result = _customerType == CustomerType.garageRejected;
    print(
      '🔍 DEBUG: isGarageRejected() - customerType: $_customerType, result: $result',
    );
    return result;
  }

  bool isAnyGarageType() {
    return _customerType == CustomerType.garageCustomer ||
        _customerType == CustomerType.garagePending ||
        _customerType == CustomerType.garageRejected;
  }

  String getGarageStatus() {
    switch (_customerType) {
      case CustomerType.garageCustomer:
        return 'garage_owner_accepted';
      case CustomerType.garagePending:
        return 'garage_owner_pending';
      case CustomerType.garageRejected:
        return 'garage_owner_rejected';
      default:
        return 'customer';
    }
  }

  bool canEditGarageInfo() {
    // Can edit if pending or rejected, cannot edit if accepted
    final result =
        _customerType == CustomerType.garagePending ||
        _customerType == CustomerType.garageRejected;
    print(
      '🔍 DEBUG: canEditGarageInfo() - customerType: $_customerType, result: $result',
    );
    return result;
  }

  /// Check if customer has garage metafields (async version)
  Future<bool> hasGarageMetafields() async {
    try {
      final metafields = await getCustomerMetafields();

      if (metafields == null) {
        print('ℹ️ No metafields available - checking stored customer type');
        // If we can't access metafields, check stored customer type
        return _customerType == CustomerType.garageCustomer;
      }

      final metafieldsList = metafields['metafields']?['edges'] ?? [];

      for (final edge in metafieldsList) {
        final metafield = edge['node'];
        final key = metafield['key'];

        // Check for garage-specific metafields
        if ([
          'garage_name',
          'garage_address',
          'vat_number',
          'account_type',
        ].contains(key)) {
          // Check if account_type indicates garage owner
          if (key == 'account_type') {
            final value = metafield['value']?.toString() ?? '';
            if (value.contains('garage_owner') || value.contains('garage')) {
              print('✅ Found garage account_type metafield: $value');
              return true;
            }
          } else {
            // If any other garage field exists, consider as garage owner
            print('✅ Found garage metafield: $key');
            return true;
          }
        }
      }

      print('❌ No garage metafields found');
      return false;
    } catch (e) {
      print('❌ Error checking garage metafields: $e');
      // Fallback to stored customer type if error occurs
      return _customerType == CustomerType.garageCustomer;
    }
  }

  /// Refresh customer info from Shopify (to get latest tags and metafields)
  Future<void> refreshCustomerInfo() async {
    if (!isAuthenticated || _accessToken == null || _customerInfo == null) {
      print(
        '❌ Cannot refresh customer info: not authenticated or no customer info',
      );
      return;
    }

    try {
      print('🔄 Refreshing customer info from Shopify Admin API...');

      // Extract customer ID from current customer info
      final customerId = _customerInfo!['id'];
      if (customerId == null) {
        print('❌ No customer ID found in current customer info');
        return;
      }

      print('🆔 Using customer ID: $customerId');

      // Get fresh customer info with tags from Admin API
      final customerResponse = await _adminService.getCustomerInfoWithTags(
        customerId: customerId,
      );

      print('📥 Fresh customer info response: $customerResponse');

      final newCustomerInfo = customerResponse['data']['customer'];

      if (newCustomerInfo != null) {
        _customerInfo = newCustomerInfo;
        print('✅ Customer info updated with tags: ${newCustomerInfo['tags']}');

        // Update stored data with fresh info
        await SecureStorageService.saveAuthData(
          accessToken: _accessToken!,
          customerType: _customerType!.name,
          customerInfo: _customerInfo!,
          expiresAt:
              await SecureStorageService.getTokenExpiry() ??
              DateTime.now().add(const Duration(hours: 24)),
          isLogining: _rememberMe,
        );

        print('✅ Customer info refreshed successfully');

        // Now update customer type based on fresh data
        await updateCustomerTypeFromMetafields();
      } else {
        print('❌ Failed to get fresh customer info');
      }
    } catch (e) {
      print('❌ Error refreshing customer info: $e');
    }
  }

  /// Update customer type based on metafields (for runtime updates)
  Future<void> updateCustomerTypeFromMetafields() async {
    if (!isAuthenticated || _customerInfo == null) {
      return;
    }

    try {
      print('🔄 Updating customer type from metafields...');
      print('🔍 Full customer info: $_customerInfo');

      // Check tags for garage status
      final tags = _customerInfo!['tags']?.toString() ?? '';
      print('🏷️ Customer tags: "$tags"');

      // Determine customer type based on tags
      CustomerType newCustomerType;

      // TEMPORARY FIX: Force correct status since Admin API tags aren't working yet
      // TODO: Remove this when Admin API integration is working
      final hasGarageMeta = await hasGarageMetafields();
      if (hasGarageMeta && tags.isEmpty) {
        print(
          '🔧 TEMPORARY FIX: Customer has garage metafields but no tags in current data',
        );
        print(
          '🔧 TEMPORARY FIX: Based on Shopify Admin setting, forcing to ACCEPTED status',
        );
        newCustomerType = CustomerType.garageCustomer;
        print(
          '✅ TEMPORARY: Set customer type to accepted garage owner (garageCustomer)',
        );
      } else if (tags.contains('garage_owner_accepted')) {
        newCustomerType = CustomerType.garageCustomer;
        print(
          '✅ Customer is accepted garage owner (garageCustomer) - found tag: garage_owner_accepted',
        );
      } else if (tags.contains('garage_owner_pending')) {
        newCustomerType = CustomerType.garagePending;
        print(
          '⏳ Customer is pending garage owner (garagePending) - found tag: garage_owner_pending',
        );
      } else if (tags.contains('garage_owner_rejected')) {
        newCustomerType = CustomerType.garageRejected;
        print(
          '❌ Customer is rejected garage owner (garageRejected) - found tag: garage_owner_rejected',
        );
      } else {
        // Check metafields as fallback
        print(
          '🔍 No garage status tags found, checking metafields as fallback...',
        );
        final hasGarageMeta = await hasGarageMetafields();
        print('🔍 Has garage metafields (fallback): $hasGarageMeta');

        if (hasGarageMeta) {
          // TODO: For now, default to pending if no status tag but has garage metafields
          // In production, all garage owners should have proper status tags
          newCustomerType = CustomerType.garagePending;
          print(
            '⚠️ WARNING: Customer has garage metafields but no status tag. Defaulting to PENDING status.',
          );
          print(
            '⚠️ In Shopify Admin, please add one of these tags: garage_owner_pending, garage_owner_accepted, garage_owner_rejected',
          );
        } else {
          newCustomerType = CustomerType.customer;
          print('👤 Customer is regular customer (no garage metafields)');
        }
      }

      if (_customerType != newCustomerType) {
        _customerType = newCustomerType;
        print('� Updated customer type to: ${_customerType!.name}');

        // Update stored data
        await SecureStorageService.saveAuthData(
          accessToken: _accessToken!,
          customerType: _customerType!.name,
          customerInfo: _customerInfo!,
          expiresAt:
              await SecureStorageService.getTokenExpiry() ??
              DateTime.now().add(const Duration(hours: 24)),
          isLogining: _rememberMe,
        );

        notifyListeners();
      }
    } catch (e) {
      print('❌ Error updating customer type: $e');
    }
  }

  /// Update customer profile information (only metafields due to PII restrictions)
  Future<bool> updateCustomerProfile({
    String? firstName,
    String? lastName,
    String? city,
    String? garageName,
    String? garageAddress,
    String? vatNumber,
  }) async {
    try {
      if (_customerInfo == null) {
        print('❌ No customer info available for update');
        return false;
      }

      final customerId = _customerInfo!['id'] as String?;
      if (customerId == null) {
        print('❌ No customer ID available for update');
        return false;
      }

      print('🔄 Updating customer profile (metafields only)...');

      // Prepare metafields for all profile data (including names due to PII restrictions)
      final metafields = <String, String>{};

      // Combine first name and last name into a single full_name field
      if ((firstName != null && firstName.isNotEmpty) ||
          (lastName != null && lastName.isNotEmpty)) {
        final fullName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
        if (fullName.isNotEmpty) {
          metafields['full_name'] = fullName;
        }
      }

      if (city != null && city.isNotEmpty) metafields['city'] = city;
      if (garageName != null && garageName.isNotEmpty)
        metafields['garage_name'] = garageName;
      if (garageAddress != null && garageAddress.isNotEmpty)
        metafields['garage_address'] = garageAddress;
      if (vatNumber != null && vatNumber.isNotEmpty)
        metafields['vat_number'] = vatNumber;

      if (metafields.isEmpty) {
        print('⚠️ No data to update');
        return true; // Nothing to update is still successful
      }

      // Get existing metafield types from current customer info
      final existingMetafields =
          _customerInfo!['metafields'] as Map<String, dynamic>? ?? {};
      print('🔍 Existing metafields structure: $existingMetafields');

      // Convert metafields to the required format for Admin API
      final metafieldsList = metafields.entries
          .map(
            (entry) => {
              'namespace': 'custom',
              'key': entry.key,
              'type': _getExistingMetafieldType(entry.key, existingMetafields),
              'value': entry.value,
            },
          )
          .toList();

      print('🔧 Prepared metafields for update: $metafieldsList');

      // Update metafields using Admin GraphQL API
      final response = await _adminService.updateCustomerMetafields(
        customerId: customerId,
        metafields: metafieldsList.cast<Map<String, String>>(),
      );

      print('📥 Profile update response: $response');

      // Check for errors in the response
      final userErrors =
          response['data']?['metafieldsSet']?['userErrors'] as List? ?? [];
      if (userErrors.isNotEmpty) {
        final errorMessage = userErrors.first['message'] ?? 'Unknown error';
        print('❌ Profile update error: $errorMessage');
        _setError('Failed to update profile: $errorMessage');
        return false;
      }

      // Check if metafields were actually updated
      final updatedMetafields =
          response['data']?['metafieldsSet']?['metafields'] as List? ?? [];
      if (updatedMetafields.isEmpty) {
        print('❌ No metafields were updated');
        _setError('Failed to update profile data');
        return false;
      }

      print(
        '✅ Profile metafields updated successfully: ${updatedMetafields.length} fields',
      );

      // Update local customer info with combined full name
      final updatedCustomerInfo = <String, dynamic>{..._customerInfo!};

      // Update full name if either firstName or lastName changed
      if (firstName != null || lastName != null) {
        final fullName = '${firstName ?? ''} ${lastName ?? ''}'.trim();
        if (fullName.isNotEmpty) {
          // Store both individual names and combined name for compatibility
          updatedCustomerInfo['firstName'] = firstName ?? '';
          updatedCustomerInfo['lastName'] = lastName ?? '';
          updatedCustomerInfo['displayName'] = fullName;
        }
      }

      _customerInfo = updatedCustomerInfo;
      // Note: email and phone are intentionally not updated

      // Update metafields in local storage if they were updated
      if (metafields.isNotEmpty) {
        final existingMetafields =
            _customerInfo!['metafields'] as Map<String, dynamic>? ?? {};
        _customerInfo!['metafields'] = {...existingMetafields, ...metafields};
      }

      // Save updated info to secure storage
      await SecureStorageService.saveAuthData(
        accessToken: _accessToken!,
        customerType: _customerType!.name,
        customerInfo: _customerInfo!,
        expiresAt:
            await SecureStorageService.getTokenExpiry() ??
            DateTime.now().add(const Duration(hours: 24)),
        isLogining: _rememberMe,
      );

      notifyListeners();
      print('✅ Customer profile updated successfully via metafields');
      return true;
    } catch (e) {
      print('❌ Error updating customer profile: $e');
      _setError('Failed to update profile');
      return false;
    }
  }

  /// Get the metafield type from existing metafields or use a fallback
  String _getExistingMetafieldType(
    String key,
    Map<String, dynamic> existingMetafields,
  ) {
    // First, try to get the type from existing metafields structure
    if (existingMetafields.containsKey('metafields')) {
      final metafieldsData = existingMetafields['metafields'];
      if (metafieldsData is Map && metafieldsData.containsKey('edges')) {
        final edges = metafieldsData['edges'] as List? ?? [];
        for (final edge in edges) {
          final node = edge['node'];
          if (node['key'] == key) {
            final type = node['type'];
            print('🔍 Found existing type for $key: $type');
            return type;
          }
        }
      }
    }

    // Fallback to predefined types based on your log data
    switch (key) {
      case 'email':
        return 'single_line_text_field';
      case 'full_name':
      case 'phone':
      case 'garage_name':
      case 'garage_address':
        return 'multi_line_text_field';
      case 'vat_number':
        return 'number_integer';
      case 'first_name':
      case 'last_name':
      case 'city':
        return 'single_line_text_field';
      default:
        print(
          '⚠️ Unknown metafield type for $key, using single_line_text_field',
        );
        return 'single_line_text_field';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
