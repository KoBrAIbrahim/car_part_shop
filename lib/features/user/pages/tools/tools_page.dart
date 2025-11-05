import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/tools_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/api/models/tool_product.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../core/routing/app_router.dart';
import '../../widgets/app_header_widget.dart';

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late ToolsProvider _toolsProvider;

  @override
  void initState() {
    super.initState();
    _toolsProvider = Provider.of<ToolsProvider>(context, listen: false);

    // Load tools when page opens only if not already loaded from subcategory page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_toolsProvider.tools.isEmpty) {
        _toolsProvider.loadTools();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == query) {
        _toolsProvider.searchTools(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to locale changes to rebuild the widget immediately
    context.locale;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: AppColors.getBackground(isDark),
          appBar: AppHeaderWidget(
            title: 'user.tools.title',
          ),
          body: Column(
            children: [
              // Search Bar
              _buildSearchBar(isDark),

              // Tools Grid
              Expanded(child: _buildToolsGrid(isDark)),

              // Pagination Controls
              _buildPaginationControls(isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(bool isDark) {
    final textColor = AppColors.getTextColor(isDark);

    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.getCardBackground(isDark),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _searchController.text.isNotEmpty
                  ? AppColors.yellow
                  : AppColors.getDivider(isDark),
              width: 1,
            ),
            boxShadow: _searchController.text.isNotEmpty
                ? [
                    BoxShadow(
                      color: AppColors.yellow.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'user.tools.search_hint'.tr(),
              hintStyle: TextStyle(
                color: textColor.withOpacity(0.4),
                fontSize: 16,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.yellow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: AppColors.yellow,
                  size: 24,
                ),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _toolsProvider.clearSearch();
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolsGrid(bool isDark) {
    return Consumer<ToolsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !provider.hasData) {
          return _buildLoadingState(isDark);
        }

        if (provider.error != null && !provider.hasData) {
          return _buildErrorState(isDark, provider);
        }

        if (!provider.hasData) {
          return _buildEmptyState(isDark);
        }

        final tools = provider.tools;

        return RefreshIndicator(
          onRefresh: provider.refresh,
          color: AppColors.yellow,
          backgroundColor: AppColors.getCardBackground(isDark),
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 products per row
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.60, // Larger cards (taller)
            ),
            itemCount: tools.length, // Show exactly 10 items per page
            itemBuilder: (context, index) {
              final tool = tools[index];
              return _buildToolCard(tool: tool, isDark: isDark);
            },
          ),
        );
      },
    );
  }

  Widget _buildToolCard({required ToolProduct tool, required bool isDark}) {
    final cardBg = AppColors.getCardBackground(isDark);
    final textColor = AppColors.getTextColor(isDark);
    final surfaceBg = AppColors.getSurface(isDark);

    return GestureDetector(
      onTap: () {
        print('🔧 Navigating to tool details: ${tool.title}');
        print('🔧 Route: ${AppRouter.toolDetails}');
        print('🔧 Tool type: ${tool.runtimeType}');
        context.push(AppRouter.toolDetails, extra: tool);
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.getDivider(isDark)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image - LARGER SIZE
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.2, // Changed from 16/9 to make image taller
                    child: CachedNetworkImage(
                      imageUrl: tool.displayImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: surfaceBg,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.yellow,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: surfaceBg,
                        child: Center(
                          child: Icon(
                            Icons.build_rounded,
                            size: 48,
                            color: textColor.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Discount badge
                if (tool.isOnSale && tool.salePercentage > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '-${tool.salePercentage}%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Yellow line under image
            Container(
              height: 4,
              decoration: BoxDecoration(color: AppColors.yellow),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    tool.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Price and Stock Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Flexible(
                        child: tool.isOnSale
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Discounted price
                                  Text(
                                    tool.displayPrice,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  // Original price with strikethrough
                                  Text(
                                    '₪${tool.compareAtPrice!.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: textColor.withOpacity(0.5),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              )
                            : Text(
                                tool.displayPrice,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      const SizedBox(width: 6),
                      // Stock indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: tool.isInStock
                              ? AppColors.success.withOpacity(0.08)
                              : AppColors.error.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: tool.isInStock
                                ? AppColors.success
                                : AppColors.error,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          tool.isInStock
                              ? 'user.tools.in_stock'.tr()
                              : 'user.tools.out_of_stock'.tr(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: tool.isInStock
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Add to Cart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: tool.isInStock
                          ? () => _addToolToCart(tool)
                          : null,
                      icon: Icon(Icons.shopping_cart_outlined, size: 16),
                      label: Text('user.car_parts.add_to_cart'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tool.isInStock
                            ? AppColors.yellow
                            : AppColors.getDivider(isDark),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToolToCart(ToolProduct tool) async {
    try {
      // Convert ToolProduct to CarPart for cart
      // You might need to adjust this based on your actual CartService implementation
      await CartService.addToolToCart(tool, quantity: 1);

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
                    tool.title,
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
    }
  }

  Widget _buildLoadingState(bool isDark) {
    final textColor = AppColors.getTextColor(isDark);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.yellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.yellow),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'user.tools.loading'.tr(),
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, ToolsProvider provider) {
    final textColor = AppColors.getTextColor(isDark);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'user.tools.error'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.error ?? 'Unknown error',
            style: TextStyle(color: textColor.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: provider.refresh,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('user.tools.retry'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final textColor = AppColors.getTextColor(isDark);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.build_rounded,
              size: 48,
              color: textColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No tools found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No tools are currently available',
            style: TextStyle(color: textColor.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(bool isDark) {
    return Consumer<ToolsProvider>(
      builder: (context, provider, child) {
        // Don't show pagination for search results or if no data
        if (provider.searchQuery.isNotEmpty ||
            !provider.hasData ||
            provider.totalPages <= 1) {
          return const SizedBox.shrink();
        }

        final cardBg = AppColors.getCardBackground(isDark);
        final textColor = AppColors.getTextColor(isDark);
        final currentPage = provider.currentPage;
        final totalPages = provider.totalPages;

        return Container(
          width: MediaQuery.of(context).size.width * 0.9, // 90% width
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.yellow.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous button
              _buildNavigationButton(
                icon: Icons.arrow_back_ios_rounded,
                onPressed: provider.canGoToPreviousPage && !provider.isLoading
                    ? provider.goToPreviousPage
                    : null,
                isDark: isDark,
              ),

              const SizedBox(width: 4),

              // Page numbers
              ..._buildPageNumbers(
                currentPage,
                totalPages,
                provider,
                isDark,
                textColor,
              ),

              const SizedBox(width: 4),

              // Next button
              _buildNavigationButton(
                icon: Icons.arrow_forward_ios_rounded,
                onPressed: provider.canGoToNextPage && !provider.isLoading
                    ? provider.goToNextPage
                    : null,
                isDark: isDark,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isDark,
  }) {
    final isEnabled = onPressed != null;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: isEnabled
            ? AppColors.yellow.withOpacity(0.15)
            : AppColors.getDivider(isDark).withOpacity(0.1),
        shape: BoxShape.circle,
        border: isEnabled
            ? Border.all(color: AppColors.yellow.withOpacity(0.3), width: 1)
            : null,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 14,
          color: isEnabled
              ? AppColors.yellow
              : AppColors.getTextColor(isDark).withOpacity(0.3),
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  List<Widget> _buildPageNumbers(
    int currentPage,
    int totalPages,
    ToolsProvider provider,
    bool isDark,
    Color textColor,
  ) {
    List<Widget> pageWidgets = [];

    // Always show first page
    pageWidgets.add(
      _buildPageButton(
        pageNumber: 0,
        currentPage: currentPage,
        provider: provider,
        isDark: isDark,
        textColor: textColor,
      ),
    );

    if (totalPages <= 5) {
      // Show all pages if total is 5 or less
      for (int i = 1; i < totalPages; i++) {
        pageWidgets.add(const SizedBox(width: 4));
        pageWidgets.add(
          _buildPageButton(
            pageNumber: i,
            currentPage: currentPage,
            provider: provider,
            isDark: isDark,
            textColor: textColor,
          ),
        );
      }
    } else {
      // Show ellipsis logic for more than 5 pages
      if (currentPage > 1) {
        pageWidgets.add(const SizedBox(width: 4));
        pageWidgets.add(_buildEllipsis(textColor));
      }

      // Show current page only if not first or last
      if (currentPage > 0 && currentPage < totalPages - 1) {
        pageWidgets.add(const SizedBox(width: 4));
        pageWidgets.add(
          _buildPageButton(
            pageNumber: currentPage,
            currentPage: currentPage,
            provider: provider,
            isDark: isDark,
            textColor: textColor,
          ),
        );
      }

      if (currentPage < totalPages - 2) {
        pageWidgets.add(const SizedBox(width: 4));
        pageWidgets.add(_buildEllipsis(textColor));
      }

      // Always show last page
      if (totalPages > 1) {
        pageWidgets.add(const SizedBox(width: 4));
        pageWidgets.add(
          _buildPageButton(
            pageNumber: totalPages - 1,
            currentPage: currentPage,
            provider: provider,
            isDark: isDark,
            textColor: textColor,
          ),
        );
      }
    }

    return pageWidgets;
  }

  Widget _buildPageButton({
    required int pageNumber,
    required int currentPage,
    required ToolsProvider provider,
    required bool isDark,
    required Color textColor,
  }) {
    final isCurrentPage = pageNumber == currentPage;

    return GestureDetector(
      onTap: !provider.isLoading ? () => provider.goToPage(pageNumber) : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isCurrentPage
              ? Colors.transparent
              : AppColors.getDivider(isDark).withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(
            color: isCurrentPage
                ? AppColors.yellow
                : AppColors.getDivider(isDark).withOpacity(0.2),
            width: isCurrentPage ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            '${pageNumber + 1}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.w500,
              color: isCurrentPage
                  ? AppColors.yellow
                  : textColor.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis(Color textColor) {
    return Container(
      width: 26,
      height: 32,
      alignment: Alignment.center,
      child: Text(
        '...',
        style: TextStyle(
          fontSize: 13,
          color: textColor.withOpacity(0.4),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Tool Details Modal
class ToolDetailsModal extends StatefulWidget {
  final ToolProduct tool;

  const ToolDetailsModal({super.key, required this.tool});

  @override
  State<ToolDetailsModal> createState() => _ToolDetailsModalState();
}

class _ToolDetailsModalState extends State<ToolDetailsModal> {
  int _quantity = 1;
  int _currentImageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: AppColors.getCardBackground(isDark),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                _buildHeader(isDark),

                // Content
                Expanded(child: _buildContent(isDark, scrollController)),

                // Actions
                _buildActions(isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    final textColor = AppColors.getTextColor(isDark);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.yellow.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: AppColors.getDivider(isDark))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tool Details',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.tool.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: AppColors.error),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark, ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor
          if (widget.tool.vendor.isNotEmpty)
            _buildInfoCard(
              isDark: isDark,
              title: 'Vendor',
              content: widget.tool.vendor,
              icon: Icons.business,
              color: AppColors.yellow,
            ),
          if (widget.tool.vendor.isNotEmpty) const SizedBox(height: 16),

          // Description
          if (widget.tool.description.isNotEmpty)
            _buildInfoCard(
              isDark: isDark,
              title: 'Description',
              content: widget.tool.description,
              icon: Icons.description,
              color: AppColors.success,
            ),
          if (widget.tool.description.isNotEmpty) const SizedBox(height: 16),

          // Images
          _buildImageSection(isDark),
          const SizedBox(height: 16),

          // Price
          _buildPriceCard(isDark),
          const SizedBox(height: 16),

          // Specifications
          _buildSpecificationsSection(isDark),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required bool isDark,
    required String title,
    required String content,
    required IconData icon,
    required Color color,
  }) {
    final textColor = AppColors.getTextColor(isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: TextStyle(fontSize: 14, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildImageSection(bool isDark) {
    // Get all available images
    List<String> availableImages = [];

    // Add primary image
    final primaryImage = widget.tool.displayImageUrl;
    if (primaryImage.isNotEmpty) {
      availableImages.add(primaryImage);
    }

    // Add other images if available
    for (String url in widget.tool.imageUrls) {
      if (url.isNotEmpty && !availableImages.contains(url)) {
        availableImages.add(url);
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              Text(
                'Images (${availableImages.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
              const Spacer(),
              if (availableImages.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1}/${availableImages.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Show images based on availability
          if (availableImages.isEmpty)
            _buildNoImagesPlaceholder(isDark)
          else
            _buildImageSlider(availableImages, isDark),
        ],
      ),
    );
  }

  Widget _buildImageSlider(List<String> images, bool isDark) {
    return Container(
      height: 200,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentImageIndex = index;
          });
        },
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: AppColors.getDivider(isDark).withOpacity(0.1),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.info),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.getDivider(isDark).withOpacity(0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.build_rounded,
                        size: 48,
                        color: AppColors.getDivider(isDark),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Image failed to load',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.getTextColor(
                            isDark,
                          ).withOpacity(0.6),
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
    );
  }

  Widget _buildNoImagesPlaceholder(bool isDark) {
    final textColor = AppColors.getTextColor(isDark);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.getDivider(isDark).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getDivider(isDark).withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.build_rounded,
            size: 64,
            color: AppColors.getDivider(isDark),
          ),
          const SizedBox(height: 16),
          Text(
            'No images available',
            style: TextStyle(fontSize: 16, color: textColor.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(bool isDark) {
    final textColor = AppColors.getTextColor(isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_money, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Price',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.tool.displayPrice,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationsSection(bool isDark) {
    final textColor = AppColors.getTextColor(isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.yellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.yellow.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: AppColors.yellow, size: 20),
              const SizedBox(width: 8),
              Text(
                'Specifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.yellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stock status
          Row(
            children: [
              Text(
                'Stock Status: ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.tool.isInStock
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.tool.isInStock ? 'In Stock' : 'Out of Stock',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.tool.isInStock
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ),
            ],
          ),

          // Sale status
          if (widget.tool.isOnSale) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Sale: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'On Sale',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(bool isDark) {
    final textColor = AppColors.getTextColor(isDark);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Quantity selector
          Row(
            children: [
              Text(
                'Quantity:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.getDivider(isDark)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                      icon: Icon(Icons.remove),
                      color: _quantity > 1
                          ? textColor
                          : AppColors.getDivider(isDark),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _quantity.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _quantity++),
                      icon: Icon(Icons.add),
                      color: textColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Add to cart button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.tool.isInStock ? _addToCart : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.tool.isInStock
                    ? AppColors.yellow
                    : AppColors.getDivider(isDark),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                widget.tool.isInStock ? 'Add to Cart' : 'Out of Stock',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart() async {
    try {
      await CartService.addToolToCart(widget.tool, quantity: _quantity);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.tool.title} (×$_quantity) added to cart'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'VIEW CART',
            textColor: Colors.white,
            onPressed: () => context.go('/cart'),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding to cart: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
