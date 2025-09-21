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
import '../../../auth/auth_provider.dart';

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

    // Load tools when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _toolsProvider.loadTools();
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
          body: Column(
            children: [
              // Header
              _buildHeader(isDark),

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

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkCardBackground, AppColors.darkSurface]
              : [AppColors.lightCardBackground, AppColors.lightSurface],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Consumer<ToolsProvider>(
        builder: (context, provider, child) {
          final totalTools = provider.totalTools;
          final hasActiveSearch = provider.searchQuery.isNotEmpty;

          return Row(
            children: [
              // Tools Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.getPrimary(isDark).withOpacity(0.2),
                      AppColors.getPrimary(isDark).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.build_rounded,
                  color: AppColors.getPrimary(isDark),
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Title and Count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'user.tools.title'.tr(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextColor(isDark),
                      ),
                    ),
                    if (provider.hasData) ...[
                      const SizedBox(height: 4),
                      Text(
                        hasActiveSearch
                            ? '${provider.tools.length} tools found for "${provider.searchQuery}"'
                            : 'Page ${provider.currentPage + 1} of ${provider.totalPages} ($totalTools total)',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.getTextColor(
                            isDark,
                          ).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Refresh Button
              if (provider.hasData)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withOpacity(0.2),
                        AppColors.accent.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: provider.isLoading ? null : provider.refresh,
                    icon: provider.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.accent,
                              ),
                            ),
                          )
                        : Icon(Icons.refresh_rounded, color: AppColors.accent),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [AppColors.darkCardBackground, AppColors.darkSurface]
              : [AppColors.lightCardBackground, AppColors.lightSurface],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.background, AppColors.cardBackground],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.getDivider(isDark).withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.getPrimary(isDark).withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search tools...',
            hintStyle: TextStyle(
              color: AppColors.getTextColor(isDark).withOpacity(0.6),
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.getPrimary(isDark).withOpacity(0.2),
                    AppColors.getPrimary(isDark).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.search_rounded,
                color: AppColors.getPrimary(isDark),
              ),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.clear_rounded, color: AppColors.error),
                      onPressed: () {
                        _searchController.clear();
                        _toolsProvider.clearSearch();
                      },
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
          style: TextStyle(color: AppColors.getTextColor(isDark), fontSize: 16),
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
          color: AppColors.getPrimary(isDark),
          backgroundColor: AppColors.getCardBackground(isDark),
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 products per row
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75, // Adjust height ratio
            ),
            itemCount: tools.length, // Show exactly 10 items per page
            itemBuilder: (context, index) {
              final tool = tools[index];
              return Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return _buildToolCard(
                    tool: tool,
                    isDark: isDark,
                    isGarageOwner: authProvider.isGarageOwner(),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildToolCard({
    required ToolProduct tool,
    required bool isDark,
    required bool isGarageOwner,
  }) {
    return GestureDetector(
      onTap: () => _showToolDetailsModal(tool),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.cardBackground, AppColors.background],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.getDivider(isDark).withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : AppColors.getPrimary(isDark).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.getDivider(isDark).withOpacity(0.1),
                        AppColors.getDivider(isDark).withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: tool.displayImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.getPrimary(isDark),
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
                            size: 32,
                            color: AppColors.getDivider(isDark),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No Image',
                            style: TextStyle(
                              color: AppColors.getDivider(isDark),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      tool.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextColor(isDark),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Vendor
                    if (tool.vendor.isNotEmpty)
                      Text(
                        tool.vendor,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.getTextColor(
                            isDark,
                          ).withOpacity(0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const Spacer(),

                    // Price and Stock
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Expanded(
                          child: Text(
                            tool.displayPrice,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: tool.isOnSale
                                  ? AppColors.success
                                  : AppColors.getTextColor(isDark),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Stock indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tool.isInStock
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tool.isInStock ? 'In Stock' : 'Out of Stock',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: tool.isInStock
                                  ? AppColors.success
                                  : AppColors.error,
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

  void _showToolDetailsModal(ToolProduct tool) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ToolDetailsModal(tool: tool),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.getPrimary(isDark).withOpacity(0.1),
                  AppColors.getPrimary(isDark).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.getPrimary(isDark),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading tools...',
            style: TextStyle(
              color: AppColors.getTextColor(isDark),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, ToolsProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.error.withOpacity(0.1),
                  AppColors.error.withOpacity(0.05),
                ],
              ),
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
            'Error loading tools',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.error ?? 'Unknown error',
            style: TextStyle(
              color: AppColors.getTextColor(isDark).withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: provider.refresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.getPrimary(isDark),
              foregroundColor: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.getTextColor(isDark).withOpacity(0.1),
                  AppColors.getTextColor(isDark).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.build_rounded,
              size: 48,
              color: AppColors.getTextColor(isDark).withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No tools found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextColor(isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No tools are currently available',
            style: TextStyle(
              color: AppColors.getTextColor(isDark).withOpacity(0.7),
            ),
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

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.cardBackground, AppColors.background],
            ),
            border: Border(
              top: BorderSide(
                color: AppColors.getDivider(isDark).withOpacity(0.3),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous Button
              _buildPaginationButton(
                icon: Icons.chevron_left_rounded,
                label: 'Previous',
                onPressed: provider.canGoToPreviousPage && !provider.isLoading
                    ? provider.goToPreviousPage
                    : null,
                isDark: isDark,
              ),

              // Page Info and Numbers
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Page Numbers
                    ..._buildPageNumbers(provider, isDark),
                  ],
                ),
              ),

              // Next Button
              _buildPaginationButton(
                icon: Icons.chevron_right_rounded,
                label: 'Next',
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

  Widget _buildPaginationButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isDark,
  }) {
    final isEnabled = onPressed != null;

    return Container(
      decoration: BoxDecoration(
        gradient: isEnabled
            ? LinearGradient(
                colors: [
                  AppColors.getPrimary(isDark).withOpacity(0.2),
                  AppColors.getPrimary(isDark).withOpacity(0.1),
                ],
              )
            : null,
        color: !isEnabled
            ? AppColors.getDivider(isDark).withOpacity(0.1)
            : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled
              ? AppColors.getPrimary(isDark).withOpacity(0.3)
              : AppColors.getDivider(isDark).withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isEnabled
                      ? AppColors.getPrimary(isDark)
                      : AppColors.getDivider(isDark),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isEnabled
                        ? AppColors.getPrimary(isDark)
                        : AppColors.getDivider(isDark),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPageNumbers(ToolsProvider provider, bool isDark) {
    final currentPage = provider.currentPage;
    final totalPages = provider.totalPages;
    final List<Widget> pageNumbers = [];

    // Show max 5 page numbers
    int startPage = (currentPage - 2).clamp(0, totalPages - 1);
    int endPage = (startPage + 4).clamp(0, totalPages - 1);

    // Adjust start if we're near the end
    if (endPage - startPage < 4) {
      startPage = (endPage - 4).clamp(0, totalPages - 1);
    }

    for (int i = startPage; i <= endPage; i++) {
      final isCurrentPage = i == currentPage;

      pageNumbers.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: isCurrentPage
                ? LinearGradient(
                    colors: [
                      AppColors.getPrimary(isDark),
                      AppColors.getPrimary(isDark).withOpacity(0.8),
                    ],
                  )
                : null,
            color: !isCurrentPage
                ? AppColors.getDivider(isDark).withOpacity(0.1)
                : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrentPage
                  ? AppColors.getPrimary(isDark)
                  : AppColors.getDivider(isDark).withOpacity(0.3),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: provider.isLoading ? null : () => provider.goToPage(i),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: isCurrentPage
                        ? (isDark ? Colors.white : Colors.black)
                        : AppColors.getTextColor(isDark),
                    fontWeight: isCurrentPage
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return pageNumbers;
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getPrimary(isDark).withOpacity(0.1),
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
                    color: AppColors.getTextColor(isDark).withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.tool.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(isDark),
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
              color: AppColors.accent,
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
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.getTextColor(isDark),
            ),
          ),
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
        color: Colors.purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              Text(
                'Images (${availableImages.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
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
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1}/${availableImages.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple,
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
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
            style: TextStyle(
              fontSize: 16,
              color: AppColors.getTextColor(isDark).withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(bool isDark) {
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
              color: AppColors.getTextColor(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationsSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Specifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
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
                  color: AppColors.getTextColor(isDark),
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
                    color: AppColors.getTextColor(isDark),
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
                  color: AppColors.getTextColor(isDark),
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
                          ? AppColors.getTextColor(isDark)
                          : AppColors.getDivider(isDark),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        _quantity.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getTextColor(isDark),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _quantity++),
                      icon: Icon(Icons.add),
                      color: AppColors.getTextColor(isDark),
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
                    ? AppColors.primary
                    : AppColors.getDivider(isDark),
                foregroundColor: Colors.white,
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

