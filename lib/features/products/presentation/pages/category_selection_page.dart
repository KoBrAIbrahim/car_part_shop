import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
import '../../../../core/providers/car_parts_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../user/pages/car_parts/car_parts_page.dart';
import 'subcategory_selection_page.dart';

class CategorySelectionPage extends StatefulWidget {
  final int carId;
  final String carName;

  const CategorySelectionPage({
    super.key,
    required this.carId,
    required this.carName,
  });

  @override
  State<CategorySelectionPage> createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage>
    with TickerProviderStateMixin {
  List<String> _categories = [];
  Map<String, Set<String>> _categorySubcategories = {};
  bool _isLoading = true;
  late AnimationController _animationController;
  late PageController _pageController;
  int _currentPage = 0;
  bool _isGridView = false; // false = single card, true = 2 cards per row

  @override
  void initState() {
    super.initState();
    // viewportFraction = 1.0 for full control
    _pageController = PageController(viewportFraction: 1.0);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadCategories();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final provider = Provider.of<CarPartsProvider>(context, listen: false);
    await provider.loadPartsForCar(widget.carId);

    if (mounted) {
      final categories = provider.allParts
          .map((part) => part.displayCategory)
          .toSet()
          .toList();
      categories.sort();

      final Map<String, Set<String>> subcategoriesMap = {};
      for (final part in provider.allParts) {
        final category = part.displayCategory;
        final subcategory = part.displaySubcategory;

        if (subcategory != null && subcategory.isNotEmpty) {
          subcategoriesMap.putIfAbsent(category, () => <String>{});
          subcategoriesMap[category]!.add(subcategory);
        }
      }

      setState(() {
        _categories = categories;
        _categorySubcategories = subcategoriesMap;
        _isLoading = false;
      });

      _animationController.forward();
    }
  }

  void _showCategoryDetails(String category) {
    // Previously we showed a bottom-sheet dialog with category details.
    // Per UX request, remove that dialog and navigate immediately.
    final subcategories = _categorySubcategories[category];

    if (subcategories != null && subcategories.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubcategorySelectionPage(
            carId: widget.carId,
            carName: widget.carName,
            category: category,
            subcategories: subcategories.toList()..sort(),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CarPartsPage(
            carId: widget.carId,
            carName: widget.carName,
            initialCategory: category,
          ),
        ),
      );
    }
  }

  // Build single card view (PageView)
  Widget _buildSingleView(double cardWidth, double cardHeight, bool isDark) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() => _currentPage = index);
      },
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        return Center(
          child: SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: _CategoryCard(
              category: _categories[index],
              subcategoryCount:
                  _categorySubcategories[_categories[index]]?.length ?? 0,
              isDark: isDark,
              onTap: () => _showCategoryDetails(_categories[index]),
            ),
          ),
        );
      },
    );
  }

  // Build grid view (2 cards per row with yellow border)
  Widget _buildGridView(double cardWidth, double cardHeight, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 cards per row
        childAspectRatio: 0.65, // Adjusted for better fit
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.yellow,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17), // Slightly less to fit inside border
            child: _CategoryCard(
              category: _categories[index],
              subcategoryCount:
                  _categorySubcategories[_categories[index]]?.length ?? 0,
              isDark: isDark,
              onTap: () => _showCategoryDetails(_categories[index]),
              isGridView: true, // Pass flag to indicate grid view
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isRtl = context.locale.languageCode == 'ar' ||
        context.locale.languageCode == 'he';

    // Fixed dimensions: 80% width, 60% height
    final cardWidth = screenWidth * 0.8;
    final cardHeight = screenHeight * 0.6;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final bgColor = AppColors.getBackground(isDark);
        final textColor = AppColors.getTextColor(isDark);

        return Scaffold(
          backgroundColor: bgColor,
          body: Stack(
            children: [
              // Background gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.yellow.withOpacity(isDark ? 0.1 : 0.05),
                      bgColor,
                      bgColor,
                    ],
                  ),
                ),
              ),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Custom App Bar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Back button
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.getCardBackground(isDark),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                isRtl
                                    ? Icons.arrow_forward_rounded
                                    : Icons.arrow_back_rounded,
                                color: textColor,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Title
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'user.car_parts.category'.tr(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  widget.carName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.getTextSecondaryColor(isDark),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // View toggle button
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.yellow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.yellow,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.yellow.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isGridView 
                                    ? Icons.view_agenda_rounded 
                                    : Icons.grid_view_rounded,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isGridView = !_isGridView;
                                });
                              },
                              tooltip: _isGridView 
                                  ? 'Single View' 
                                  : 'Grid View',
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Page indicator
                          if (!_isLoading && _categories.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.yellow,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_currentPage + 1}/${_categories.length}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Loading state
                    if (_isLoading)
                      Expanded(
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.yellow,
                            ),
                          ),
                        ),
                      )
                    else if (_categories.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            'user.car_parts.no_parts_found'.tr(),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      )
                    else
                      // Card Display - Single or Grid View
                      Expanded(
                        child: _isGridView
                            ? _buildGridView(cardWidth, cardHeight, isDark)
                            : _buildSingleView(cardWidth, cardHeight, isDark),
                      ),

                    // Bottom hint - Only show in single view mode
                    if (!_isLoading && _categories.isNotEmpty && !_isGridView)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 24,
                          bottom: 24,
                          top: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.swipe_rounded,
                              color: AppColors.getTextSecondaryColor(isDark),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isRtl
                                    ? 'مرر لرؤية المزيد'
                                    : context.locale.languageCode == 'he'
                                        ? 'החלק לראות עוד'
                                        : 'Swipe to explore',
                                style: TextStyle(
                                  color: AppColors.getTextSecondaryColor(isDark),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
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
}

