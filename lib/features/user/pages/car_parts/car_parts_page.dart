import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/car_parts_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/api/models/car_part.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/services/part_compatibility_service.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../../auth/auth_provider.dart';
import 'car_parts_filter_sheet.dart';
import 'car_parts_header.dart';
import 'car_parts_pagination.dart';

class CarPartsPage extends StatefulWidget {
  final int carId;
  final String carName;

  const CarPartsPage({super.key, required this.carId, required this.carName});

  @override
  State<CarPartsPage> createState() => _CarPartsPageState();
}

class _CarPartsPageState extends State<CarPartsPage> {
  final TextEditingController _searchController = TextEditingController();
  late CarPartsProvider _partsProvider;

  // Filter and sort state
  String _selectedCategory = 'All';
  String _sortBy = 'name';
  bool _sortAscending = true;
  List<String> _availableCategories = ['All'];

  @override
  void initState() {
    super.initState();
    _partsProvider = Provider.of<CarPartsProvider>(context, listen: false);

    // Load parts when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _partsProvider.loadPartsForCar(widget.carId);
    });

    // Listen to provider changes to extract categories
    _partsProvider.addListener(_onProviderDataChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _partsProvider.removeListener(_onProviderDataChanged);
    super.dispose();
  }

  void _onProviderDataChanged() {
    if (_partsProvider.allParts.isNotEmpty &&
        _availableCategories.length == 1) {
      _extractCategoriesFromProviderData();
    }
  }

  void _extractCategoriesFromProviderData() {
    final categories = _partsProvider.allParts
        .map((part) => part.displayCategory)
        .toSet()
        .toList();
    categories.sort();

    final newCategories = ['All', ...categories];

    if (_availableCategories.length != newCategories.length ||
        !_availableCategories.every((cat) => newCategories.contains(cat))) {
      setState(() {
        _availableCategories = newCategories;
      });
    }
  }

  void _onSearchChanged(String query) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_searchController.text == query) {
        _partsProvider.searchParts(query);
      }
    });
  }

  List<CarPart> _getFilteredAndSortedParts(List<CarPart> parts) {
    List<CarPart> filtered = parts;
    if (_selectedCategory != 'All') {
      filtered = parts
          .where((part) => part.displayCategory == _selectedCategory)
          .toList();
    }

    filtered.sort((a, b) {
      int comparison;
      if (_sortBy == 'name') {
        comparison = a.displayTitle.compareTo(b.displayTitle);
      } else {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isGarage = authProvider.isGarageOwner();

        double priceA = _getPartPriceForSorting(a, isGarage);
        double priceB = _getPartPriceForSorting(b, isGarage);

        comparison = priceA.compareTo(priceB);
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  double _getPartPriceForSorting(CarPart part, bool isGarage) {
    if (part.shopifyProduct != null) {
      final shopifyProduct = part.shopifyProduct!;

      if (isGarage && shopifyProduct.garagePrice != null) {
        final gPrice = double.tryParse(shopifyProduct.garagePrice!) ?? 0.0;
        if (gPrice > 0) {
          return gPrice;
        }
      }

      return shopifyProduct.price;
    }

    return part.price ?? 0.0;
  }

  void _showFilterSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CarPartsFilterSheet(
        selectedCategory: _selectedCategory,
        sortBy: _sortBy,
        sortAscending: _sortAscending,
        availableCategories: _availableCategories,
        onApply: (category, sortBy, sortAscending) {
          setState(() {
            _selectedCategory = category;
            _sortBy = sortBy;
            _sortAscending = sortAscending;
          });
        },
      ),
    );
  }

  void _showCacheManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => _CacheManagementDialog(carId: widget.carId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: AppColors.getBackground(isDark),
          body: Column(
            children: [
              // Header Widget
              Consumer<CarPartsProvider>(
                builder: (context, provider, child) {
                  final filteredParts = _getFilteredAndSortedParts(
                    provider.parts,
                  );
                  final totalParts = filteredParts.length;
                  final hasActiveFilters =
                      _selectedCategory != 'All' ||
                      provider.searchQuery.isNotEmpty;

                  return CarPartsHeader(
                    carName: widget.carName,
                    totalParts: totalParts,
                    isLoading: provider.isLoading && provider.parts.isEmpty,
                    onFilterPressed: _showFilterSortBottomSheet,
                    hasActiveFilters: hasActiveFilters,
                    onCacheManagePressed: _showCacheManagementDialog,
                  );
                },
              ),

              // Search Bar
              _buildSearchBar(isDark),

              // Parts Grid with Pagination
              Expanded(
                child: Column(
                  children: [
                    // Parts Grid
                    Expanded(child: _buildPartsGrid(isDark)),

                    // Pagination Controls
                    Consumer<CarPartsProvider>(
                      builder: (context, provider, child) {
                        return CarPartsPagination(
                          currentPage: provider.currentPage,
                          totalPages: provider.totalPages,
                          isLoading: provider.isLoading,
                          onPreviousPage: provider.canGoToPreviousPage
                              ? provider.goToPreviousPage
                              : null,
                          onNextPage: provider.canGoToNextPage
                              ? provider.goToNextPage
                              : null,
                          onPageSelected: provider.goToPage,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: AppBottomNavigationBar(currentIndex: 0),
        );
      },
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.1)
                : Colors.grey.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getBackground(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.getDivider(isDark)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: tr('user.car_parts.search_hint'),
            hintStyle: TextStyle(
              color: AppColors.getTextColor(isDark).withOpacity(0.6),
            ),
            prefixIcon: Icon(Icons.search, color: AppColors.getPrimary(isDark)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: AppColors.error),
                    onPressed: () {
                      _searchController.clear();
                      _partsProvider.clearSearch();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: TextStyle(color: AppColors.getTextColor(isDark), fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildPartsGrid(bool isDark) {
    return Consumer<CarPartsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && !provider.hasData) {
          return _buildLoadingState(isDark);
        }

        if (provider.error != null && !provider.hasData) {
          return _buildErrorState(isDark, provider);
        }

        if (!provider.hasData) {
          return _buildEmptyState(isDark, provider);
        }

        final filteredParts = _getFilteredAndSortedParts(provider.parts);

        if (filteredParts.isEmpty && provider.parts.isNotEmpty) {
          return _buildNoFilterResultsState(isDark);
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Clear cache and refresh data
            await CacheService.clearCarCache(widget.carId);
            await provider.refresh(forceRefresh: true);

            // Show a brief message to user
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🔄 Cache cleared and data refreshed'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          color: AppColors.getPrimary(isDark),
          backgroundColor: AppColors.getCardBackground(isDark),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.70,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: filteredParts.length,
            itemBuilder: (context, index) {
              final part = filteredParts[index];
              return Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return _buildPartCard(
                    part: part,
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

  Widget _buildPartCard({
    required CarPart part,
    required bool isDark,
    required bool isGarageOwner,
  }) {
    return GestureDetector(
      onTap: () => _showPartDetails(part),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.getDivider(isDark)),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.getBackground(isDark),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: _buildPartImage(part, isDark),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Flexible(
                      child: Text(
                        part.displayTitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextColor(isDark),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Part Number
                    Text(
                      part.partNumber,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.getTextColor(isDark).withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Stock quantity
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 12,
                          color: part.isInStock
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStockText(part),
                          style: TextStyle(
                            fontSize: 10,
                            color: part.isInStock
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Price section with sale support
                    Flexible(
                      child: _buildPriceSection(part, isGarageOwner, isDark),
                    ),

                    const SizedBox(height: 4),

                    // Add to Cart Button
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: part.isInStock
                            ? () => _addToCart(part)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: part.isInStock
                              ? AppColors.getPrimary(isDark)
                              : AppColors.getDivider(isDark),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          part.isInStock ? 'Add to Cart' : 'Out of Stock',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.getPrimary(isDark)),
          const SizedBox(height: 16),
          Text(
            tr('user.car_parts.loading_parts'),
            style: TextStyle(
              color: AppColors.getTextColor(isDark),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, CarPartsProvider provider) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              tr('user.car_parts.error_loading_parts'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextColor(isDark),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextColor(isDark).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: provider.refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.getPrimary(isDark),
                foregroundColor: Colors.white,
              ),
              child: Text(tr('user.home.retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, CarPartsProvider provider) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.getDivider(isDark)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: AppColors.getTextColor(isDark).withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              tr('user.car_parts.no_parts_found'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextColor(isDark),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              provider.searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'No parts available for this car',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextColor(isDark).withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFilterResultsState(bool isDark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list_off, size: 48, color: AppColors.warning),
            const SizedBox(height: 16),
            Text(
              'No parts match your filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextColor(isDark),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filter settings',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextColor(isDark).withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = 'All';
                  _sortBy = 'name';
                  _sortAscending = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  String _getStockText(CarPart part) {
    if (!part.isInStock) {
      return 'Out of Stock';
    }

    // For now, just show In Stock or Out of Stock
    // TODO: Add proper stock quantity when available in the model
    return 'In Stock';
  }

  Widget _buildPartImage(CarPart part, bool isDark) {
    // Debug print to understand image availability
    print('🖼️ [IMAGE_DEBUG] Part: ${part.partNumber}');
    print(
      '🖼️ [IMAGE_DEBUG] Has Shopify Product: ${part.shopifyProduct != null}',
    );
    print(
      '🖼️ [IMAGE_DEBUG] All Image URLs count: ${part.allImageUrls.length}',
    );
    print('🖼️ [IMAGE_DEBUG] Display Image URL: ${part.displayImageUrl}');
    if (part.allImageUrls.isNotEmpty) {
      print('🖼️ [IMAGE_DEBUG] First image URL: ${part.allImageUrls.first}');
    }

    // Try multiple image sources in order of preference
    String? imageUrl;

    // First try: get from allImageUrls (Shopify images)
    if (part.allImageUrls.isNotEmpty) {
      imageUrl = part.allImageUrls.first;
      print('🖼️ [IMAGE_DEBUG] Using allImageUrls.first: $imageUrl');
    }
    // Second try: get from displayImageUrl (primary image)
    else if (part.displayImageUrl != null && part.displayImageUrl!.isNotEmpty) {
      imageUrl = part.displayImageUrl;
      print('🖼️ [IMAGE_DEBUG] Using displayImageUrl: $imageUrl');
    }
    // Third try: get from Shopify primary image
    else if (part.shopifyProduct?.primaryImageUrl != null) {
      imageUrl = part.shopifyProduct!.primaryImageUrl;
      print(
        '🖼️ [IMAGE_DEBUG] Using shopifyProduct.primaryImageUrl: $imageUrl',
      );
    }
    // Fourth try: get from legacy imageUrl field
    else if (part.imageUrl != null && part.imageUrl!.isNotEmpty) {
      imageUrl = part.imageUrl;
      print('🖼️ [IMAGE_DEBUG] Using legacy imageUrl: $imageUrl');
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => Container(
          color: AppColors.getDivider(isDark).withOpacity(0.1),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) {
          print('🖼️ [IMAGE_ERROR] Failed to load image: $url, Error: $error');
          return Container(
            color: AppColors.getDivider(isDark).withOpacity(0.1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.settings,
                  size: 40,
                  color: AppColors.getDivider(isDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'No Image',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.getDivider(isDark),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // No image available - show placeholder
    print('🖼️ [IMAGE_DEBUG] No image available, showing placeholder');
    return Container(
      color: AppColors.getDivider(isDark).withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 40, color: AppColors.getDivider(isDark)),
          const SizedBox(height: 4),
          Text(
            'No Image',
            style: TextStyle(fontSize: 10, color: AppColors.getDivider(isDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(CarPart part, bool isGarageOwner, bool isDark) {
    final hasSale = part.hasSalePrice(isGarageOwner: isGarageOwner);
    final currentPrice = part.getPrice(isGarageOwner: isGarageOwner);

    if (!hasSale) {
      // No sale - show current price only
      return Text(
        currentPrice,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.getPrimary(isDark),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // On sale - show everything in one compact row
    final originalPrice = part.shopifyProduct?.compareAtPrice != null
        ? '₪${part.shopifyProduct!.compareAtPrice!.toStringAsFixed(0)}'
        : currentPrice;
    final salePercentage = part.getSalePercentage(isGarageOwner: isGarageOwner);

    return Row(
      children: [
        // Sale badge
        if (salePercentage > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              '-${salePercentage}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],

        // Original price (crossed out)
        Text(
          originalPrice,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.getTextColor(isDark).withOpacity(0.6),
            decoration: TextDecoration.lineThrough,
          ),
        ),

        const SizedBox(width: 6),

        // Sale price
        Expanded(
          child: Text(
            currentPrice,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _addToCart(CarPart part) async {
    try {
      final carParts = widget.carName.split(' ');
      final carMake = carParts.isNotEmpty ? carParts[0] : 'Unknown';
      final carModel = carParts.length > 1 ? carParts[1] : null;
      final carYear = carParts.length > 2 ? carParts[2] : null;

      await CartService.addToCart(
        part,
        carMake: carMake,
        carModel: carModel,
        carYear: carYear,
        quantity: 1,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${part.displayTitle} added to cart'),
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

  void _showPartDetails(CarPart part) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) =>
          CarPartDetailsModal(part: part, carName: widget.carName),
    );
  }
}

// Simplified Car Part Details Modal
class CarPartDetailsModal extends StatefulWidget {
  final CarPart part;
  final String carName;

  const CarPartDetailsModal({
    super.key,
    required this.part,
    required this.carName,
  });

  @override
  State<CarPartDetailsModal> createState() => _CarPartDetailsModalState();
}

class _CarPartDetailsModalState extends State<CarPartDetailsModal> {
  int _quantity = 1;
  int _currentImageIndex = 0;
  late PageController _pageController;

  // Compatible cars data
  List<CompatibleCar> _compatibleCars = [];
  PartCompatibilityStats? _compatibilityStats;
  bool _isLoadingCompatibleCars = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadCompatibleCars();
  }

  void _loadCompatibleCars() async {
    setState(() {
      _isLoadingCompatibleCars = true;
    });

    try {
      final cars = await PartCompatibilityService.getCarsForPart(
        widget.part.partNumber,
      );
      final stats = await PartCompatibilityService.getPartCompatibilityStats(
        widget.part.partNumber,
      );

      if (mounted) {
        setState(() {
          _compatibleCars = cars;
          _compatibilityStats = stats;
          _isLoadingCompatibleCars = false;
        });
      }
    } catch (e) {
      print('Error loading compatible cars: $e');
      if (mounted) {
        setState(() {
          _isLoadingCompatibleCars = false;
        });
      }
    }
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
                  'Part Details',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.getTextColor(isDark).withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.part.partNumber,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextColor(isDark),
                  ),
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
          // Title
          _buildInfoCard(
            isDark: isDark,
            title: 'Title',
            content: widget.part.displayTitle,
            icon: Icons.title,
            color: AppColors.accent,
          ),

          const SizedBox(height: 16),

          // Description
          _buildInfoCard(
            isDark: isDark,
            title: 'Description',
            content: widget.part.displayDescription,
            icon: Icons.description,
            color: AppColors.success,
          ),

          const SizedBox(height: 16),

          // Images - always show section with better fallback handling
          _buildImageSection(isDark),

          const SizedBox(height: 16),

          // Price
          _buildPriceCard(isDark),

          const SizedBox(height: 16),

          // Compatible Cars
          _buildCompatibleCarsSection(isDark),
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
    // Get all available images from multiple sources
    List<String> availableImages = [];

    // Add Shopify images
    if (widget.part.shopifyProduct?.imageUrls != null) {
      availableImages.addAll(widget.part.shopifyProduct!.imageUrls);
    }

    // Add primary image if not already in list
    final primaryImage = widget.part.displayImageUrl;
    if (primaryImage != null &&
        primaryImage.isNotEmpty &&
        !availableImages.contains(primaryImage)) {
      availableImages.insert(0, primaryImage);
    }

    // Add legacy image URL if not already in list
    if (widget.part.imageUrl != null &&
        widget.part.imageUrl!.isNotEmpty &&
        !availableImages.contains(widget.part.imageUrl!)) {
      availableImages.add(widget.part.imageUrl!);
    }

    // Remove duplicates and empty URLs
    availableImages = availableImages
        .where((url) => url.isNotEmpty)
        .toSet()
        .toList();

    print('🖼️ [DETAILS_DEBUG] Part: ${widget.part.partNumber}');
    print('🖼️ [DETAILS_DEBUG] Available images: ${availableImages.length}');

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
    return Column(
      children: [
        // Main image slider
        Container(
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
              return GestureDetector(
                onTap: () => _openFullScreenImage(images, index),
                child: Container(
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
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: images[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => Container(
                            color: AppColors.getDivider(
                              isDark,
                            ).withOpacity(0.1),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.purple,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.getDivider(
                              isDark,
                            ).withOpacity(0.1),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
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
                        // Zoom indicator
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Dots indicator for multiple images
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: images.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    entry.key,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == entry.key
                        ? Colors.purple
                        : Colors.purple.withOpacity(0.3),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _openFullScreenImage(List<String> images, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, _, __) => FullScreenImageViewer(
          images: images,
          initialIndex: initialIndex,
          partNumber: widget.part.partNumber,
        ),
      ),
    );
  }

  Widget _buildNoImagesPlaceholder(bool isDark) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.getDivider(isDark).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getDivider(isDark).withOpacity(0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: AppColors.getDivider(isDark),
            ),
            const SizedBox(height: 8),
            Text(
              'No images available',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextColor(isDark).withOpacity(0.6),
              ),
            ),
          ],
        ),
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
              Icon(Icons.monetization_on, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pricing Information',
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
            _getPriceDisplay(),
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

  Widget _buildCompatibleCarsSection(bool isDark) {
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
              Icon(Icons.directions_car, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Compatible Cars',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (_isLoadingCompatibleCars) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          if (_isLoadingCompatibleCars)
            Text(
              'Loading compatible cars...',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextColor(isDark).withOpacity(0.8),
              ),
            )
          else if (_compatibleCars.isEmpty)
            Text(
              'No compatibility data available for this part.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.getTextColor(isDark).withOpacity(0.8),
              ),
            )
          else ...[
            // Summary stats
            if (_compatibilityStats != null &&
                _compatibilityStats!.hasData) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Text(
                  _compatibilityStats!.summary,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Car list
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _compatibleCars.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final car = _compatibleCars[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.getCardBackground(isDark),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.getDivider(isDark).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_car_filled,
                          size: 16,
                          color: AppColors.getTextColor(
                            isDark,
                          ).withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            car.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.getTextColor(isDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            if (_compatibleCars.length > 10) ...[
              const SizedBox(height: 8),
              Text(
                'Showing first 10 of ${_compatibleCars.length} compatible cars',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.getTextColor(isDark).withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildActions(bool isDark) {
    return Column(
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
            onPressed: widget.part.isInStock ? _addToCart : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.part.isInStock
                  ? AppColors.primary
                  : AppColors.getDivider(isDark),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              widget.part.isInStock ? 'Add to Cart' : 'Out of Stock',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  String _getPriceDisplay() {
    if (widget.part.shopifyProduct != null) {
      final shopifyProduct = widget.part.shopifyProduct!;
      final price = shopifyProduct.price;
      return '₪${price.toStringAsFixed(0)}';
    }

    if (widget.part.price != null) {
      return '₪${widget.part.price!.toStringAsFixed(0)}';
    }

    return 'Price on request';
  }

  void _addToCart() async {
    try {
      final carParts = widget.carName.split(' ');
      final carMake = carParts.isNotEmpty ? carParts[0] : 'Unknown';
      final carModel = carParts.length > 1 ? carParts[1] : null;
      final carYear = carParts.length > 2 ? carParts[2] : null;

      await CartService.addToCart(
        widget.part,
        carMake: carMake,
        carModel: carModel,
        carYear: carYear,
        quantity: _quantity,
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.part.displayTitle} (×$_quantity) added to cart',
          ),
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

class FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String partNumber;

  const FullScreenImageViewer({
    Key? key,
    required this.images,
    required this.initialIndex,
    required this.partNumber,
  }) : super(key: key);

  @override
  _FullScreenImageViewerState createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentIndex + 1}/${widget.images.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: widget.images[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 64,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
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

          // Part number overlay
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Part: ${widget.partNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Dots indicator for multiple images
          if (widget.images.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.images.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == entry.key
                          ? Colors.white
                          : Colors.white54,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// Cache Management Dialog Widget
class _CacheManagementDialog extends StatefulWidget {
  final int carId;

  const _CacheManagementDialog({required this.carId});

  @override
  State<_CacheManagementDialog> createState() => _CacheManagementDialogState();
}

class _CacheManagementDialogState extends State<_CacheManagementDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return AlertDialog(
          backgroundColor: AppColors.getSurface(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.storage_rounded, color: AppColors.accent, size: 24),
              const SizedBox(width: 12),
              Text(
                'Cache Management',
                style: TextStyle(
                  color: AppColors.getTextColor(isDark),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manage cached data to free up storage or refresh outdated information.',
                style: TextStyle(
                  color: AppColors.getTextColor(isDark).withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // Cache Options
              _buildCacheOption(
                isDark: isDark,
                icon: Icons.refresh_rounded,
                title: 'Refresh Current Car Parts',
                subtitle: 'Reload parts for this specific car',
                color: AppColors.accent,
                onTap: () => _refreshCurrentCarCache(isDark),
              ),

              const SizedBox(height: 12),

              _buildCacheOption(
                isDark: isDark,
                icon: Icons.delete_sweep_rounded,
                title: 'Clear Current Car Cache',
                subtitle: 'Remove cached data for this car only',
                color: AppColors.warning,
                onTap: () => _clearCurrentCarCache(isDark),
              ),

              const SizedBox(height: 12),

              _buildCacheOption(
                isDark: isDark,
                icon: Icons.cleaning_services_rounded,
                title: 'Clean Expired Cache',
                subtitle: 'Remove only outdated cached entries',
                color: AppColors.success,
                onTap: () => _cleanExpiredCache(isDark),
              ),

              const SizedBox(height: 12),

              _buildCacheOption(
                isDark: isDark,
                icon: Icons.delete_forever_rounded,
                title: 'Clear All Cache',
                subtitle: 'Remove all cached data (requires confirmation)',
                color: AppColors.error,
                onTap: () => _clearAllCache(isDark),
              ),

              const SizedBox(height: 16),

              // Image Cache Section
              _buildCacheOption(
                isDark: isDark,
                icon: Icons.image_outlined,
                title: 'Clear Image Cache',
                subtitle: 'Clear cached images to free storage',
                color: AppColors.primary,
                onTap: () => _clearImageCache(isDark),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(
                  color: _isLoading
                      ? AppColors.getTextColor(isDark).withOpacity(0.4)
                      : AppColors.getTextColor(isDark),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCacheOption({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.getTextColor(isDark),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.getTextColor(isDark).withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshCurrentCarCache(bool isDark) async {
    setState(() => _isLoading = true);
    try {
      // Clear current car cache first
      await CacheService.clearCarCache(widget.carId);

      // Refresh the parts provider
      if (mounted) {
        final provider = context.read<CarPartsProvider>();
        await provider.loadPartsForCar(widget.carId, forceRefresh: true);

        Navigator.pop(context);
        _showSuccessSnackBar('Car parts cache refreshed successfully!');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to refresh cache: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearCurrentCarCache(bool isDark) async {
    setState(() => _isLoading = true);
    try {
      await CacheService.clearCarCache(widget.carId);
      Navigator.pop(context);
      _showSuccessSnackBar('Car cache cleared successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to clear car cache: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cleanExpiredCache(bool isDark) async {
    setState(() => _isLoading = true);
    try {
      await CacheService.cleanExpiredCache();
      Navigator.pop(context);
      _showSuccessSnackBar('Expired cache cleaned successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to clean expired cache: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllCache(bool isDark) async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.getSurface(isDark),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text(
              'Confirm Clear All',
              style: TextStyle(color: AppColors.getTextColor(isDark)),
            ),
          ],
        ),
        content: Text(
          'This will remove ALL cached data from the app. You\'ll need to reload everything. Are you sure?',
          style: TextStyle(
            color: AppColors.getTextColor(isDark).withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.getTextColor(isDark)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Clear All', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await CacheService.clearAllCache();
        Navigator.pop(context);
        _showSuccessSnackBar('All cache cleared successfully!');
      } catch (e) {
        _showErrorSnackBar('Failed to clear all cache: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _clearImageCache(bool isDark) async {
    setState(() => _isLoading = true);
    try {
      // Clear the cached network image cache
      await CachedNetworkImage.evictFromCache('');
      // Force clear all image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      Navigator.pop(context);
      _showSuccessSnackBar('Image cache cleared successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to clear image cache: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
