import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum UserRole { regularBuyer, garageOwner }

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _backgroundAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_backgroundController);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paddingTop = MediaQuery.of(context).padding.top;

    return Theme(
      // Force light theme for auth pages
      data: ThemeData.light().copyWith(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textDark,
        ),
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // Animated background
            AnimatedBuilder(
              animation: _backgroundAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.background,
                        AppColors.primary.withOpacity(0.05),
                        AppColors.background,
                      ],
                      stops: [0.0, 0.5 + 0.3 * _backgroundAnimation.value, 1.0],
                    ),
                  ),
                );
              },
            ),

            // Floating particles effect
            ...List.generate(15, (index) {
              return Positioned(
                left: (index * 50.0) % size.width,
                top: (index * 80.0) % size.height,
                child: AnimatedBuilder(
                  animation: _backgroundAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        20 *
                            _backgroundAnimation.value *
                            (index % 2 == 0 ? 1 : -1),
                        30 * _backgroundAnimation.value,
                      ),
                      child: Opacity(
                        opacity: 0.1 + 0.1 * _backgroundAnimation.value,
                        child: Container(
                          width: 4 + (index % 3) * 2,
                          height: 4 + (index % 3) * 2,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),

            SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: size.height - paddingTop,
                  ),
                  child: Column(
                    children: [
                      // Custom App Bar
                      Container(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.arrow_back,
                                      color: Colors.black,
                                    ),
                                    onPressed: () => context.go('/login'),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'auth.role_selection.title'.tr(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: AppColors.textDark,
                                          fontWeight: FontWeight.w600,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(
                                  width: 48,
                                ), // Balance the back button
                              ],
                            ),
                          )
                          // ✅ Correct chaining: no stray comma/paren before .animate()
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: -0.5),

                      // Content
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Hero Section
                            Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [
                                        AppColors.primary.withOpacity(0.1),
                                        AppColors.primary.withOpacity(0.02),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Icon(
                                    Icons.groups_rounded,
                                    size: 80,
                                    color: AppColors.primary,
                                  ),
                                )
                                .animate()
                                .scale(delay: 300.ms)
                                .then()
                                .shimmer(duration: 1500.ms),

                            const SizedBox(height: 32),

                            Text(
                                  'auth.role_selection.choose_role'.tr(),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                  textAlign: TextAlign.center,
                                )
                                .animate()
                                .fadeIn(delay: 400.ms)
                                .slideY(begin: 0.3),

                            const SizedBox(height: 16),

                            Text(
                              'Choose your role to get started with the best experience',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: AppColors.textDark.withOpacity(0.6),
                                  ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),

                            const SizedBox(height: 48),

                            // Role Cards
                            _AdvancedRoleCard(
                                  title: 'auth.role_selection.regular_buyer'
                                      .tr(),
                                  description:
                                      'auth.role_selection.regular_buyer_desc'
                                          .tr(),
                                  icon: Icons.person_rounded,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withOpacity(0.8),
                                      AppColors.primary,
                                    ],
                                  ),
                                  onTap: () => context.go('/signup/buyer'),
                                )
                                .animate()
                                .fadeIn(delay: 600.ms)
                                .slideX(begin: -0.3),

                            const SizedBox(height: 24),

                            _AdvancedRoleCard(
                                  title: 'auth.role_selection.garage_owner'
                                      .tr(),
                                  description:
                                      'auth.role_selection.garage_owner_desc'
                                          .tr(),
                                  icon: Icons.car_repair_rounded,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withOpacity(0.6),
                                      AppColors.primary.withOpacity(0.8),
                                    ],
                                  ),
                                  onTap: () => context.go('/signup/garage'),
                                )
                                .animate()
                                .fadeIn(delay: 700.ms)
                                .slideX(begin: 0.3),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvancedRoleCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _AdvancedRoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_AdvancedRoleCard> createState() => _AdvancedRoleCardState();
}

class _AdvancedRoleCardState extends State<_AdvancedRoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
    _elevationAnimation = Tween<double>(begin: 8.0, end: 16.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTapDown: (_) => _hoverController.forward(),
        onTapUp: (_) => _hoverController.reverse(),
        onTapCancel: () => _hoverController.reverse(),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: _elevationAnimation.value,
                      offset: Offset(0, _elevationAnimation.value / 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(
                          _isHovered ? 0.3 : 0.1,
                        ),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Gradient overlay
                        Positioned.fill(
                          child: AnimatedOpacity(
                            opacity: _isHovered ? 0.05 : 0.02,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: widget.gradient,
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                          ),
                        ),

                        // Content
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Row(
                            children: [
                              // Icon container
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: widget.gradient,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  widget.icon,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(width: 20),

                              // Text content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.title,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.description,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textDark.withOpacity(
                                          0.7,
                                        ),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Arrow
                              AnimatedRotation(
                                turns: _isHovered ? 0.25 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
