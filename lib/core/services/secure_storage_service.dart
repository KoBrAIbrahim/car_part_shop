import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Keys for storing data
  static const String _accessTokenKey = 'shopify_access_token';
  static const String _customerTypeKey = 'customer_type';
  static const String _customerInfoKey = 'customer_info';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _isLoginingKey =
      'is_logining'; // Track if user wants to stay logged in
  static const String _emailMappingPrefix =
      'email_mapping_'; // For original->unique email mapping

  /// Save access token and customer data
  static Future<void> saveAuthData({
    required String accessToken,
    required String customerType, // 'customer' or 'garageCustomer'
    required Map<String, dynamic> customerInfo,
    required DateTime expiresAt,
    bool isLogining = false, // Whether user wants to stay logged in
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _customerTypeKey, value: customerType),
      _storage.write(key: _customerInfoKey, value: jsonEncode(customerInfo)),
      _storage.write(key: _tokenExpiryKey, value: expiresAt.toIso8601String()),
      _storage.write(key: _isLoginingKey, value: isLogining.toString()),
    ]);
  }

  /// Save access token only
  static Future<void> saveAccessToken(String accessToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
  }

  /// Save token expiry only
  static Future<void> saveTokenExpiry(DateTime expiresAt) async {
    await _storage.write(
      key: _tokenExpiryKey,
      value: expiresAt.toIso8601String(),
    );
  }

  /// Get access token
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// Get customer type
  static Future<String?> getCustomerType() async {
    return await _storage.read(key: _customerTypeKey);
  }

  /// Get customer info
  static Future<Map<String, dynamic>?> getCustomerInfo() async {
    final customerInfoJson = await _storage.read(key: _customerInfoKey);
    if (customerInfoJson != null) {
      return jsonDecode(customerInfoJson);
    }
    return null;
  }

  /// Get token expiry date
  static Future<DateTime?> getTokenExpiry() async {
    final expiryString = await _storage.read(key: _tokenExpiryKey);
    if (expiryString != null) {
      return DateTime.parse(expiryString);
    }
    return null;
  }

  /// Check if token is expired
  static Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;
    return DateTime.now().isAfter(
      expiry.subtract(const Duration(minutes: 5)),
    ); // 5 min buffer
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token == null) return false;
    return !(await isTokenExpired());
  }

  /// Get isLogining flag (whether user wants to stay logged in)
  static Future<bool> getIsLogining() async {
    final isLoginingString = await _storage.read(key: _isLoginingKey);
    return isLoginingString == 'true';
  }

  /// Save isLogining flag
  static Future<void> saveIsLogining(bool isLogining) async {
    await _storage.write(key: _isLoginingKey, value: isLogining.toString());
  }

  /// Clear all auth data (logout)
  static Future<void> clearAuthData() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _customerTypeKey),
      _storage.delete(key: _customerInfoKey),
      _storage.delete(key: _tokenExpiryKey),
      _storage.delete(key: _isLoginingKey),
      // Note: We keep email mappings for future logins
    ]);
  }

  /// Clear all storage
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Save email mapping (original email -> unique email for Shopify)
  static Future<void> saveEmailMapping(
    String originalEmail,
    String uniqueEmail,
  ) async {
    final key = _emailMappingPrefix + originalEmail.toLowerCase();
    await _storage.write(key: key, value: uniqueEmail);
  }

  /// Get unique email from original email
  static Future<String?> getUniqueEmail(String originalEmail) async {
    final key = _emailMappingPrefix + originalEmail.toLowerCase();
    return await _storage.read(key: key);
  }

  /// Clear email mapping
  static Future<void> clearEmailMapping(String originalEmail) async {
    final key = _emailMappingPrefix + originalEmail.toLowerCase();
    await _storage.delete(key: key);
  }
}
