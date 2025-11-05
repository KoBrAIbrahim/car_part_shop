import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/sales_provider.dart';
import '../../../../core/api/models/car_part.dart';
import '../../../../core/api/models/tool_product.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/cart_service.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SalesProvider>(context, listen: false);
      provider.loadSaleCarParts();
      provider.loadSaleTools();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      body: SafeArea(
        child: Column(
          children: [
            // TabBar only (no header)
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 16,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: AppColors.getCardBackground(isDark),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.getDivider(isDark)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.black,
                unselectedLabelColor: AppColors.getTextColor(isDark),
                indicator: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.all(4),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.directions_car_rounded),
                    text: 'user.sales.car_parts'.tr(),
                  ),
                  Tab(
                    icon: const Icon(Icons.build_rounded),
                    text: 'user.sales.tools'.tr(),
                  ),
                ],
              ),
            ),

            // TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CarPartsTab(isTablet: isTablet),
                  _ToolsTab(isTablet: isTablet),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Car Parts Tab Widget
class _CarPartsTab extends StatelessWidget {
  final bool isTablet;

  const _CarPartsTab({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Consumer<SalesProvider>(
      builder: (context, salesProvider, child) {
        if (salesProvider.isLoadingCarParts) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.yellow),
                ),
                const SizedBox(height: 16),
                Text(
                  'common.loading'.tr(),
                  style: TextStyle(
                    color: AppColors.getTextColor(isDark),
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ],
            ),
          );
        }

