import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';

class CarPartsHeader extends StatefulWidget {
  final String carName;
  final int totalParts;
  final bool isLoading;
  final VoidCallback? onFilterPressed;
  final VoidCallback? onSearchPressed;
  final bool hasActiveFilters;
  final VoidCallback? onCacheManagePressed;
  final bool showActions;

  const CarPartsHeader({
    super.key,
    required this.carName,
    required this.totalParts,
    this.isLoading = false,
    this.onFilterPressed,
    this.onSearchPressed,
    this.hasActiveFilters = false,
    this.onCacheManagePressed,
    this.showActions = true,
  });

  @override
  State<CarPartsHeader> createState() => _CarPartsHeaderState();
}

class _CarPartsHeaderState extends State<CarPartsHeader>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  bool _isFilterPressed = false;
  bool _isBackPressed = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Initialize animations
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start entrance animations
    _fadeController.forward();
    _slideController.forward();

    // Start subtle pulse animation
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildHeader(isDark, context),
          ),
        );
      },
    );
  }
  Widget _buildHeader(bool isDark, BuildContext context) {
    // Reuse the same visual contract as AppHeaderWidget: logo on the left,
    // centered title, and action icons on the right.
    final headerBg = isDark ? AppColors.darkCardBackground : Colors.white;

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;

    return Container(
      decoration: BoxDecoration(
        color: headerBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 28 : (isTablet ? 20 : 12),
            vertical: isSmallScreen ? 6 : 8,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo on the left
                  Image.asset(
                    'assets/logo1.png',
                    width: isDesktop ? 64 : (isTablet ? 56 : 48),
                    height: isDesktop ? 64 : (isTablet ? 56 : 48),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.directions_car_rounded,
                        size: isDesktop ? 64 : (isTablet ? 56 : 48),
                        color: AppColors.yellow,
                      );
                    },
                  ),

                  // Actions on the right: search, filter, cache/manage (optional)
                  if (widget.showActions)
                    Row(
                      children: [
                        // Search icon — call parent callback to open inline search
                        IconButton(
                          onPressed: widget.onSearchPressed ?? () => context.go('/home'),
                          icon: Icon(Icons.search_rounded,
                              color: AppColors.getTextColor(isDark)),
                          tooltip: 'Search',
                        ),

                        if (widget.onCacheManagePressed != null)
                          IconButton(
                            onPressed: widget.onCacheManagePressed,
                            icon: Icon(Icons.storage_rounded,
                                color: AppColors.getTextColor(isDark)),
                            tooltip: 'Cache',
                          ),
                      ],
                    ),
                ],
              ),

              // Centered title
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: screenWidth * 0.6),
                  child: Text(
                    'user.car_parts.title'.tr(),
                    style: TextStyle(
                      color: AppColors.getTextColor(isDark),
                      fontWeight: FontWeight.bold,
                      fontSize: isDesktop ? 24 : (isTablet ? 22 : 20),
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeaderRow(bool isDark) {
    return Row(
      children: [
        // Compact Back Button
        _buildCompactButton(
          onPressed: () {
            setState(() => _isBackPressed = true);
            _scaleController.forward().then((_) {
              _scaleController.reverse();
              Navigator.of(context).pop();
            });
          },
          icon: Icons.arrow_back_ios_new_rounded,
          isPressed: _isBackPressed,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        // Compact Title
        Expanded(
          child: Text(
            'user.car_parts.title'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
          ),
        ),
        // Compact Filter Button (Hidden when null)
        if (widget.onFilterPressed != null)
          _buildCompactButton(
            onPressed: () {
              setState(() => _isFilterPressed = true);
              _scaleController.forward().then((_) {
                _scaleController.reverse();
                setState(() => _isFilterPressed = false);
                widget.onFilterPressed!();
              });
            },
            icon: Icons.filter_alt_rounded,
            isPressed: _isFilterPressed,
            isDark: isDark,
            showBadge: widget.hasActiveFilters,
          ),
      ],
    );
  }

  Widget _buildCompactButton({
    required VoidCallback onPressed,
    required IconData icon,
    required bool isPressed,
    required bool isDark,
    bool showBadge = false,
  }) {
    return AnimatedScale(
      scale: isPressed ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: Colors.black, size: 18),
                if (showBadge)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.error.withOpacity(0.5),
                                  blurRadius: 2,
                                  spreadRadius: 0.5,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineCarInfo(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: [
          // Compact Car Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black.withOpacity(0.2)),
            ),
            child: Icon(
              Icons.directions_car_filled_rounded,
              color: Colors.black,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // Car Name and Parts Count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.carName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        height: 1.1,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                widget.isLoading
                    ? _buildLoadingIndicator()
                    : _buildPartsInfo(isDark),
              ],
            ),
          ),
          // Status Indicator
          _buildStatusChip(isDark),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.black.withOpacity(0.7),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Loading parts...',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPartsInfo(bool isDark) {
    return TweenAnimationBuilder<int>(
      duration: const Duration(milliseconds: 800),
      tween: IntTween(begin: 0, end: widget.totalParts),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: widget.hasActiveFilters
                    ? ' parts found'
                    : ' parts available',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isLoading
            ? AppColors.info.withOpacity(0.2)
            : AppColors.success.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.isLoading
              ? AppColors.info.withOpacity(0.4)
              : AppColors.success.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: widget.isLoading ? AppColors.info : AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            widget.isLoading ? 'Loading' : 'Ready',
            style: TextStyle(
              fontSize: 10,
              color: widget.isLoading ? AppColors.info : AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}