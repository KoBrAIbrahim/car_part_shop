import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/language_switcher.dart';
import '../../../auth/auth_provider.dart';

class AdvancedSettingsPage extends StatefulWidget {
  const AdvancedSettingsPage({super.key});

  @override
  State<AdvancedSettingsPage> createState() => _AdvancedSettingsPageState();
}

class _AdvancedSettingsPageState extends State<AdvancedSettingsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutQuart,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.locale; // This triggers rebuild when locale changes

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: AppColors.getCardBackground(isDark),
          body: SafeArea(
            bottom: false,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Custom App Bar
                    SliverAppBar(
                      expandedHeight: 120,
                      floating: false,
                      pinned: true,
                      backgroundColor: AppColors.getCardBackground(isDark),
                      elevation: 0,
                      automaticallyImplyLeading: false,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          'user.settings.title'.tr(),
                          style: TextStyle(
                            color: AppColors.getTextColor(isDark),
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary.withOpacity(0.1),
                                AppColors.accent.withOpacity(0.05),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Content
                    SliverPadding(
                      padding: const EdgeInsets.all(20.0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Profile setting
                          _buildAnimatedSettingsTile(
                            context: context,
                            icon: Icons.person_rounded,
                            title: 'user.settings.profile'.tr(),
                            subtitle: 'user.settings.manage_account'.tr(),
                            onTap: () => context.push('/profile'),
                            isDark: isDark,
                            delay: 100,
                            showArrow: true,
                          ),

                          const SizedBox(height: 24),

                          // General Settings section header
                          _buildSectionHeader(
                            context: context,
                            title: 'user.settings.general'.tr(),
                            isDark: isDark,
                          ),

                          const SizedBox(height: 12),

                          // Language setting
                          _buildAnimatedSettingsTile(
                            context: context,
                            icon: Icons.language_rounded,
                            title: 'user.settings.language'.tr(),
                            onTap: null,
                            isDark: isDark,
                            delay: 200,
                            trailing: const LanguageSwitcher(),
                          ),

                          const SizedBox(height: 8),

                          // Theme setting
                          _buildAnimatedSettingsTile(
                            context: context,
                            icon: isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            title: 'settings.theme'.tr(),
                            onTap: null,
                            isDark: isDark,
                            delay: 250,
                            trailing: _buildThemeSwitch(themeProvider, isDark),
                          ),

                          const SizedBox(height: 8),

                          // Notifications setting
                          _buildAnimatedSettingsTile(
                            context: context,
                            icon: Icons.notifications_rounded,
                            title: 'user.settings.notifications'.tr(),
                            onTap: () {
                              // Add notification settings navigation
                            },
                            isDark: isDark,
                            delay: 300,
                            showArrow: true,
                          ),

                          const SizedBox(height: 24),

                          // Support section header
                          _buildSectionHeader(
                            context: context,
                            title: 'Support',
                            isDark: isDark,
                          ),

                          const SizedBox(height: 12),

                          // Help setting
                          _buildAnimatedSettingsTile(
                            context: context,
                            icon: Icons.help_center_rounded,
                            title: 'user.settings.help'.tr(),
                            onTap: () => context.push('/help'),
                            isDark: isDark,
                            delay: 350,
                            showArrow: true,
                          ),

                          const SizedBox(height: 8),

                          // About setting
                          _buildAnimatedSettingsTile(
                            context: context,
                            icon: Icons.info_rounded,
                            title: 'user.settings.about'.tr(),
                            onTap: () => context.push('/about'),
                            isDark: isDark,
                            delay: 400,
                            showArrow: true,
                          ),

                          const SizedBox(height: 24),

                          // Logout setting
                          _buildAnimatedSettingsTile(
                            context: context,
                            icon: Icons.logout_rounded,
                            title: 'user.settings.logout'.tr(),
                            onTap: () => _showLogoutDialog(context, isDark),
                            isDark: isDark,
                            delay: 450,
                            isDestructive: true,
                          ),

                          const SizedBox(height: 32),

                          // Version info
                          _buildVersionInfo(isDark),

                          const SizedBox(height: 24),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    required bool isDark,
    required int delay,
    bool showArrow = false,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: _SettingsTileWidget(
              icon: icon,
              title: title,
              subtitle: subtitle,
              onTap: onTap,
              isDark: isDark,
              showArrow: showArrow,
              trailing: trailing,
              isDestructive: isDestructive,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.getTextColor(isDark).withOpacity(0.8),
          fontWeight: FontWeight.w600,
          fontSize: 16,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildThemeSwitch(ThemeProvider themeProvider, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Switch(
        value: isDark,
        onChanged: (value) {
          themeProvider.toggleTheme();
        },
        activeColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withOpacity(0.3),
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.grey.withOpacity(0.3),
      ),
    );
  }

  Widget _buildVersionInfo(bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.getTextColor(isDark).withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'user.settings.version'.tr(args: ['1.0.0']),
          style: TextStyle(
            color: AppColors.getTextColor(isDark).withOpacity(0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext context) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(
                opacity: value,
                child: AlertDialog(
                  backgroundColor: AppColors.getCardBackground(isDark),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    'user.settings.logout_confirm'.tr(),
                    style: TextStyle(
                      color: AppColors.getTextColor(isDark),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Text(
                    'user.settings.logout_message'.tr(),
                    style: TextStyle(
                      color: AppColors.getTextColor(isDark),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        'user.settings.cancel'.tr(),
                        style: TextStyle(
                          color: AppColors.getTextColor(isDark),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _handleLogout(context, isDark),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.error.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        'user.settings.logout'.tr(),
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context, bool isDark) async {
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    navigator.pop();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: AppColors.getCardBackground(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'user.settings.logging_out'.tr(),
                style: TextStyle(
                  color: AppColors.getTextColor(isDark),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      await authProvider.logout();
      navigator.pop();
      router.go('/login');
    } catch (e) {
      print('Logout error: $e');
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Logout failed. Please try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
}

class _SettingsTileWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDark;
  final bool showArrow;
  final Widget? trailing;
  final bool isDestructive;

  const _SettingsTileWidget({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    required this.isDark,
    this.showArrow = false,
    this.trailing,
    this.isDestructive = false,
  });

  @override
  State<_SettingsTileWidget> createState() => _SettingsTileWidgetState();
}

class _SettingsTileWidgetState extends State<_SettingsTileWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _isPressed
              ? AppColors.getCardBackground(widget.isDark).withOpacity(0.8)
              : AppColors.getCardBackground(widget.isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isPressed
                ? AppColors.primary.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
          ),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (widget.isDestructive ? AppColors.error : AppColors.accent)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.icon,
                color: widget.isDestructive ? AppColors.error : AppColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: widget.isDestructive
                          ? AppColors.error
                          : AppColors.getTextColor(widget.isDark),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle!,
                      style: TextStyle(
                        color: AppColors.getTextColor(widget.isDark)
                            .withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.trailing != null) widget.trailing!,
            if (widget.showArrow)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.getTextColor(widget.isDark).withOpacity(0.5),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}