        if (salesProvider.carPartsError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: isTablet ? 64 : 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  salesProvider.carPartsError!,
                  style: TextStyle(
                    color: AppColors.getTextColor(isDark),
                    fontSize: isTablet ? 16 : 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => salesProvider.loadSaleCarParts(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text('common.retry'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          );
        }

        if (salesProvider.saleCarParts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: isTablet ? 80 : 64,
                  color: AppColors.getTextColor(isDark).withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'user.sales.no_car_parts'.tr(),
                  style: TextStyle(
                    color: AppColors.getTextColor(isDark),
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Total items info
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 16,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Text(
                    '${'user.sales.total_items'.tr()}: ${salesProvider.totalCarParts}',
                    style: TextStyle(
                      color: AppColors.getTextColor(isDark).withOpacity(0.7),
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Grid of car parts
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : 16,
                  vertical: 8,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: salesProvider.saleCarParts.length,
                itemBuilder: (context, index) {
                  final part = salesProvider.saleCarParts[index];
                  return _CarPartCard(part: part, isTablet: isTablet);
                },
              ),
            ),

            // Pagination
            if (salesProvider.totalCarPartsPages > 1)
              _buildCarPartsPagination(context, salesProvider, isDark),
          ],
        );
      },
    );
  }

  Widget _buildCarPartsPagination(
    BuildContext context,
    SalesProvider provider,
    bool isDark,
  ) {
    final pages = _getPageNumbers(
      provider.currentCarPartsPage,
      provider.totalCarPartsPages,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        border: Border(top: BorderSide(color: AppColors.getDivider(isDark))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          IconButton(
            onPressed: provider.canGoToPreviousCarPartsPage
                ? () => provider.goToPreviousCarPartsPage()
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.yellow,
            disabledColor: AppColors.getTextColor(isDark).withOpacity(0.3),
          ),

          // Page numbers
          ...pages.map((page) {
            if (page == -1) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '...',
                  style: TextStyle(
                    color: AppColors.getTextColor(isDark),
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              );
            }

            final isCurrentPage = page == provider.currentCarPartsPage;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => provider.goToCarPartsPage(page),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: isTablet ? 40 : 36,
                  height: isTablet ? 40 : 36,
                  decoration: BoxDecoration(
                    color: isCurrentPage
                        ? AppColors.yellow
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrentPage
                          ? AppColors.yellow
                          : AppColors.getDivider(isDark),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    page.toString(),
                    style: TextStyle(
                      color: isCurrentPage
                          ? Colors.black
                          : AppColors.getTextColor(isDark),
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: isCurrentPage
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }),

          // Next button
          IconButton(
            onPressed: provider.canGoToNextCarPartsPage
                ? () => provider.goToNextCarPartsPage()
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppColors.yellow,
            disabledColor: AppColors.getTextColor(isDark).withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

// Car Part Card Widget
class _CarPartCard extends StatefulWidget {
  final CarPart part;
  final bool isTablet;

  const _CarPartCard({required this.part, required this.isTablet});

  @override
  State<_CarPartCard> createState() => _CarPartCardState();
}

class _CarPartCardState extends State<_CarPartCard> {
  bool _adding = false;

  Future<void> _addToCart() async {
    if (_adding) return;
    setState(() => _adding = true);
    try {
      await CartService.addToCart(
        widget.part,
        carMake: widget.part.displayBrand,
        quantity: 1,
      );

      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          // Auto-close after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (Navigator.canPop(dialogContext)) {
              Navigator.of(dialogContext).pop();
            }
          });

          final isDark = Provider.of<ThemeProvider>(
            context,
            listen: false,
          ).isDarkMode;

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.getCardBackground(isDark),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yellow.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 50,
                      color: AppColors.yellow,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Success message
                  Text(
                    'user.car_parts.added_to_cart'.tr(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextColor(isDark),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Product name
                  Text(
                    widget.part.displayTitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.getTextColor(isDark).withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Quantity
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.yellow.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '${'user.car_parts.quantity'.tr()}: 1',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextColor(isDark),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // View Cart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        context.go('/cart');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'user.car_parts.view_cart'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('user.car_parts.error_adding_to_cart'.tr()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return GestureDetector(
      onTap: () {
        context.push(AppRouter.partDetails, extra: widget.part);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.getDivider(isDark)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with discount badge
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                    child: widget.part.displayImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: widget.part.displayImageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.getBackground(isDark),
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.yellow,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.getBackground(isDark),
                              child: Icon(
                                Icons.directions_car_rounded,
                                color: AppColors.getTextColor(
                                  isDark,
                                ).withOpacity(0.3),
                                size: 48,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.getBackground(isDark),
                            child: Icon(
                              Icons.directions_car_rounded,
                              color: AppColors.getTextColor(
                                isDark,
                              ).withOpacity(0.3),
                              size: 48,
                            ),
                          ),
                  ),
                  // Discount badge
                  if (widget.part.isOnSale &&
                      widget.part.shopifyProduct != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${widget.part.getSalePercentage(isGarageOwner: false)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Part number / title
                    Flexible(
                      child: Text(
                        widget.part.displayTitle,
                        style: TextStyle(
                          color: AppColors.getTextColor(isDark),
                          fontSize: widget.isTablet ? 14 : 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const Spacer(),

                    // Price and Add to Cart button row
                    Row(
                      children: [
                        // Price with discount
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.part.isOnSale &&
                                  widget.part.compareAtPrice != null) ...[
                                Text(
                                  '₪${widget.part.compareAtPrice!.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: AppColors.getTextColor(
                                      isDark,
                                    ).withOpacity(0.5),
                                    fontSize: widget.isTablet ? 11 : 10,
                                    decoration: TextDecoration.lineThrough,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                widget.part.getPrice(isGarageOwner: false),
                                style: TextStyle(
                                  color: widget.part.isOnSale
                                      ? Colors.red
                                      : AppColors.yellow,
                                  fontSize: widget.isTablet ? 15 : 14,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Add to cart button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _adding ? null : _addToCart,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _adding
                                    ? AppColors.yellow.withOpacity(0.5)
                                    : AppColors.yellow,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _adding
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.black,
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.add_shopping_cart_rounded,
                                      size: 18,
                                      color: Colors.black,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tools Tab Widget
class _ToolsTab extends StatelessWidget {
  final bool isTablet;

  const _ToolsTab({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Consumer<SalesProvider>(
      builder: (context, salesProvider, child) {
        if (salesProvider.isLoadingTools) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.yellow),
                ),
                const SizedBox(height: 16),
                Text(
                  'common.loading'.tr(),
                  style: TextStyle(
                    color: AppColors.getTextColor(isDark),
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ],
            ),
          );
        }

        if (salesProvider.toolsError != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: isTablet ? 64 : 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  salesProvider.toolsError!,
                  style: TextStyle(
                    color: AppColors.getTextColor(isDark),
                    fontSize: isTablet ? 16 : 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => salesProvider.loadSaleTools(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text('common.retry'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          );
        }

        if (salesProvider.saleTools.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_offer_outlined,
                  size: isTablet ? 80 : 64,
                  color: AppColors.getTextColor(isDark).withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'user.sales.no_tools'.tr(),
                  style: TextStyle(
                    color: AppColors.getTextColor(isDark),
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Total items info
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 16,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Text(
                    '${'user.sales.total_items'.tr()}: ${salesProvider.totalTools}',
                    style: TextStyle(
                      color: AppColors.getTextColor(isDark).withOpacity(0.7),
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Grid of tools
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : 16,
                  vertical: 8,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: salesProvider.saleTools.length,
                itemBuilder: (context, index) {
                  final tool = salesProvider.saleTools[index];
                  return _ToolCard(tool: tool, isTablet: isTablet);
                },
              ),
            ),

            // Pagination
            if (salesProvider.totalToolsPages > 1)
              _buildToolsPagination(context, salesProvider, isDark),
          ],
        );
      },
    );
  }

  Widget _buildToolsPagination(
    BuildContext context,
    SalesProvider provider,
    bool isDark,
  ) {
    final pages = _getPageNumbers(
      provider.currentToolsPage,
      provider.totalToolsPages,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        border: Border(top: BorderSide(color: AppColors.getDivider(isDark))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          IconButton(
            onPressed: provider.canGoToPreviousToolsPage
                ? () => provider.goToPreviousToolsPage()
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
            color: AppColors.yellow,
            disabledColor: AppColors.getTextColor(isDark).withOpacity(0.3),
          ),

          // Page numbers
          ...pages.map((page) {
            if (page == -1) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '...',
                  style: TextStyle(
                    color: AppColors.getTextColor(isDark),
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              );
            }

            final isCurrentPage = page == provider.currentToolsPage;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => provider.goToToolsPage(page),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: isTablet ? 40 : 36,
                  height: isTablet ? 40 : 36,
                  decoration: BoxDecoration(
                    color: isCurrentPage
                        ? AppColors.yellow
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrentPage
                          ? AppColors.yellow
                          : AppColors.getDivider(isDark),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    page.toString(),
                    style: TextStyle(
                      color: isCurrentPage
                          ? Colors.black
                          : AppColors.getTextColor(isDark),
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: isCurrentPage
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }),

          // Next button
          IconButton(
            onPressed: provider.canGoToNextToolsPage
                ? () => provider.goToNextToolsPage()
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
            color: AppColors.yellow,
            disabledColor: AppColors.getTextColor(isDark).withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

// Tool Card Widget
// Tool Card Widget
class _ToolCard extends StatefulWidget {
  final ToolProduct tool;
  final bool isTablet;

  const _ToolCard({required this.tool, required this.isTablet});

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard> {
  bool _adding = false;

  Future<void> _addToCart() async {
    if (_adding) return;
    setState(() => _adding = true);
    try {
      await CartService.addToolToCart(widget.tool, quantity: 1);

      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          // Auto-close after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (Navigator.canPop(dialogContext)) {
              Navigator.of(dialogContext).pop();
            }
          });

          final isDark = Provider.of<ThemeProvider>(
            context,
            listen: false,
          ).isDarkMode;

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.getCardBackground(isDark),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yellow.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 50,
                      color: AppColors.yellow,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Success message
                  Text(
                    'user.car_parts.added_to_cart'.tr(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextColor(isDark),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Product name
                  Text(
                    widget.tool.title,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.getTextColor(isDark).withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Quantity
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.yellow.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '${'user.car_parts.quantity'.tr()}: 1',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextColor(isDark),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // View Cart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        context.go('/cart');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'user.car_parts.view_cart'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('user.car_parts.error_adding_to_cart'.tr()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final discountPercentage = widget.tool.salePercentage;

    return GestureDetector(
      onTap: () {
        context.push(AppRouter.toolDetails, extra: widget.tool);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.getDivider(isDark)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with discount badge
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: widget.tool.imageUrls.isNotEmpty
                          ? widget.tool.imageUrls.first
                          : 'https://via.placeholder.com/150',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.getBackground(isDark),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.yellow,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.getBackground(isDark),
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          color: AppColors.getTextColor(
                            isDark,
                          ).withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                  // Discount badge
                  if (discountPercentage > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-${discountPercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    Flexible(
                      child: Text(
                        widget.tool.title,
                        style: TextStyle(
                          color: AppColors.getTextColor(isDark),
                          fontSize: widget.isTablet ? 14 : 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const Spacer(),

                    // Price and Add to Cart button row
                    Row(
                      children: [
                        // Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.tool.isOnSale &&
                                  widget.tool.compareAtPrice != null) ...[
                                Text(
                                  '\$${widget.tool.compareAtPrice!.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: AppColors.getTextColor(
                                      isDark,
                                    ).withOpacity(0.5),
                                    fontSize: widget.isTablet ? 11 : 10,
                                    decoration: TextDecoration.lineThrough,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                '\$${widget.tool.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: widget.tool.isOnSale
                                      ? Colors.red
                                      : AppColors.yellow,
                                  fontSize: widget.isTablet ? 15 : 14,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Add to cart button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _adding ? null : _addToCart,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _adding
                                    ? AppColors.yellow.withOpacity(0.5)
                                    : AppColors.yellow,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _adding
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.black,
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.add_shopping_cart_rounded,
                                      size: 18,
                                      color: Colors.black,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to get page numbers for pagination
List<int> _getPageNumbers(int currentPage, int totalPages) {
  if (totalPages <= 7) {
    return List.generate(totalPages, (i) => i + 1);
  }

  if (currentPage <= 4) {
    return [1, 2, 3, 4, 5, -1, totalPages];
  }

  if (currentPage >= totalPages - 3) {
    return [
      1,
      -1,
      totalPages - 4,
      totalPages - 3,
      totalPages - 2,
      totalPages - 1,
      totalPages,
    ];
  }

  return [1, -1, currentPage - 1, currentPage, currentPage + 1, -1, totalPages];
}
