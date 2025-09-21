import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: AppColors.getBackground(isDark),
          appBar: AppBar(
            backgroundColor: AppColors.getBackground(isDark),
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: AppColors.getTextColor(isDark),
              ),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'help.title'.tr(),
              style: TextStyle(
                color: AppColors.getTextColor(isDark),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Help Header
                _buildHelpHeader(isDark),

                const SizedBox(height: 24),

                // Getting Started Section
                _buildGettingStartedSection(isDark),

                const SizedBox(height: 24),

                // Profile Management Section
                _buildProfileManagementSection(context, isDark),

                const SizedBox(height: 24),

                // App Settings Section
                _buildAppSettingsSection(context, isDark),

                const SizedBox(height: 24),

                // Account Security Section
                _buildAccountSecuritySection(isDark),

                const SizedBox(height: 24),

                // Troubleshooting Section
                _buildTroubleshootingSection(isDark),

                const SizedBox(height: 24),

                // FAQ Section
                _buildFAQSection(isDark),

                const SizedBox(height: 24),

                // Tips & Best Practices
                _buildTipsSection(isDark),

                const SizedBox(height: 24),

                // Contact Support Section
                _buildContactSupportSection(isDark),

                const SizedBox(height: 24),

                // Developer Section
                _buildDeveloperSection(context, isDark),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelpHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getTextColor(isDark).withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.help_center_rounded, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'help.title'.tr(),
            style: TextStyle(
              color: AppColors.getTextColor(isDark),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'help.subtitle'.tr(),
            style: TextStyle(
              color: AppColors.getTextColor(isDark).withOpacity(0.8),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGettingStartedSection(bool isDark) {
    final topics = [
      'Setting up your account',
      'Navigating the interface',
      'Understanding app features',
    ];

    return _buildSection(
      title: 'help.getting_started.title'.tr(),
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'help.getting_started.description'.tr(),
            style: TextStyle(
              color: AppColors.getTextColor(isDark).withOpacity(0.8),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...topics.map((topic) => _buildBulletPoint(topic, isDark)),
        ],
      ),
    );
  }

  Widget _buildProfileManagementSection(BuildContext context, bool isDark) {
    return _buildSection(
      title: 'help.profile_management.title'.tr(),
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'help.profile_management.description'.tr(),
            style: TextStyle(
              color: AppColors.getTextColor(isDark).withOpacity(0.8),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Edit Profile
          _buildHelpItem(
            title: 'help.profile_management.edit_profile.title'.tr(),
            icon: Icons.edit_rounded,
            isDark: isDark,
            onTap: () {
              final steps = [
                'Go to Settings from the bottom navigation',
                'Tap on \'Profile\' at the top',
                'Edit your personal information',
                'Tap \'Save Changes\' to update',
              ];
              _showStepsDialog(
                context,
                'help.profile_management.edit_profile.title'.tr(),
                steps,
                isDark,
              );
            },
          ),

          const SizedBox(height: 12),

          // Change Password
          _buildHelpItem(
            title: 'help.profile_management.change_password.title'.tr(),
            icon: Icons.lock_reset_rounded,
            isDark: isDark,
            onTap: () {
              final steps = [
                'Navigate to Settings → Profile',
                'Scroll down to find \'Reset Password\' button',
                'Tap the \'Reset Password\' button',
                'Check your email for reset instructions',
                'Follow the link in the email to set a new password',
              ];
              _showStepsDialog(
                context,
                'help.profile_management.change_password.title'.tr(),
                steps,
                isDark,
              );
            },
          ),

          const SizedBox(height: 12),

          // Update Contact
          _buildHelpItem(
            title: 'help.profile_management.update_contact.title'.tr(),
            icon: Icons.contact_phone_rounded,
            isDark: isDark,
            onTap: () {
              final steps = [
                'Go to Settings → Profile',
                'Edit your phone number or email',
                'Verify the changes if required',
                'Save your updates',
              ];
              _showStepsDialog(
                context,
                'help.profile_management.update_contact.title'.tr(),
                steps,
                isDark,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsSection(BuildContext context, bool isDark) {
    return _buildSection(
      title: 'help.app_settings.title'.tr(),
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'help.app_settings.description'.tr(),
            style: TextStyle(
              color: AppColors.getTextColor(isDark).withOpacity(0.8),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Change Language
          _buildHelpItem(
            title: 'help.app_settings.language.title'.tr(),
            icon: Icons.language_rounded,
            isDark: isDark,
            onTap: () {
              final steps = [
                'Open Settings from bottom navigation',
                'Find \'Language\' option',
                'Select from available languages: English, Arabic, Hebrew',
                'App will restart with new language',
              ];
              _showStepsDialog(
                context,
                'help.app_settings.language.title'.tr(),
                steps,
                isDark,
              );
            },
          ),

          const SizedBox(height: 12),

          // Change Theme
          _buildHelpItem(
            title: 'help.app_settings.theme.title'.tr(),
            icon: Icons.dark_mode_rounded,
            isDark: isDark,
            onTap: () {
              final steps = [
                'Go to Settings page',
                'Find the \'Theme\' toggle switch',
                'Toggle between Dark and Light mode',
                'Changes apply immediately',
              ];
              _showStepsDialog(
                context,
                'help.app_settings.theme.title'.tr(),
                steps,
                isDark,
              );
            },
          ),

          const SizedBox(height: 12),

          // Notifications
          _buildHelpItem(
            title: 'help.app_settings.notifications.title'.tr(),
            icon: Icons.notifications_rounded,
            isDark: isDark,
            onTap: () {
              final steps = [
                'Navigate to Settings',
                'Tap on \'Notifications\'',
                'Configure your notification preferences',
                'Enable or disable specific types',
              ];
              _showStepsDialog(
                context,
                'help.app_settings.notifications.title'.tr(),
                steps,
                isDark,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSecuritySection(bool isDark) {
    final securityTopics = [
      'Use a strong, unique password',
      'Keep your email address updated',
      'Log out from shared devices',
      'Report any suspicious activity',
    ];

    return _buildSection(
      title: 'help.account_security.title'.tr(),
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'help.account_security.description'.tr(),
            style: TextStyle(
              color: AppColors.getTextColor(isDark).withOpacity(0.8),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...securityTopics.map((topic) => _buildSecurityTip(topic, isDark)),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingSection(bool isDark) {
    final troubleshootingItems = [
      {
        'problem': 'Can\'t log in to my account',
        'solution':
            'Try resetting your password or check your internet connection',
      },
      {
        'problem': 'App crashes or freezes',
        'solution': 'Close and restart the app, or restart your device',
      },
      {
        'problem': 'Changes not saving',
        'solution': 'Check your internet connection and try again',
      },
      {
        'problem': 'Language not changing',
        'solution': 'Restart the app after changing language settings',
      },
    ];

    return _buildSection(
      title: 'help.troubleshooting.title'.tr(),
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'help.troubleshooting.description'.tr(),
            style: TextStyle(
              color: AppColors.getTextColor(isDark).withOpacity(0.8),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...troubleshootingItems.map(
            (item) => _buildTroubleshootingItem(
              item['problem']!,
              item['solution']!,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(bool isDark) {
    final faqItems = [
      {
        'question': 'How do I create an account?',
        'answer':
            'Tap \'Sign Up\' on the login screen and follow the registration process',
      },
      {
        'question': 'Can I change my account type?',
        'answer':
            'Contact support to change from buyer to garage owner or vice versa',
      },
      {
        'question': 'Is my data secure?',
        'answer':
            'Yes, we use industry-standard encryption to protect your information',
      },
      {
        'question': 'How do I delete my account?',
        'answer': 'Contact our support team to request account deletion',
      },
    ];

    return _buildSection(
      title: 'help.faq.title'.tr(),
      isDark: isDark,
      child: Column(
        children: faqItems
            .map(
              (item) =>
                  _buildFAQItem(item['question']!, item['answer']!, isDark),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTipsSection(bool isDark) {
    final tips = [
      'Keep your profile information up to date',
      'Use the search function to find parts quickly',
      'Enable notifications for important updates',
      'Regularly check for app updates',
      'Log out when using shared devices',
    ];

    return _buildSection(
      title: 'help.tips.title'.tr(),
      isDark: isDark,
      child: Column(
        children: tips.map((tip) => _buildTipItem(tip, isDark)).toList(),
      ),
    );
  }

  Widget _buildContactSupportSection(bool isDark) {
    return _buildSection(
      title: 'help.contact_support.title'.tr(),
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'help.contact_support.description'.tr(),
            style: TextStyle(
              color: AppColors.getTextColor(isDark).withOpacity(0.8),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            Icons.email_rounded,
            'help.contact_support.email'.tr(),
            isDark,
          ),
          const SizedBox(height: 8),
          _buildContactItem(
            Icons.phone_rounded,
            'help.contact_support.phone'.tr(),
            isDark,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'help.contact_support.response_time'.tr(),
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required bool isDark,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.getTextColor(isDark),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildHelpItem({
    required String title,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.getTextColor(isDark).withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.getTextColor(isDark),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.getTextColor(isDark).withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.getTextColor(isDark).withOpacity(0.8),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTip(String tip, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.security_rounded, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: AppColors.getTextColor(isDark).withOpacity(0.8),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingItem(
    String problem,
    String solution,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getTextColor(isDark).withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  problem,
                  style: TextStyle(
                    color: AppColors.getTextColor(isDark),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            solution,
            style: TextStyle(
              color: AppColors.getTextColor(isDark).withOpacity(0.8),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getTextColor(isDark).withOpacity(0.1),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          question,
          style: TextStyle(
            color: AppColors.getTextColor(isDark),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconColor: AppColors.accent,
        collapsedIconColor: AppColors.getTextColor(isDark).withOpacity(0.7),
        children: [
          Text(
            answer,
            style: TextStyle(
              color: AppColors.getTextColor(isDark).withOpacity(0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getTextColor(isDark).withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_rounded, color: AppColors.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: AppColors.getTextColor(isDark).withOpacity(0.8),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.getTextColor(isDark),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showStepsDialog(
    BuildContext context,
    String title,
    List<String> steps,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.getCardBackground(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: AppColors.getTextColor(isDark),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...steps.asMap().entries.map((entry) {
                  int index = entry.key;
                  String step = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step,
                            style: TextStyle(
                              color: AppColors.getTextColor(
                                isDark,
                              ).withOpacity(0.8),
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeveloperSection(BuildContext context, bool isDark) {
    return _buildSection(
      title: 'Developer Tools',
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tools for testing and debugging the application',
            style: TextStyle(
              color: AppColors.getTextColor(isDark).withOpacity(0.8),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Shopify Connection Test
          _buildHelpItem(
            title: 'Test Shopify Connection',
            icon: Icons.api_rounded,
            isDark: isDark,
            onTap: () {
              context.push('/shopify-test');
            },
          ),
        ],
      ),
    );
  }
}