class _CategoryCard extends StatefulWidget {
  final String category;
  final int subcategoryCount;
  final bool isDark;
  final VoidCallback onTap;
  final bool isGridView;

  const _CategoryCard({
    required this.category,
    required this.subcategoryCount,
    required this.isDark,
    required this.onTap,
    this.isGridView = false,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('engine') ||
        categoryLower.contains('محرك') ||
        categoryLower.contains('מנוע')) {
      return Icons.settings_rounded;
    } else if (categoryLower.contains('brake') ||
        categoryLower.contains('فرامل') ||
        categoryLower.contains('בלם')) {
      return Icons.stop_circle_rounded;
    } else if (categoryLower.contains('suspension') ||
        categoryLower.contains('تعليق') ||
        categoryLower.contains('מתלה')) {
      return Icons.directions_car_rounded;
    } else if (categoryLower.contains('electrical') ||
        categoryLower.contains('كهرباء') ||
        categoryLower.contains('חשמל')) {
      return Icons.electric_bolt_rounded;
    } else if (categoryLower.contains('body') ||
        categoryLower.contains('هيكل') ||
        categoryLower.contains('מרכב')) {
      return Icons.car_repair_rounded;
    } else if (categoryLower.contains('interior') ||
        categoryLower.contains('داخلي') ||
        categoryLower.contains('פנים')) {
      return Icons.airline_seat_recline_normal_rounded;
    } else if (categoryLower.contains('wheel') ||
        categoryLower.contains('عجל') ||
        categoryLower.contains('גלגל')) {
      return Icons.album_rounded;
    } else if (categoryLower.contains('filter') ||
        categoryLower.contains('فلتر') ||
        categoryLower.contains('מסנן')) {
      return Icons.filter_alt_rounded;
    } else if (categoryLower.contains('oil') ||
        categoryLower.contains('زيت') ||
        categoryLower.contains('שמן')) {
      return Icons.oil_barrel_rounded;
    } else if (categoryLower.contains('light') ||
        categoryLower.contains('إضاءة') ||
        categoryLower.contains('אור')) {
      return Icons.lightbulb_rounded;
    } else if (categoryLower.contains('battery') ||
        categoryLower.contains('بطارية') ||
        categoryLower.contains('סוללה')) {
      return Icons.battery_charging_full_rounded;
    } else {
      return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getCategoryIcon(widget.category);
    final isGrid = widget.isGridView;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1.0 - (_controller.value * 0.03);
          return Transform.scale(
            scale: scale,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isGrid ? 20 : 32),
                boxShadow: isGrid ? [] : [
                  BoxShadow(
                    color: AppColors.yellow.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(widget.isDark ? 0.5 : 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isGrid ? 20 : 32),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.isDark
                            ? [
                                // Dark mode - Black gradient
                                Colors.black.withOpacity(0.95),
                                Colors.black87,
                                Colors.black.withOpacity(0.9),
                              ]
                            : [
                                // Light mode - White gradient
                                Colors.white.withOpacity(0.95),
                                Colors.white.withOpacity(0.9),
                                Colors.white.withOpacity(0.85),
                              ],
                      ),
                      border: Border.all(
                        color: widget.isDark 
                            ? Colors.white.withOpacity(0.1) 
                            : Colors.black.withOpacity(0.1),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Content
                        Padding(
                          padding: EdgeInsets.all(isGrid ? 16 : 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isGrid) const Spacer(flex: 1),
                              
                              // Icon - Responsive size - CENTERED
                              Container(
                                width: isGrid ? 70 : 140,
                                height: isGrid ? 70 : 140,
                                padding: EdgeInsets.all(isGrid ? 16 : 32),
                                decoration: BoxDecoration(
                                  color: widget.isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.isDark
                                          ? Colors.white.withOpacity(0.2)
                                          : Colors.black.withOpacity(0.15),
                                      blurRadius: isGrid ? 10 : 20,
                                      spreadRadius: isGrid ? 2 : 5,
                                    ),
                                  ],
                                ),
                                child: FittedBox(
                                  child: Icon(
                                    icon,
                                    color: widget.isDark 
                                        ? Colors.white 
                                        : Colors.black,
                                  ),
                                ),
                              ),

                              SizedBox(height: isGrid ? 12 : 32),

                              // Category name - Responsive - UNDER ICON
                              Flexible(
                                child: Center(
                                  child: Text(
                                    widget.category,
                                    textAlign: TextAlign.center,
                                    maxLines: isGrid ? 3 : 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: isGrid ? 16 : 28,
                                      fontWeight: FontWeight.w900,
                                      color: widget.isDark 
                                          ? Colors.white 
                                          : Colors.black,
                                      letterSpacing: 0.5,
                                      height: 1.2,
                                      shadows: [
                                        Shadow(
                                          color: widget.isDark
                                              ? Colors.black.withOpacity(0.3)
                                              : Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: isGrid ? 8 : 20),

                              // Subcategory count - Responsive
                              if (widget.subcategoryCount > 0)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isGrid ? 10 : 20,
                                    vertical: isGrid ? 5 : 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.isDark
                                        ? Colors.white.withOpacity(0.15)
                                        : Colors.black.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(isGrid ? 12 : 25),
                                    border: Border.all(
                                      color: widget.isDark
                                          ? Colors.white.withOpacity(0.3)
                                          : Colors.black.withOpacity(0.2),
                                      width: isGrid ? 1 : 2,
                                    ),
                                  ),
                                  child: Text(
                                    '${widget.subcategoryCount} ${context.locale.languageCode == 'ar' ? 'فئات' : (context.locale.languageCode == 'he' ? 'קטגוריות' : 'items')}',
                                    style: TextStyle(
                                      color: widget.isDark 
                                          ? Colors.white 
                                          : Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isGrid ? 11 : 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                              if (!isGrid) const Spacer(flex: 2),

                              // Tap hint - Only in single view
                              if (!isGrid)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.isDark
                                        ? Colors.white.withOpacity(0.15)
                                        : Colors.black.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.touch_app_rounded,
                                        color: widget.isDark 
                                            ? Colors.white 
                                            : Colors.black,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        context.locale.languageCode == 'ar'
                                            ? 'اضغط للتفاصيل'
                                            : context.locale.languageCode == 'he'
                                                ? 'הקש לפרטים'
                                              : 'Tap for details',
                                      style: TextStyle(
                                        color: widget.isDark 
                                            ? Colors.white 
                                            : Colors.black,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),
                            ],
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
      ),
    );
  }
}

// _CategoryDetailSheet removed — navigation now goes directly to the chosen page.