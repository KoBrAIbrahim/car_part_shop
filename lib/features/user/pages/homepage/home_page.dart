import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui' as ui;
import '../../../../core/providers/car_makes_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/api/models/car_make.dart';
import '../../../../core/services/search_service.dart';
import '../../../../core/services/vin_decoder_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<CarMake> _filteredCarMakes = [];

  // Search-related state
  SearchType _currentSearchType = SearchType.empty;
  bool _isSearching = false;
  String _searchValidationMessage = '';
  Color _searchTypeColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    // Load car makes when the page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CarMakesProvider>().loadCarMakes();
    });

    // Listen to search changes
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;

    // Update search type and validation
    setState(() {
      _currentSearchType = SearchService.determineSearchType(query);
      _searchValidationMessage = SearchService.getValidationMessage(query);
      _searchTypeColor = SearchService.getSearchTypeColor(
        _currentSearchType,
        query.isEmpty || VinDecoderService.isValidVinFormat(query),
      );
    });

    // Filter car makes for traditional search
    _filterCarMakes();
  }

  void _filterCarMakes() {
    final provider = context.read<CarMakesProvider>();
    final query = _searchController.text.toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _filteredCarMakes = provider.carMakes;
      });
    } else {
      setState(() {
        _filteredCarMakes = provider.carMakes
            .where((make) => make.name.toLowerCase().contains(query))
            .toList();
      });
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final result = await SearchService.performSearch(query);

      if (result.success && result.hasCarResult) {
        // Navigate to car parts page
        context.push(
          '/car-parts/${result.carResult!.carId}?carName=${Uri.encodeComponent(result.carResult!.displayName)}',
        );
      } else {
        // Show error/suggestion dialog
        _showSearchResultDialog(result);
      }
    } catch (e) {
      // Show error dialog
      _showErrorDialog('Search failed: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _showSearchResultDialog(SearchResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.type.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message),
            if (result.vinData != null) ...[
              const SizedBox(height: 16),
              Text(
                'VIN Information:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (result.vinData!.make != null)
                Text('Make: ${result.vinData!.make}'),
              if (result.vinData!.model != null)
                Text('Model: ${result.vinData!.model}'),
              if (result.vinData!.year != null)
                Text('Year: ${result.vinData!.year}'),
              Text('Confidence: ${result.vinData!.confidence}%'),
            ],
            if (result.hasSuggestions) ...[
              const SizedBox(height: 16),
              Text(
                'Similar vehicles found:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ...result.suggestions!
                  .take(3)
                  .map(
                    (car) => ListTile(
                      title: Text(car.displayName),
                      subtitle: Text('${car.confidence}% match'),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push(
                          '/car-parts/${car.carId}?carName=${Uri.encodeComponent(car.displayName)}',
                        );
                      },
                    ),
                  ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;

        return Scaffold(
          backgroundColor: AppColors.getBackground(isDark),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.welcomeBox,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey,
                    ), // Changed to gray border
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'user.home.welcome'.tr(),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.lightTextDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'user.home.subtitle'.tr(),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.8)
                                        : AppColors.lightTextDark.withOpacity(
                                            0.8,
                                          ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.car_repair_rounded,
                        size: 48,
                        color: isDark ? Colors.white : AppColors.lightTextDark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getCardBackground(isDark),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _searchTypeColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.getPrimary(isDark).withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        textDirection:
                            context.locale.languageCode == 'ar' ||
                                context.locale.languageCode == 'he'
                            ? ui.TextDirection.rtl
                            : ui.TextDirection.ltr,
                        style: TextStyle(color: AppColors.getTextColor(isDark)),
                        onSubmitted: (_) => _performSearch(),
                        decoration: InputDecoration(
                          hintText: _currentSearchType.hint,
                          hintStyle: TextStyle(
                            color: AppColors.getTextColor(
                              isDark,
                            ).withOpacity(0.6),
                          ),
                          prefixIcon: Icon(
                            SearchService.getSearchTypeIcon(_currentSearchType),
                            color: _searchTypeColor,
                          ),
                          suffixIcon: _isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : IconButton(
                                  onPressed: _performSearch,
                                  icon: Icon(
                                    Icons.search,
                                    color: AppColors.getPrimary(isDark),
                                  ),
                                ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                      if (_searchValidationMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                _currentSearchType == SearchType.vin &&
                                        VinDecoderService.isValidVinFormat(
                                          _searchController.text,
                                        )
                                    ? Icons.check_circle
                                    : Icons.info,
                                size: 16,
                                color: _searchTypeColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _searchValidationMessage,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _searchTypeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Car makes section
                Text(
                  'user.home.car_makes'.tr(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.getTextColor(isDark),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // Car makes list
                Expanded(
                  child: Consumer<CarMakesProvider>(
                    builder: (context, provider, child) {
                      // Update filtered list when provider data changes
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_filteredCarMakes.isEmpty && provider.hasData) {
                          _filteredCarMakes = provider.carMakes;
                        }
                      });

                      if (provider.isLoading && !provider.hasData) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.getPrimary(isDark),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'user.home.loading'.tr(),
                                style: TextStyle(
                                  color: AppColors.getTextColor(
                                    isDark,
                                  ).withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (provider.error != null && !provider.hasData) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 64,
                                color: AppColors.getTextColor(
                                  isDark,
                                ).withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'user.home.error'.tr(),
                                style: TextStyle(
                                  color: AppColors.getTextColor(
                                    isDark,
                                  ).withOpacity(0.7),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                provider.error!,
                                style: TextStyle(
                                  color: AppColors.getTextColor(
                                    isDark,
                                  ).withOpacity(0.5),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => provider.refresh(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.getPrimary(isDark),
                                  foregroundColor: isDark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                child: Text('user.home.retry'.tr()),
                              ),
                            ],
                          ),
                        );
                      }

                      if (!provider.hasData) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.car_repair_rounded,
                                size: 64,
                                color: AppColors.getTextColor(
                                  isDark,
                                ).withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'user.home.no_data'.tr(),
                                style: TextStyle(
                                  color: AppColors.getTextColor(
                                    isDark,
                                  ).withOpacity(0.7),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final displayList = _searchController.text.isEmpty
                          ? provider.carMakes
                          : _filteredCarMakes;

                      return RefreshIndicator(
                        onRefresh: provider.refresh,
                        color: isDark
                            ? Colors.white
                            : AppColors.getPrimary(isDark),
                        backgroundColor: AppColors.getCardBackground(isDark),
                        child: GridView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio:
                                    0.75, // Made cards a little taller (was 0.85)
                              ),
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            final carMake = displayList[index];

                            return _buildCarCard(carMake, isDark);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCarCard(CarMake carMake, bool isDark) {
    return GestureDetector(
      onTap: () {
        // Navigate to car details page using GoRouter with path parameters
        context.push(
          '/car-details/${Uri.encodeComponent(carMake.name)}?logoUrl=${Uri.encodeComponent(carMake.logoUrl)}',
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black), // Changed to black border
          boxShadow: [
            BoxShadow(
              color: AppColors.getPrimary(isDark).withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Car Logo
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.black, // Changed to black border
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CachedNetworkImage(
                      imageUrl: carMake.logoUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.getPrimary(isDark),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.car_repair_rounded,
                        color: AppColors.getPrimary(isDark),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Car Name
              Expanded(
                flex: 1,
                child: Text(
                  carMake.name,
                  style: TextStyle(
                    color: AppColors.getTextColor(isDark),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
