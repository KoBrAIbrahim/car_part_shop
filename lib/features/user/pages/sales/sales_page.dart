import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class SalesPage extends StatelessWidget {
  const SalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to locale changes to rebuild the widget immediately
    context.locale; // This triggers rebuild when locale changes

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_offer_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'user.sales.title'.tr(),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'user.sales.subtitle'.tr(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sales Categories
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  children: [
                    _buildSalesCard(
                      context: context,
                      icon: Icons.flash_on_rounded,
                      title: 'user.sales.flash_deals'.tr(),
                      subtitle: 'user.sales.flash_deals_desc'.tr(),
                      color: Colors.orange,
                      isDark: isDark,
                    ),
                    _buildSalesCard(
                      context: context,
                      icon: Icons.percent_rounded,
                      title: 'user.sales.discounts'.tr(),
                      subtitle: 'user.sales.discounts_desc'.tr(),
                      color: Colors.red,
                      isDark: isDark,
                    ),
                    _buildSalesCard(
                      context: context,
                      icon: Icons.card_giftcard_rounded,
                      title: 'user.sales.seasonal'.tr(),
                      subtitle: 'user.sales.seasonal_desc'.tr(),
                      color: Colors.green,
                      isDark: isDark,
                    ),
                    _buildSalesCard(
                      context: context,
                      icon: Icons.stars_rounded,
                      title: 'user.sales.premium'.tr(),
                      subtitle: 'user.sales.premium_desc'.tr(),
                      color: Colors.purple,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Coming Soon Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.getCardBackground(isDark),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'user.sales.coming_soon'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.getTextColor(isDark),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'user.sales.coming_soon_desc'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.getTextColor(isDark).withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSalesCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: Navigate to specific sales category
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('user.sales.coming_soon'.tr()),
                backgroundColor: color,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.getTextColor(isDark),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.getTextColor(isDark).withOpacity(0.7),
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
