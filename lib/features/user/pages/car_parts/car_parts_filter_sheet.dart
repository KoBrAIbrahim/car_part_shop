import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';

class CarPartsFilterSheet extends StatefulWidget {
  final String selectedCategory;
  final String sortBy;
  final bool sortAscending;
  final List<String> availableCategories;
  final Function(String category, String sortBy, bool sortAscending) onApply;

  const CarPartsFilterSheet({
    super.key,
    required this.selectedCategory,
    required this.sortBy,
    required this.sortAscending,
    required this.availableCategories,
    required this.onApply,
  });

  @override
  State<CarPartsFilterSheet> createState() => _CarPartsFilterSheetState();
}

class _CarPartsFilterSheetState extends State<CarPartsFilterSheet>
    with TickerProviderStateMixin {
  late String _selectedCategory;
  late String _sortBy;
  late bool _sortAscending;

  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _staggerController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _handleAnimation;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _sortBy = widget.sortBy;
    _sortAscending = widget.sortAscending;

    // Initialize animation controllers
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize animations
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _handleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _staggerController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _staggerController.dispose();
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
            child: DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              builder: (context, scrollController) =>
                  _buildSheet(isDark, scrollController),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheet(bool isDark, ScrollController scrollController) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [AppColors.darkCardBackground, AppColors.darkSurface]
              : [AppColors.lightCardBackground, AppColors.lightSurface],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: AppColors.getDivider(isDark).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Enhanced handle bar
          _buildEnhancedHandle(isDark),

          // Enhanced title
          _buildEnhancedTitle(isDark),

          // Enhanced content
          Expanded(child: _buildEnhancedContent(isDark, scrollController)),
        ],
      ),
    );
  }

  Widget _buildEnhancedHandle(bool isDark) {
    return AnimatedBuilder(
      animation: _handleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _handleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.getPrimary(isDark),
                  AppColors.getPrimary(isDark).withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.getPrimary(isDark).withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedTitle(bool isDark) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.getPrimary(isDark).withOpacity(0.1),
                    AppColors.getPrimary(isDark).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.getPrimary(isDark).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.getPrimary(isDark).withOpacity(0.3),
                          AppColors.getPrimary(isDark).withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: AppColors.getPrimary(isDark),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'user.car_parts.filter_sort'.tr(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextColor(isDark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedContent(bool isDark, ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        // Enhanced Category Filter Section
        _buildAnimatedFilterSection(
          isDark: isDark,
          title: 'user.car_parts.filter_by_category'.tr(),
          icon: Icons.category_rounded,
          color: AppColors.accent,
          children: widget.availableCategories
              .asMap()
              .entries
              .map(
                (entry) => _buildEnhancedCategoryChip(
                  entry.value,
                  isDark,
                  delay: entry.key * 100,
                ),
              )
              .toList(),
          delay: 0,
        ),

        const SizedBox(height: 32),

        // Enhanced Sort Section
        _buildAnimatedSortSection(isDark, delay: 400),

        const SizedBox(height: 40),

        // Enhanced Apply Button
        _buildEnhancedApplyButton(isDark, delay: 800),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAnimatedFilterSection({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(30 * (1 - value), 0),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(isDark ? 0.15 : 0.1),
                    color.withOpacity(isDark ? 0.1 : 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 8, children: children),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedCategoryChip(
    String category,
    bool isDark, {
    int delay = 0,
  }) {
    final isSelected = _selectedCategory == category;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        AppColors.getPrimary(isDark),
                        AppColors.getPrimary(isDark).withOpacity(0.8),
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        AppColors.getCardBackground(isDark),
                        AppColors.getSurface(isDark),
                      ],
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.getPrimary(isDark)
                    : AppColors.getDivider(isDark).withOpacity(0.5),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.getPrimary(isDark).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            size: 12,
                            color: AppColors.getPrimary(isDark),
                          ),
                        ),
                      Text(
                        category,
                        style: TextStyle(
                          color: isSelected
                              ? (isDark ? Colors.white : Colors.black)
                              : AppColors.getTextColor(isDark),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedSortSection(bool isDark, {required int delay}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(-30 * (1 - value), 0),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withOpacity(isDark ? 0.15 : 0.1),
                    AppColors.success.withOpacity(isDark ? 0.1 : 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.sort_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'user.car_parts.sort_by'.tr(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sort options
                  _buildEnhancedSortOption(
                    'user.car_parts.sort_name'.tr(),
                    'name',
                    Icons.text_fields_rounded,
                    isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildEnhancedSortOption(
                    'user.car_parts.sort_price'.tr(),
                    'price',
                    Icons.attach_money_rounded,
                    isDark,
                  ),

                  const SizedBox(height: 20),

                  // Sort order toggle
                  _buildEnhancedSortOrderToggle(isDark),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedSortOption(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _sortBy == value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  AppColors.success.withOpacity(0.2),
                  AppColors.success.withOpacity(0.1),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppColors.success.withOpacity(0.5))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _sortBy = value;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.success.withOpacity(0.3)
                        : AppColors.getDivider(isDark).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: isSelected
                        ? AppColors.success
                        : AppColors.getTextColor(isDark).withOpacity(0.6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.success
                          : AppColors.getTextColor(isDark),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  )
                else
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.getDivider(isDark)),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedSortOrderToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.getCardBackground(isDark),
            AppColors.getSurface(isDark),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getDivider(isDark).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withOpacity(0.2),
                  AppColors.accent.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _sortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sort Order',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextColor(isDark),
                  ),
                ),
                Text(
                  _sortAscending
                      ? 'user.car_parts.ascending'.tr()
                      : 'user.car_parts.descending'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.getTextColor(isDark).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 60,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _sortAscending
                    ? [AppColors.success, AppColors.success.withOpacity(0.8)]
                    : [
                        AppColors.getDivider(isDark),
                        AppColors.getDivider(isDark).withOpacity(0.8),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _sortAscending
                    ? AppColors.success
                    : AppColors.getDivider(isDark),
              ),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  left: _sortAscending ? 28 : 2,
                  top: 2,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _sortAscending
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 16,
                      color: _sortAscending
                          ? AppColors.success
                          : AppColors.getDivider(isDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedApplyButton(bool isDark, {required int delay}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [AppColors.darkPrimary, AppColors.secondary]
                    : [AppColors.lightPrimary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.getPrimary(isDark).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_selectedCategory, _sortBy, _sortAscending);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: isDark ? Colors.white : Colors.black,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'user.car_parts.apply_filters'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
