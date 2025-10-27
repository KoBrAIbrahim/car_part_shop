import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../user/pages/car_parts/car_parts_page.dart';

class SubcategorySelectionPage extends StatefulWidget {
  final int carId;
  final String carName;
  final String category;
  final List<String> subcategories;

  const SubcategorySelectionPage({
    super.key,
    required this.carId,
    required this.carName,
    required this.category,
    required this.subcategories,
  });

  @override
  State<SubcategorySelectionPage> createState() =>
      _SubcategorySelectionPageState();
}

class _SubcategorySelectionPageState extends State<SubcategorySelectionPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late PageController _pageController;
  int _currentPage = 0;
  bool _isGridView = false; // false = single card, true = 2 cards per row

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Build single card view (PageView)
  Widget _buildSingleView(double cardWidth, double cardHeight, bool isDark) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() => _currentPage = index);
      },
      itemCount: widget.subcategories.length,
      itemBuilder: (context, index) {
        return Center(
          child: SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: _SubcategoryCard(
              subcategoryName: widget.subcategories[index],
              categoryName: widget.category,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CarPartsPage(
                      carId: widget.carId,
                      carName: widget.carName,
                      initialCategory: widget.category,
                      initialSubcategory: widget.subcategories[index],
                    ),
                  ),
                );
              },
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
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: widget.subcategories.length,
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
            borderRadius: BorderRadius.circular(17),
            child: _SubcategoryCard(
              subcategoryName: widget.subcategories[index],
              categoryName: widget.category,
              isDark: isDark,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CarPartsPage(
                      carId: widget.carId,
                      carName: widget.carName,
                      initialCategory: widget.category,
                      initialSubcategory: widget.subcategories[index],
                    ),
                  ),
                );
              },
              isGridView: true,
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
                                  widget.category,
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
                          // Page indicator (only in single view)
                          if (!_isGridView)
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
                                '${_currentPage + 1}/${widget.subcategories.length}',
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

                    // Cards - Grid or Single View
                    Expanded(
                      child: _isGridView
                          ? _buildGridView(cardWidth, cardHeight, isDark)
                          : _buildSingleView(cardWidth, cardHeight, isDark),
                    ),

                    // Bottom hint (only in single view)
                    if (!_isGridView)
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

class _SubcategoryCard extends StatefulWidget {
  final String subcategoryName;
  final String categoryName;
  final bool isDark;
  final VoidCallback onTap;
  final bool isGridView;

  const _SubcategoryCard({
    required this.subcategoryName,
    required this.categoryName,
    required this.isDark,
    required this.onTap,
    this.isGridView = false,
  });

  @override
  State<_SubcategoryCard> createState() => _SubcategoryCardState();
}

class _SubcategoryCardState extends State<_SubcategoryCard>
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

  IconData _getSubcategoryIcon(String subcategory) {
    final subLower = subcategory.toLowerCase();

    // Transmission & Belts subcategories
    if (subLower.contains('clutch') ||
        subLower.contains('كلتش') ||
        subLower.contains('מצמד')) {
      return Icons.adjust_rounded;
    }
    if (subLower.contains('belt') ||
        subLower.contains('سير') ||
        subLower.contains('חגורה')) {
      return Icons.view_week_rounded;
    }
    if (subLower.contains('gear') ||
        subLower.contains('تروس') ||
        subLower.contains('הילוך')) {
      return Icons.settings_input_component_rounded;
    }

    // Filter subcategories
    if (subLower.contains('air filter') ||
        subLower.contains('فلتر هواء') ||
        subLower.contains('מסנן אוויר')) {
      return Icons.air_rounded;
    }
    if (subLower.contains('oil filter') ||
        subLower.contains('فلتر زيت') ||
        subLower.contains('מסנן שמן')) {
      return Icons.water_drop_rounded;
    }
    if (subLower.contains('fuel filter') ||
        subLower.contains('فلتر وقود') ||
        subLower.contains('מסנן דלק')) {
      return Icons.local_gas_station_rounded;
    }
    if (subLower.contains('filter') ||
        subLower.contains('فلتر') ||
        subLower.contains('מסנן')) {
      return Icons.filter_alt_rounded;
    }

    // Oil subcategories
    if (subLower.contains('engine oil') ||
        subLower.contains('زيت محرك') ||
        subLower.contains('שמן מנוע')) {
      return Icons.oil_barrel_rounded;
    }
    if (subLower.contains('oil') ||
        subLower.contains('زيت') ||
        subLower.contains('שמן')) {
      return Icons.opacity_rounded;
    }

    // Brake subcategories
    if (subLower.contains('brake pad') ||
        subLower.contains('فرامل') ||
        subLower.contains('רפידות בלם')) {
      return Icons.stop_circle_rounded;
    }
    if (subLower.contains('brake disc') ||
        subLower.contains('ديسك فرامل') ||
        subLower.contains('דיסק בלם')) {
      return Icons.album_rounded;
    }

    // Suspension subcategories
    if (subLower.contains('shock') ||
        subLower.contains('مساعد') ||
        subLower.contains('בולם')) {
      return Icons.swap_vert_rounded;
    }
    if (subLower.contains('spring') ||
        subLower.contains('زنبرك') ||
        subLower.contains('קפיץ')) {
      return Icons.height_rounded;
    }
    if (subLower.contains('bushing') ||
        subLower.contains('جلب') ||
        subLower.contains('תותב')) {
      return Icons.circle_outlined;
    }

    // Cooling subcategories
    if (subLower.contains('radiator') ||
        subLower.contains('رديتر') ||
        subLower.contains('רדיאטור')) {
      return Icons.device_thermostat_rounded;
    }
    if (subLower.contains('coolant') ||
        subLower.contains('سائل تبريد') ||
        subLower.contains('נוזל קירור')) {
      return Icons.ac_unit_rounded;
    }

    // Body parts
    if (subLower.contains('mirror') ||
        subLower.contains('مرآة') ||
        subLower.contains('מראה')) {
      return Icons.visibility_rounded;
    }
    if (subLower.contains('bumper') ||
        subLower.contains('صدام') ||
        subLower.contains('פגוש')) {
      return Icons.rectangle_rounded;
    }
    if (subLower.contains('door') ||
        subLower.contains('باب') ||
        subLower.contains('דלת')) {
      return Icons.meeting_room_rounded;
    }

    // Generic icons
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getSubcategoryIcon(widget.subcategoryName);
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
                    color: Colors.black
                        .withOpacity(widget.isDark ? 0.5 : 0.15),
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
                    child: Padding(
                      padding: EdgeInsets.all(isGrid ? 16 : 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isGrid) const Spacer(flex: 1),

                          // Icon - Centered
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

                          // Subcategory name - Under icon
                          Flexible(
                            child: Center(
                              child: Text(
                                widget.subcategoryName,
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

                          if (!isGrid) const SizedBox(height: 40),
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
                                        ? 'اضغط لعرض القطع'
                                        : context.locale.languageCode == 'he'
                                            ? 'הקש לצפות בחלקים'
                                            : 'Tap to view parts',
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

                          if (!isGrid) const SizedBox(height: 8),
                        ],
                      ),
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