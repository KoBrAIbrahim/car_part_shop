import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  PackageInfo? packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        packageInfo = info;
      });
    }
  }

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
              'about.title'.tr(),
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
                // App Logo and Name Section
                _buildAppHeader(isDark),
                const SizedBox(height: 24),

                // App Description
                _buildDescriptionSection(isDark),
                const SizedBox(height: 24),

                // Mission Section
                _buildMissionSection(isDark),
                const SizedBox(height: 24),

                // Features Section
                _buildFeaturesSection(isDark),
                const SizedBox(height: 24),

                // App Information Section
                _buildAppInfoSection(isDark),
                const SizedBox(height: 24),

                // Contact Information
                _buildContactSection(isDark),
                const SizedBox(height: 24),

                // Feedback Section
                _buildFeedbackSection(context, isDark),
                const SizedBox(height: 24),

                // Legal Section
                _buildLegalSection(isDark),
                const SizedBox(height: 24),

                // Acknowledgments
                _buildAcknowledgmentsSection(isDark),
                const SizedBox(height: 24),

                // Copyright Footer
                _buildCopyrightFooter(isDark),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppHeader(bool isDark) {
    return Center(
      child: Column(
        children: [
          // App Icon/Logo
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.yellow.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              size: 60,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          // App Name
          Text(
            'about.app_name'.tr(),
            style: TextStyle(
              color: AppColors.getTextColor(isDark),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Version
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.yellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.yellow.withOpacity(0.3),
              ),
            ),
            child: Text(
              '${'about.version'.tr()} ${packageInfo?.version ?? '1.0.0'}',
              style: TextStyle(
                color: AppColors.yellow,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(bool isDark) {
    return _buildSectionCard(
      isDark: isDark,
      child: Text(
        'about.app_description'.tr(),
        style: TextStyle(
          color: AppColors.getTextColor(isDark),
          fontSize: 16,
          height: 1.6,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMissionSection(bool isDark) {
    return _buildSection(
      title: 'about.mission_title'.tr(),
      isDark: isDark,
      child: Text(
        'about.mission_description'.tr(),
        style: TextStyle(
          color: AppColors.getTextColor(isDark).withOpacity(0.8),
          fontSize: 15,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(bool isDark) {
    final features = [
      {
        'icon': Icons.search_rounded,
        'title': 'about.features.search'.tr(),
        'description': 'about.features.search_desc'.tr(),
      },
      {
        'icon': Icons.inventory_2_rounded,
        'title': 'about.features.catalog'.tr(),
        'description': 'about.features.catalog_desc'.tr(),
      },
      {
        'icon': Icons.verified_rounded,
        'title': 'about.features.quality'.tr(),
        'description': 'about.features.quality_desc'.tr(),
      },
      {
        'icon': Icons.support_agent_rounded,
        'title': 'about.features.support'.tr(),
        'description': 'about.features.support_desc'.tr(),
      },
      {
        'icon': Icons.local_shipping_rounded,
        'title': 'about.features.delivery'.tr(),
        'description': 'about.features.delivery_desc'.tr(),
      },
      {
        'icon': Icons.security_rounded,
        'title': 'about.features.warranty'.tr(),
        'description': 'about.features.warranty_desc'.tr(),
      },
    ];

    return _buildSection(
      title: 'about.features_title'.tr(),
      isDark: isDark,
      child: Column(
        children: features
            .map(
              (feature) => _buildFeatureItem(
                icon: feature['icon'] as IconData,
                title: feature['title'] as String,
                description: feature['description'] as String,
                isDark: isDark,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.yellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.yellow, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.getTextColor(isDark),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.getTextColor(isDark).withOpacity(0.7),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoSection(bool isDark) {
    return _buildSection(
      title: 'about.app_info'.tr(),
      isDark: isDark,
      child: Column(
        children: [
          _buildInfoRow(
            'about.version'.tr(),
            packageInfo?.version ?? '1.0.0',
            isDark,
          ),
          _buildInfoRow(
            'about.build_number'.tr(),
            packageInfo?.buildNumber ?? '1',
            isDark,
          ),
          _buildInfoRow(
            'about.developer'.tr(),
            'about.developer_name'.tr(),
            isDark,
          ),
          _buildInfoRow('about.powered_by'.tr(), 'Flutter', isDark),
        ],
      ),
    );
  }

  Widget _buildContactSection(bool isDark) {
    return _buildSection(
      title: 'about.contact_title'.tr(),
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'about.contact_info'.tr(),
            style: TextStyle(
              color: AppColors.getTextColor(isDark).withOpacity(0.8),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            Icons.email_rounded,
            'about.email'.tr(),
            'support@carpartsshop.com',
            isDark,
          ),
          _buildContactItem(
            Icons.phone_rounded,
            'about.phone'.tr(),
            '+970-XXX-XXXX',
            isDark,
          ),
          _buildContactItem(
            Icons.language_rounded,
            'about.website'.tr(),
            'www.carpartsshop.com',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.yellow, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              color: AppColors.getTextColor(isDark),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.getTextColor(isDark).withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(BuildContext context, bool isDark) {
    return _buildSection(
      title: 'about.feedback_title'.tr(),
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'about.feedback_desc'.tr(),
            style: TextStyle(
              color: AppColors.getTextColor(isDark).withOpacity(0.8),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'about.rate_app'.tr(),
                  Icons.star_rounded,
                  AppColors.yellow,
                  isDark,
                  () {
                    _showRateAppDialog(context, isDark);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'about.send_feedback'.tr(),
                  Icons.feedback_rounded,
                  AppColors.info,
                  isDark,
                  () {
                    _showFeedbackDialog(context, isDark);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection(bool isDark) {
    return _buildSection(
      title: 'about.legal_title'.tr(),
      isDark: isDark,
      child: Column(
        children: [
          _buildLegalItem(
            'about.privacy_policy'.tr(),
            Icons.privacy_tip_rounded,
            isDark,
            () => _showPrivacyPolicyDialog(context, isDark),
          ),
          _buildLegalItem(
            'about.terms_of_service'.tr(),
            Icons.description_rounded,
            isDark,
            () => _showTermsOfServiceDialog(context, isDark),
          ),
          _buildLegalItem(
            'about.licenses'.tr(),
            Icons.code_rounded,
            isDark,
            () => _showLicensesDialog(context, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalItem(
    String title,
    IconData icon,
    bool isDark,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: AppColors.yellow, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.getTextColor(isDark),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
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

  Widget _buildAcknowledgmentsSection(bool isDark) {
    return _buildSection(
      title: 'about.acknowledgments_title'.tr(),
      isDark: isDark,
      child: Text(
        'about.acknowledgments_desc'.tr(),
        style: TextStyle(
          color: AppColors.getTextColor(isDark).withOpacity(0.8),
          fontSize: 15,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildCopyrightFooter(bool isDark) {
    return Center(
      child: Column(
        children: [
          Text(
            'about.copyright'.tr(),
            style: TextStyle(
              color: AppColors.getTextColor(isDark).withOpacity(0.6),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flutter_dash,
                color: AppColors.yellow.withOpacity(0.7),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'about.powered_by'.tr(),
                style: TextStyle(
                  color: AppColors.getTextColor(isDark).withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
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

  Widget _buildSectionCard({required bool isDark, required Widget child}) {
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
      child: child,
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.getTextColor(isDark),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.getTextColor(isDark).withOpacity(0.8),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    bool isDark,
    VoidCallback onPressed,
  ) {
    // Determine text color based on background color
    final foregroundColor = color == AppColors.yellow ? Colors.black : Colors.white;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.getCardBackground(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'about.send_feedback'.tr(),
            style: TextStyle(
              color: AppColors.getTextColor(isDark),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This feature will be available soon. You can contact us directly via email or phone.',
                style: TextStyle(
                  color: AppColors.getTextColor(isDark).withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.yellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.yellow.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'support@carpartsshop.com',
                  style: TextStyle(
                    color: AppColors.yellow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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

  void _showRateAppDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.getCardBackground(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'about.rate_app'.tr(),
            style: TextStyle(
              color: AppColors.getTextColor(isDark),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Thank you for using our app! Rating will be available when the app is published to app stores.',
                style: TextStyle(
                  color: AppColors.getTextColor(isDark).withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => Icon(Icons.star, color: AppColors.yellow, size: 32),
                ),
              ),
            ],
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

  void _showPrivacyPolicyDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.getCardBackground(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'about.privacy_policy'.tr(),
            style: TextStyle(
              color: AppColors.getTextColor(isDark),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              'Privacy Policy\n\n'
              'Car Parts Shop is committed to protecting your privacy. This policy explains how we collect, use, and protect your information.\n\n'
              '1. Information We Collect\n'
              '- Personal information (name, email, phone)\n'
              '- Usage data and preferences\n'
              '- Device information\n\n'
              '2. How We Use Information\n'
              '- To provide and improve our services\n'
              '- To communicate with you\n'
              '- To personalize your experience\n\n'
              '3. Data Protection\n'
              'We implement appropriate security measures to protect your data.',
              style: TextStyle(
                color: AppColors.getTextColor(isDark).withOpacity(0.8),
                fontSize: 14,
                height: 1.5,
              ),
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

  void _showTermsOfServiceDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.getCardBackground(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'about.terms_of_service'.tr(),
            style: TextStyle(
              color: AppColors.getTextColor(isDark),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              'Terms of Service\n\n'
              'By using Car Parts Shop, you agree to these terms:\n\n'
              '1. Acceptance of Terms\n'
              'By accessing our app, you accept these terms and conditions.\n\n'
              '2. Use of Service\n'
              '- Use the app only for lawful purposes\n'
              '- Do not misuse or harm the service\n'
              '- Respect other users\n\n'
              '3. Account Responsibility\n'
              'You are responsible for maintaining account security.\n\n'
              '4. Limitation of Liability\n'
              'We are not liable for any damages arising from app usage.',
              style: TextStyle(
                color: AppColors.getTextColor(isDark).withOpacity(0.8),
                fontSize: 14,
                height: 1.5,
              ),
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

  void _showLicensesDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.getCardBackground(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'about.licenses'.tr(),
            style: TextStyle(
              color: AppColors.getTextColor(isDark),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              'Open Source Licenses\n\n'
              'This app uses the following open source packages:\n\n'
              '• Flutter (BSD-3-Clause)\n'
              '• Provider (MIT)\n'
              '• GoRouter (BSD-3-Clause)\n'
              '• Easy Localization (MIT)\n'
              '• Cached Network Image (MIT)\n'
              '• Shared Preferences (BSD-3-Clause)\n'
              '• Flutter Secure Storage (BSD-3-Clause)\n'
              '• Hive (Apache-2.0)\n'
              '• Package Info Plus (BSD-3-Clause)\n'
              '• Image Picker (Apache-2.0)\n\n'
              'We thank all the open source contributors for their amazing work!',
              style: TextStyle(
                color: AppColors.getTextColor(isDark).withOpacity(0.8),
                fontSize: 14,
                height: 1.5,
              ),
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
}