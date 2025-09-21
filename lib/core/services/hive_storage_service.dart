import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_settings.dart';
import '../models/cart_item.dart';

class HiveStorageService {
  static const String _settingsBoxName = 'app_settings';
  static const String _settingsKey = 'user_settings';

  static Box<AppSettings>? _settingsBox;

  /// Initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CartItemAdapter());
    }

    // Open boxes
    _settingsBox = await Hive.openBox<AppSettings>(_settingsBoxName);
  }

  /// Get settings box
  static Box<AppSettings> get settingsBox {
    if (_settingsBox == null || !_settingsBox!.isOpen) {
      throw Exception(
        'Settings box is not initialized. Call HiveStorageService.init() first.',
      );
    }
    return _settingsBox!;
  }

  /// Save app settings
  static Future<void> saveSettings(AppSettings settings) async {
    await settingsBox.put(_settingsKey, settings);
  }

  /// Get app settings
  static AppSettings getSettings() {
    return settingsBox.get(_settingsKey) ?? AppSettings();
  }

  /// Update specific setting
  static Future<void> updateSetting({
    bool? isDarkMode,
    String? language,
    bool? notificationsEnabled,
    bool? rememberMe,
    String? lastLoginEmail,
  }) async {
    final currentSettings = getSettings();
    final updatedSettings = currentSettings.copyWith(
      isDarkMode: isDarkMode,
      language: language,
      notificationsEnabled: notificationsEnabled,
      rememberMe: rememberMe,
      lastLoginEmail: lastLoginEmail,
    );
    await saveSettings(updatedSettings);
  }

  /// Clear all settings
  static Future<void> clearSettings() async {
    await settingsBox.clear();
  }

  /// Close all boxes
  static Future<void> close() async {
    await _settingsBox?.close();
  }
}
