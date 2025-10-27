import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/car_parts_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/api/models/car_part.dart';
import '../../../../core/services/cache_service.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../../auth/auth_provider.dart';
import 'car_parts_header.dart';
// pagination removed - using lazy loading (infinite scroll)
import 'car_part_card.dart';

class CarPartsPage extends StatefulWidget {
  final int carId;
  final String carName;
  final String? initialCategory;
  final String? initialSubcategory;

  const CarPartsPage({
    super.key,
    required this.carId,
    required this.carName,
    this.initialCategory,
    this.initialSubcategory,
  });

  @override
  State<CarPartsPage> createState() => _CarPartsPageState();
}

class _CarPartsPageState extends State<CarPartsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchActive = false;
  Timer? _searchDebounce;
  late CarPartsProvider _partsProvider;
  final ScrollController _scrollController = ScrollController();

  // Filter and sort state
  String _selectedCategory = 'All';
  String? _selectedSubcategory;
  String _sortBy = 'name';
  bool _sortAscending = true;
  List<String> _availableCategories = ['All'];

  @override
  void initState() {
    super.initState();
    _partsProvider = Provider.of<CarPartsProvider>(context, listen: false);

    // Set initial category and subcategory if provided
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    if (widget.initialSubcategory != null) {
      _selectedSubcategory = widget.initialSubcategory;
    }

    // Load parts when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _partsProvider.loadPartsForCar(
        widget.carId,
        category: widget.initialCategory,
        subcategory: widget.initialSubcategory,
      );
    });

    // Listen to provider changes to extract categories
    _partsProvider.addListener(_onProviderDataChanged);
    // Listen to scroll events for lazy loading
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _partsProvider.removeListener(_onProviderDataChanged);
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;

    // When user scrolls within 200px of bottom, try to load next page
    if (current >= (max - 200)) {
      final provider = Provider.of<CarPartsProvider>(context, listen: false);
      if (provider.canGoToNextPage && !provider.isLoading) {
        provider.goToNextPage();
      }
    }
  }

  void _activateSearch() {
    setState(() => _isSearchActive = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _deactivateSearch() {
    setState(() => _isSearchActive = false);
    _searchController.clear();
    _searchDebounce?.cancel();
    final provider = Provider.of<CarPartsProvider>(context, listen: false);
    provider.clearSearch();
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: AppColors.getBackground(isDark),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'user.car_parts.search_hint'.tr(),
                filled: true,
                fillColor: AppColors.getCardBackground(isDark),
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.yellow),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.getTextColor(isDark)),
                        onPressed: () {
                          _searchController.clear();
                          final provider = Provider.of<CarPartsProvider>(context, listen: false);
                          provider.clearSearch();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 400), () {
                  final provider = Provider.of<CarPartsProvider>(context, listen: false);
                  if (value.trim().isEmpty) {
                    provider.clearSearch();
                  } else {
                    provider.searchParts(value.trim());
                  }
                });
                setState(() {});
              },
              onSubmitted: (value) {
                final provider = Provider.of<CarPartsProvider>(context, listen: false);
                if (value.trim().isEmpty) {
                  provider.clearSearch();
                } else {
                  provider.searchParts(value.trim());
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _deactivateSearch,
            child: Text('Cancel'),
          ),
        ],
      ),
    );
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

  List<CarPart> _getFilteredAndSortedParts(List<CarPart> parts) {
    List<CarPart> filtered = parts;

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((part) => part.displayCategory == _selectedCategory)
          .toList();
    }

    // Filter by subcategory if selected
    if (_selectedSubcategory != null && _selectedSubcategory!.isNotEmpty) {
      filtered = filtered
          .where((part) => part.displaySubcategory == _selectedSubcategory)
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

  // Cache management removed per UX request

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: AppColors.getBackground(isDark),
          body: Column(
            children: [
              // Header Widget (show total from provider)
              Consumer<CarPartsProvider>(
                builder: (context, provider, child) {
                  final totalParts = provider.totalParts;

                  return CarPartsHeader(
                    carName: widget.carName,
                    totalParts: totalParts,
                    isLoading: provider.isLoading && provider.parts.isEmpty,
                    onFilterPressed: null, // Disabled filter button
                    onSearchPressed: () => _activateSearch(),
                    hasActiveFilters: false, // No filters
                    onCacheManagePressed: null,
                  );
                },
              ),
              // Search bar (shown when search mode is active)
              if (_isSearchActive) _buildSearchBar(isDark),

              // Parts Grid with Pagination
              Expanded(
                child: Column(
                  children: [
                    // Parts Grid
                    Expanded(child: _buildPartsGrid(isDark)),

                    // Lazy loading indicator (shows when loading more pages)
                    Consumer<CarPartsProvider>(
                      builder: (context, provider, child) {
                        if (provider.isLoading && provider.parts.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(AppColors.yellow),
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox(height: 12);
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
                  content: Text('Parts refreshed!'),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          color: AppColors.yellow,
          backgroundColor: AppColors.getCardBackground(isDark),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: filteredParts.length,
            itemBuilder: (context, index) {
              final part = filteredParts[index];
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final isGarageOwner = authProvider.isGarageOwner();
              
              return _buildPartCard(part, isGarageOwner, index, isDark);
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(bool isDark) {
    final textColor = AppColors.getTextColor(isDark);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.yellow),
          ),
          const SizedBox(height: 16),
          Text(
            'user.car_parts.loading'.tr(),
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, CarPartsProvider provider) {
    final textColor = AppColors.getTextColor(isDark);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'user.car_parts.error'.tr(),
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              provider.error ?? 'Unknown error',
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => provider.loadPartsForCar(widget.carId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text('user.car_parts.retry'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, CarPartsProvider provider) {
    final textColor = AppColors.getTextColor(isDark);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: textColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'user.car_parts.no_parts'.tr(),
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFilterResultsState(bool isDark) {
    final textColor = AppColors.getTextColor(isDark);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: textColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No parts match your filters',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartCard(CarPart part, bool isGarageOwner, int index, bool isDark) {
    // Use the reusable CarPartCard widget for a richer UI and consistent behavior
    return CarPartCard(
      part: part,
      carName: widget.carName,
      isGarageOwner: isGarageOwner,
      index: index,
      onTap: (p) => context.push('/part-details/${p.id}', extra: p),
    );
  }
}

// Cache management UI removed — methods removed as part of simplification