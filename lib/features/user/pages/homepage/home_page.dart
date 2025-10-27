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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<CarMake> _filteredCarMakes = [];
  bool _showSearchBar = false;
  late AnimationController _animationController;
  late Animation<double> _searchBarAnimation;

  // Search-related state
  SearchType _currentSearchType = SearchType.empty;
  bool _isSearching = false;
  String _searchValidationMessage = '';
  Color _searchTypeColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _searchBarAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
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
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (_showSearchBar) {
        _animationController.forward();
        Future.delayed(const Duration(milliseconds: 300), () {
          _searchFocusNode.requestFocus();
        });
      } else {
        _animationController.reverse();
        _searchController.clear();
        _searchFocusNode.unfocus();
      }
    });
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
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final bgColor = AppColors.getCardBackground(isDark);
    final textColor = AppColors.getTextColor(isDark);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.yellow, width: 2),
        ),
        title: Text(
          result.type.displayName,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.message,
              style: TextStyle(color: textColor),
            ),
                    if (result.vinData != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.getSurface(isDark),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.yellow),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VIN Information:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.yellow,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (result.vinData!.make != null)
                      _buildInfoRow('Make', result.vinData!.make!, textColor),
                    if (result.vinData!.model != null)
                      _buildInfoRow('Model', result.vinData!.model!, textColor),
                    if (result.vinData!.year != null)
                      _buildInfoRow('Year', result.vinData!.year!.toString(), textColor),
                    _buildInfoRow('Confidence', '${result.vinData!.confidence}%', textColor),
                  ],
                ),
              ),
            ],
            if (result.hasSuggestions) ...[
              const SizedBox(height: 16),
              Text(
                'Similar vehicles found:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.yellow,
                ),
              ),
              const SizedBox(height: 8),
              ...result.suggestions!
                  .take(3)
                  .map(
                    (car) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.yellow),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        title: Text(
                          car.displayName,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${car.confidence}% match',
                          style: TextStyle(
                            color: AppColors.getTextSecondaryColor(isDark),
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.yellow,
                          size: 16,
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push(
                            '/car-parts/${car.carId}?carName=${Uri.encodeComponent(car.displayName)}',
                          );
                        },
                      ),
                    ),
                  ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: AppColors.getTextSecondaryColor(
                Provider.of<ThemeProvider>(context, listen: false).isDarkMode,
              ),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final bgColor = AppColors.getCardBackground(isDark);
    final textColor = AppColors.getTextColor(isDark);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.error, width: 2),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 8),
            Text(
              'Search Error',
              style: TextStyle(color: textColor),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
        final bgColor = AppColors.getBackground(isDark);
        final textColor = AppColors.getTextColor(isDark);
        final secondaryTextColor = AppColors.getTextSecondaryColor(isDark);
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth > 600;
        final isDesktop = screenWidth > 1200;

        // Determine grid cross axis count based on screen size
        int crossAxisCount;
        if (isDesktop) {
          crossAxisCount = 6;
        } else if (isTablet) {
          crossAxisCount = 4;
        } else {
          crossAxisCount = 3;
        }

        return Scaffold(
          backgroundColor: bgColor,
          
          body: SafeArea(
            child: Column(
              children: [
                // Animated Search Bar
                SizeTransition(
                  sizeFactor: _searchBarAnimation,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(isDark),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search hint text
                        Text(
                          'user.home.search_hint'.tr(),
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Search TextField
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.getCardBackground(isDark),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _searchController.text.isEmpty 
                                  ? AppColors.yellow 
                                  : _searchTypeColor,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.yellow.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            style: TextStyle(color: textColor, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'user.home.search_hint'.tr(),
                              hintStyle: TextStyle(color: secondaryTextColor),
                              prefixIcon: Icon(
                                Icons.search,
                                color: AppColors.yellow,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_isSearching)
                                          Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  AppColors.yellow,
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          IconButton(
                                            icon: Icon(
                                              Icons.clear,
                                              color: secondaryTextColor,
                                            ),
                                            onPressed: () {
                                              _searchController.clear();
                                            },
                                          ),
                                        Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          child: Material(
                                            color: AppColors.yellow,
                                            borderRadius: BorderRadius.circular(8),
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(8),
                                              onTap: _isSearching ? null : _performSearch,
                                              child: const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Icon(
                                                  Icons.arrow_forward,
                                                  color: Colors.black,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            onSubmitted: (_) => _performSearch(),
                          ),
                        ),
                        
                        // Search validation message
                        if (_searchValidationMessage.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _searchTypeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _searchTypeColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: _searchTypeColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _searchValidationMessage,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Main Content - Car Makes Section
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Title with Search Icon
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.yellow,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'user.home.car_makes'.tr(),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: isDesktop ? 24 : (isTablet ? 22 : 20),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            
                            // Search Icon Button
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.yellow,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.yellowDark,
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
                                  _showSearchBar ? Icons.close : Icons.search,
                                  color: Colors.black,
                                ),
                                onPressed: _toggleSearchBar,
                                tooltip: _showSearchBar ? 'Close Search' : 'Search',
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Car Makes Grid
                        Expanded(
                          child: Consumer<CarMakesProvider>(
                            builder: (context, provider, child) {
                              // Loading State
                              if (provider.isLoading && !provider.hasData) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: AppColors.yellow.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(30),
                                          border: Border.all(
                                            color: AppColors.yellow,
                                            width: 2,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              AppColors.yellow,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'user.home.loading'.tr(),
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Please wait...',
                                        style: TextStyle(
                                          color: secondaryTextColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              // Error State
                              if (provider.error != null && !provider.hasData) {
                                return Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    margin: const EdgeInsets.symmetric(horizontal: 32),
                                    decoration: BoxDecoration(
                                      color: AppColors.getCardBackground(isDark),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.error,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: AppColors.error.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.error_outline_rounded,
                                            size: 48,
                                            color: AppColors.error,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'user.home.error'.tr(),
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          provider.error!,
                                          style: TextStyle(
                                            color: secondaryTextColor,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          onPressed: () => provider.refresh(),
                                          icon: const Icon(Icons.refresh),
                                          label: Text('user.home.retry'.tr()),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.yellow,
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 32,
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              // No Data State
                              if (!provider.hasData) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: AppColors.yellow.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.yellow,
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.car_repair_rounded,
                                          size: 64,
                                          color: AppColors.yellow,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'user.home.no_data'.tr(),
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final displayList = _searchController.text.isEmpty
                                  ? provider.carMakes
                                  : _filteredCarMakes;

                              // Car Makes Grid
                              return RefreshIndicator(
                                onRefresh: provider.refresh,
                                color: AppColors.yellow,
                                backgroundColor: AppColors.getCardBackground(isDark),
                                child: GridView.builder(
                                  controller: _scrollController,
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: EdgeInsets.all(isDesktop ? 16 : (isTablet ? 12 : 12)),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2, // Always 2 cards per row
                                    crossAxisSpacing: isDesktop ? 20 : (isTablet ? 16 : 16),
                                    mainAxisSpacing: isDesktop ? 20 : (isTablet ? 16 : 16),
                                    childAspectRatio: 0.75, // Made cards taller
                                  ),
                                  itemCount: displayList.length,
                                  itemBuilder: (context, index) {
                                    final carMake = displayList[index];
                                    return _buildCarCard(
                                      carMake,
                                      isDark,
                                      isDesktop,
                                      isTablet,
                                    );
                                  },
                                ),
                              );
                            },
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
      },
    );
  }

  Widget _buildCarCard(
    CarMake carMake,
    bool isDark,
    bool isDesktop,
    bool isTablet,
  ) {
    final cardBg = AppColors.getCardBackground(isDark);
    final textColor = AppColors.getTextColor(isDark);

    return GestureDetector(
      onTap: () {
        context.push(
          '/car-details/${Uri.encodeComponent(carMake.name)}?logoUrl=${Uri.encodeComponent(carMake.logoUrl)}',
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.yellow,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.yellow.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                context.push(
                  '/car-details/${Uri.encodeComponent(carMake.name)}?logoUrl=${Uri.encodeComponent(carMake.logoUrl)}',
                );
              },
              splashColor: AppColors.yellow.withOpacity(0.3),
              highlightColor: AppColors.yellow.withOpacity(0.1),
              child: Padding(
                padding: EdgeInsets.all(isDesktop ? 20 : (isTablet ? 16 : 14)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Car Logo Container
                    Expanded(
                      flex: 4,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.yellow.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.yellow.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isDesktop ? 16 : (isTablet ? 14 : 12)),
                          child: CachedNetworkImage(
                            imageUrl: carMake.logoUrl,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.yellow,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              decoration: BoxDecoration(
                                color: AppColors.yellow.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.directions_car_rounded,
                                color: AppColors.yellow,
                                size: isDesktop ? 60 : (isTablet ? 50 : 45),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: isDesktop ? 16 : (isTablet ? 14 : 12)),
                    
                    // Car Name
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Text(
                          carMake.name,
                          style: TextStyle(
                            color: textColor,
                            fontSize: isDesktop ? 18 : (isTablet ? 16 : 15),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}