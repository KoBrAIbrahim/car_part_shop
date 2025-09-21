import 'package:flutter/material.dart';
import '../widgets/top_notification.dart';

class PhoneValidationUtils {
  /// Validates phone number format and shows top notification for errors
  /// Returns true if valid, false if invalid
  static bool validatePhoneAndShowNotification(
    BuildContext context, {
    required String phone,
    required String countryCode,
    bool showNotification = true,
  }) {
    // Remove any formatting characters
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-()]'), '');

    // Check if phone is empty
    if (cleanPhone.isEmpty) {
      if (showNotification) {
        TopNotification.show(
          context,
          message: 'auth.validation.required_field',
          type: NotificationType.error,
          duration: const Duration(seconds: 4),
        );
      }
      return false;
    }

    // Check minimum length (usually 7-15 digits for international phone numbers)
    if (cleanPhone.length < 7) {
      if (showNotification) {
        TopNotification.show(
          context,
          message: 'auth.validation.invalid_phone_format',
          type: NotificationType.error,
          duration: const Duration(seconds: 4),
        );
      }
      return false;
    }

    // Check maximum length
    if (cleanPhone.length > 15) {
      if (showNotification) {
        TopNotification.show(
          context,
          message: 'auth.validation.invalid_phone_format',
          type: NotificationType.error,
          duration: const Duration(seconds: 4),
        );
      }
      return false;
    }

    // Check if phone contains only digits
    if (!RegExp(r'^\d+$').hasMatch(cleanPhone)) {
      if (showNotification) {
        TopNotification.show(
          context,
          message: 'auth.validation.invalid_phone_format',
          type: NotificationType.error,
          duration: const Duration(seconds: 4),
        );
      }
      return false;
    }

    // Country-specific validation for common country codes
    if (countryCode == '+972') {
      // Israel phone number validation
      if (cleanPhone.length < 9 || cleanPhone.length > 10) {
        if (showNotification) {
          TopNotification.show(
            context,
            message: 'auth.validation.invalid_phone_format',
            type: NotificationType.error,
            duration: const Duration(seconds: 4),
          );
        }
        return false;
      }

      // Israeli mobile numbers usually start with 5
      if (cleanPhone.length == 9 && !cleanPhone.startsWith('5')) {
        if (showNotification) {
          TopNotification.show(
            context,
            message: 'auth.validation.invalid_phone_format',
            type: NotificationType.error,
            duration: const Duration(seconds: 4),
          );
        }
        return false;
      }
    } else if (countryCode == '+1') {
      // US/Canada phone number validation
      if (cleanPhone.length != 10) {
        if (showNotification) {
          TopNotification.show(
            context,
            message: 'auth.validation.invalid_phone_format',
            type: NotificationType.error,
            duration: const Duration(seconds: 4),
          );
        }
        return false;
      }
    } else if (countryCode == '+44') {
      // UK phone number validation
      if (cleanPhone.length < 10 || cleanPhone.length > 11) {
        if (showNotification) {
          TopNotification.show(
            context,
            message: 'auth.validation.invalid_phone_format',
            type: NotificationType.error,
            duration: const Duration(seconds: 4),
          );
        }
        return false;
      }
    }

    return true;
  }

  /// Formats phone number for display
  static String formatPhoneNumber(String phone, String countryCode) {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-()]'), '');

    if (countryCode == '+972' && cleanPhone.length >= 9) {
      // Format Israeli phone number: 05X-XXX-XXXX
      if (cleanPhone.length == 9) {
        return '${cleanPhone.substring(0, 3)}-${cleanPhone.substring(3, 6)}-${cleanPhone.substring(6)}';
      } else if (cleanPhone.length == 10) {
        return '${cleanPhone.substring(0, 3)}-${cleanPhone.substring(3, 6)}-${cleanPhone.substring(6)}';
      }
    } else if (countryCode == '+1' && cleanPhone.length == 10) {
      // Format US phone number: (XXX) XXX-XXXX
      return '(${cleanPhone.substring(0, 3)}) ${cleanPhone.substring(3, 6)}-${cleanPhone.substring(6)}';
    }

    return cleanPhone;
  }

  /// Normalizes phone number for storage/API calls
  static String normalizePhone(
    String phone, {
    String defaultCountryCode = '+972',
  }) {
    var s = phone.trim();
    if (s.startsWith('00')) s = '+${s.substring(2)}';
    s = s.replaceAll(RegExp(r'[\s\-()]'), '');
    if (!s.startsWith('+')) s = '$defaultCountryCode$s';
    return s;
  }
}
