import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/api/models/car_part.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';

class CarPartCard extends StatefulWidget {
  final CarPart part;
  final String carName;
  final Function(CarPart) onTap;
  final bool isGarageOwner;
  final int index;

  const CarPartCard({
    super.key,
    required this.part,
    required this.carName,
    required this.onTap,
    required this.isGarageOwner,
    this.index = 0,
  });

  @override
  State<CarPartCard> createState() => _CarPartCardState();
}

class _CarPartCardState extends State<CarPartCard>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600 + (widget.index * 100)),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Initialize animations
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Start entrance animations with staggered delay
    Future.delayed(Duration(milliseconds: widget.index * 150), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });

    // Start pulse animation for sale items
    if (widget.part.hasSalePrice(isGarageOwner: widget.isGarageOwner)) {
      _pulseController.repeat(reverse: true);
    }

    // Start shimmer for live items
    if (widget.part.hasShopifyData) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
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
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: _buildCard(isDark),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(bool isDark) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: () => widget.onTap(widget.part),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.darkCardBackground,
                      AppColors.darkSurface.withOpacity(0.8),
                    ]
                  : [Colors.white, AppColors.lightSurface.withOpacity(0.5)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHovered
                  ? AppColors.getPrimary(isDark).withOpacity(0.6)
                  : AppColors.getDivider(isDark).withOpacity(0.2),
              width: _isHovered ? 2.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? AppColors.getPrimary(isDark).withOpacity(0.25)
                    : (isDark
                          ? Colors.black.withOpacity(0.4)
                          : Colors.grey.withOpacity(0.15)),
                blurRadius: _isHovered ? 20 : 10,
                offset: Offset(0, _isHovered ? 8 : 4),
                spreadRadius: _isHovered ? 2 : 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full-width image section
                _buildFullWidthImage(isDark),

                // Content section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isDark),
                      const SizedBox(height: 12),
                      _buildDescription(isDark),
                      const SizedBox(height: 16),
                      _buildTags(isDark),
                      const SizedBox(height: 16),
                      _buildPriceAndStock(isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullWidthImage(bool isDark) {
    return Hero(
      tag:
          'part_image_${widget.part.id ?? widget.part.partNumber}_${widget.index}',
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.darkSurface,
                    AppColors.darkBackground.withOpacity(0.8),
                  ]
                : [AppColors.lightSurface.withOpacity(0.1), Colors.white],
          ),
        ),
        child: Stack(
          children: [
            // Main image
            if (widget.part.allImageUrls.isNotEmpty)
              _buildMainImage()
            else
              _buildPlaceholderImage(isDark),

            // Overlay gradient for better text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.1)],
                ),
              ),
            ),

            // Image indicators and badges
            _buildImageOverlays(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMainImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Image.network(
        widget.part.allImageUrls.first,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(
          Theme.of(context).brightness == Brightness.dark,
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildImageLoader(loadingProgress);
        },
      ),
    );
  }

  Widget _buildPlaceholderImage(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.getPrimary(isDark).withOpacity(0.15),
            AppColors.getPrimary(isDark).withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings_rounded,
              size: 48,
              color: AppColors.getPrimary(isDark).withOpacity(0.6),
            ),
            const SizedBox(height: 8),
            Text(
              'No Image',
              style: TextStyle(
                color: AppColors.getPrimary(isDark).withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageLoader(ImageChunkEvent loadingProgress) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.getDivider(
              Theme.of(context).brightness == Brightness.dark,
            ).withOpacity(0.1),
            AppColors.getDivider(
              Theme.of(context).brightness == Brightness.dark,
            ).withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.getPrimary(
                  Theme.of(context).brightness == Brightness.dark,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading...',
              style: TextStyle(
                color: AppColors.getTextColor(
                  Theme.of(context).brightness == Brightness.dark,
                ).withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOverlays(bool isDark) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Live indicator
          if (widget.part.hasShopifyData)
            Positioned(
              top: 12,
              left: 12,
              child: AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppColors.accent.withOpacity(0.9),
                          AppColors.accent,
                          AppColors.accent.withOpacity(0.9),
                        ],
                        stops: [0.0, (_shimmerAnimation.value + 2) / 4, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'LIVE PRICING',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // Sale badge
          if (widget.part.hasSalePrice(isGarageOwner: widget.isGarageOwner))
            Positioned(
              top: 12,
              right: 12,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.error, Color(0xFFFF5722)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${widget.part.getSalePercentage(isGarageOwner: widget.isGarageOwner)}% OFF',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Image count indicator
          if (widget.part.allImageUrls.length > 1)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.part.allImageUrls.length} images',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.part.displayTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextColor(isDark),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.part.displayTitle != widget.part.partNumber) ...[
                const SizedBox(height: 4),
                Text(
                  'Part #: ${widget.part.partNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextColor(isDark).withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildStockIndicator(isDark),
      ],
    );
  }

  Widget _buildDescription(bool isDark) {
    return Text(
      widget.part.displayDescription,
      style: TextStyle(
        fontSize: 14,
        color: AppColors.getTextColor(isDark).withOpacity(0.8),
        height: 1.4,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTags(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildAnimatedChip(
            label: widget.part.displayBrand,
            color: AppColors.accent,
            isDark: isDark,
            icon: Icons.verified_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAnimatedChip(
            label: widget.part.displayCategory,
            color: AppColors.success,
            isDark: isDark,
            icon: Icons.category_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedChip({
    required String label,
    required Color color,
    required bool isDark,
    required IconData icon,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (widget.index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(isDark ? 0.2 : 0.1),
                  color.withOpacity(isDark ? 0.1 : 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceAndStock(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _buildPriceSection(isDark)),
        const SizedBox(width: 16),
        _buildActionButton(isDark),
      ],
    );
  }

  Widget _buildPriceSection(bool isDark) {
    final hasSale = widget.part.hasSalePrice(
      isGarageOwner: widget.isGarageOwner,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.part.getPrice(isGarageOwner: widget.isGarageOwner),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: hasSale ? AppColors.error : AppColors.success,
            letterSpacing: -0.5,
          ),
        ),
        if (hasSale && widget.part.shopifyProduct?.compareAtPrice != null)
          Text(
            '₪${widget.part.shopifyProduct!.compareAtPrice!.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextColor(isDark).withOpacity(0.5),
              decoration: TextDecoration.lineThrough,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildStockIndicator(bool isDark) {
    final isInStock = widget.part.isInStock;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isInStock
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isInStock
              ? AppColors.success.withOpacity(0.3)
              : AppColors.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isInStock ? AppColors.success : AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            widget.part.stockStatus,
            style: TextStyle(
              fontSize: 10,
              color: isInStock ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.getPrimary(isDark),
            AppColors.getPrimary(isDark).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.getPrimary(isDark).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => widget.onTap(widget.part),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
