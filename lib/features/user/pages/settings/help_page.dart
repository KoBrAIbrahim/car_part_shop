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
          color: AppColors.getDivider(isDark),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.help_center_rounded, size: 64, color: AppColors.yellow),
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

          // Theme Settings
          _buildHelpItem(
            title: 'help.app_settings.theme.title'.tr(),
            icon: Icons.palette_rounded,
            isDark: isDark,
            onTap: () {
              final steps = [
                'Go to Settings',
                'Find the \'Theme\' section',
                'Toggle between Light and Dark mode',
                'Your preference is saved automatically',
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

          // Language Settings
          _buildHelpItem(
            title: 'help.app_settings.language.title'.tr(),
            icon: Icons.language_rounded,
            isDark: isDark,
            onTap: () {
              final steps = [
                'Navigate to Settings',
                'Tap on \'Language\'',
                'Select your preferred language',
                'The app will update immediately',
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

          // Notification Settings
          _buildHelpItem(
            title: 'help.app_settings.notifications.title'.tr(),
            icon: Icons.notifications_rounded,
            isDark: isDark,
            onTap: () {
              final steps = [
                'Open Settings',
                'Scroll to \'Notifications\'',
                'Toggle notification preferences',
                'Customize notification types as needed',
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
          _buildSecurityTip(
            'Use a strong, unique password',
            isDark,
          ),
          _buildSecurityTip(
            'Enable two-factor authentication when available',
            isDark,
          ),
          _buildSecurityTip(
            'Don\'t share your account credentials',
            isDark,
          ),
          _buildSecurityTip(
            'Log out from shared devices',
            isDark,
          ),
          _buildSecurityTip(
            'Regularly review your account activity',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingSection(bool isDark) {
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
          _buildTroubleshootingItem(
            'App crashes or freezes',
            'Try restarting the app. If the problem persists, clear the app cache or reinstall.',
            isDark,
          ),
          _buildTroubleshootingItem(
            'Can\'t log in',
            'Check your credentials. Use \'Forgot Password\' if needed. Ensure you have internet connection.',
            isDark,
          ),
          _buildTroubleshootingItem(
            'Features not working',
            'Make sure you have the latest app version. Check your internet connection.',
            isDark,
          ),
          _buildTroubleshootingItem(
            'Slow performance',
            'Close other apps, clear cache, or restart your device.',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(bool isDark) {
    return _buildSection(
      title: 'help.faq.title'.tr(),
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFAQItem(
            'How do I create an account?',
            'Tap the \'Sign Up\' button on the login screen, fill in your details, and verify your email.',
            isDark,
          ),
          _buildFAQItem(
            'Is my data secure?',
            'Yes, we use industry-standard encryption and security measures to protect your data.',
            isDark,
          ),
          _buildFAQItem(
            'How do I delete my account?',
            'Go to Settings → Account → Delete Account. Note that this action is permanent.',
            isDark,
          ),
          _buildFAQItem(
            'Can I use the app offline?',
            'Some features work offline, but most require an internet connection.',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection(bool isDark) {
    return _buildSection(
      title: 'help.tips.title'.tr(),
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'help.tips.description'.tr(),
            style: TextStyle(
              color: AppColors.getTextColor(isDark).withOpacity(0.8),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildTipItem(
            'Keep your app updated to access the latest features',
            isDark,
          ),
          _buildTipItem(
            'Enable notifications to stay informed',
            isDark,
          ),
          _buildTipItem(
            'Customize your profile for a personalized experience',
            isDark,
          ),
          _buildTipItem(
            'Use the search feature to find what you need quickly',
            isDark,
          ),
        ],
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
            'support@carpartsshop.com',
            isDark,
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            Icons.phone_rounded,
            '+970-XXX-XXXX',
            isDark,
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            Icons.language_rounded,
            'www.carpartsshop.com',
            isDark,
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
            color: AppColors.getDivider(isDark),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.yellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.yellow, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.getTextColor(isDark),
                  fontSize: 15,
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
            margin: const EdgeInsets.only(top: 8),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.yellow,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
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
          Icon(Icons.security_rounded, color: AppColors.yellow, size: 20),
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
          color: AppColors.getDivider(isDark),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded, color: AppColors.warning, size: 20),
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
          color: AppColors.getDivider(isDark),
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
        iconColor: AppColors.yellow,
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
          color: AppColors.getDivider(isDark),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_rounded, color: AppColors.yellow, size: 20),
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
        Icon(icon, color: AppColors.yellow, size: 20),
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
                            color: AppColors.yellow,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.black,
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
              child: Text('Close', style: TextStyle(color: AppColors.yellow)),
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