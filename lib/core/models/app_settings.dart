import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 0)
class AppSettings extends HiveObject {
  @HiveField(0)
  bool isDarkMode;

  @HiveField(1)
  String language;

  @HiveField(2)
  bool notificationsEnabled;

  @HiveField(3)
  bool rememberMe;

  @HiveField(4)
  String? lastLoginEmail;

  AppSettings({
    this.isDarkMode = false,
    this.language = 'en',
    this.notificationsEnabled = true,
    this.rememberMe = false,
    this.lastLoginEmail,
  });

  AppSettings copyWith({
    bool? isDarkMode,
    String? language,
    bool? notificationsEnabled,
    bool? rememberMe,
    String? lastLoginEmail,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      rememberMe: rememberMe ?? this.rememberMe,
      lastLoginEmail: lastLoginEmail ?? this.lastLoginEmail,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isDarkMode': isDarkMode,
      'language': language,
      'notificationsEnabled': notificationsEnabled,
      'rememberMe': rememberMe,
      'lastLoginEmail': lastLoginEmail,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      isDarkMode: json['isDarkMode'] ?? false,
      language: json['language'] ?? 'en',
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      rememberMe: json['rememberMe'] ?? false,
      lastLoginEmail: json['lastLoginEmail'],
    );
  }
}
