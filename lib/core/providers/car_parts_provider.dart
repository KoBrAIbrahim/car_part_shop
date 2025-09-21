import 'package:flutter/material.dart';
import 'dart:async';
import '../api/models/car_part.dart';
import '../api/services/car_parts_service.dart';
import '../services/cache_service.dart';

class CarPartsProvider extends ChangeNotifier {
  List<CarPart> _parts = []; // Current page parts only
  bool _isLoading = false;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalPartsCount = 0;
  int? _carId;
  String _searchQuery = '';
  Timer? _refreshTimer;
  DateTime? _lastRefreshTime;

  // Pagination constants
  static const int _pageSize = 10;

  // Auto refresh interval (1 hour)
  static const Duration _autoRefreshInterval = Duration(hours: 1);

  List<CarPart> get parts => _parts;
  List<CarPart> get allParts =>
      _parts; // For compatibility, return current parts
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _parts.isNotEmpty;
  int get totalParts => _totalPartsCount;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get pageSize => _pageSize;
  String get searchQuery => _searchQuery;
  DateTime? get lastRefreshTime => _lastRefreshTime;
  bool get isAutoRefreshActive => _refreshTimer?.isActive ?? false;
  bool get canGoToNextPage => _currentPage < _totalPages - 1;
  bool get canGoToPreviousPage => _currentPage > 0;

  /// Load parts for a specific car with server-side pagination
  Future<void> loadPartsForCar(int carId, {bool forceRefresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _carId = carId;
    _currentPage = 0;
    _parts.clear();
    notifyListeners();

    try {
      print(
        '🔄 [PARTS_PROVIDER] Loading parts for car ID: $carId (forceRefresh: $forceRefresh)',
      );

      // Get total count first
      _totalPartsCount = await CarPartsService.getTotalPartsCount(carId);
      _totalPages = (_totalPartsCount / _pageSize).ceil();
      if (_totalPages == 0) _totalPages = 1;

      // Load first page
      _parts = await CarPartsService.fetchCarParts(
        carId: carId,
        page: _currentPage,
        pageSize: _pageSize,
        forceRefresh: forceRefresh,
      );

      print(
        '✅ [PARTS_PROVIDER] Loaded page ${_currentPage + 1}/${_totalPages} with ${_parts.length} parts (total: $_totalPartsCount)',
      );

      // Update last refresh time and start auto-refresh timer
      _lastRefreshTime = DateTime.now();
      _startAutoRefreshTimer();
    } catch (e) {
      print('❌ [PARTS_PROVIDER] Error loading parts: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Go to next page with server-side loading
  Future<void> goToNextPage() async {
    if (!canGoToNextPage || _isLoading || _carId == null) return;

    _isLoading = true;
    _currentPage++;
    notifyListeners();

    try {
      if (_searchQuery.isNotEmpty) {
        _parts = await CarPartsService.searchCarParts(
          carId: _carId!,
          searchQuery: _searchQuery,
          page: _currentPage,
          pageSize: _pageSize,
        );
      } else {
        _parts = await CarPartsService.fetchCarParts(
          carId: _carId!,
          page: _currentPage,
          pageSize: _pageSize,
        );
      }

      print(
        '📄 [PARTS_PROVIDER] Moved to page ${_currentPage + 1}/$_totalPages',
      );
    } catch (e) {
      print('❌ [PARTS_PROVIDER] Error loading next page: $e');
      _error = e.toString();
      _currentPage--; // Revert page change on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Go to previous page with server-side loading
  Future<void> goToPreviousPage() async {
    if (!canGoToPreviousPage || _isLoading || _carId == null) return;

    _isLoading = true;
    _currentPage--;
    notifyListeners();

    try {
      if (_searchQuery.isNotEmpty) {
        _parts = await CarPartsService.searchCarParts(
          carId: _carId!,
          searchQuery: _searchQuery,
          page: _currentPage,
          pageSize: _pageSize,
        );
      } else {
        _parts = await CarPartsService.fetchCarParts(
          carId: _carId!,
          page: _currentPage,
          pageSize: _pageSize,
        );
      }

      print(
        '📄 [PARTS_PROVIDER] Moved to page ${_currentPage + 1}/$_totalPages',
      );
    } catch (e) {
      print('❌ [PARTS_PROVIDER] Error loading previous page: $e');
      _error = e.toString();
      _currentPage++; // Revert page change on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Go to specific page with server-side loading
  Future<void> goToPage(int pageIndex) async {
    if (pageIndex < 0 ||
        pageIndex >= _totalPages ||
        _isLoading ||
        _carId == null)
      return;

    final oldPage = _currentPage;
    _isLoading = true;
    _currentPage = pageIndex;
    notifyListeners();

    try {
      if (_searchQuery.isNotEmpty) {
        _parts = await CarPartsService.searchCarParts(
          carId: _carId!,
          searchQuery: _searchQuery,
          page: _currentPage,
          pageSize: _pageSize,
        );
      } else {
        _parts = await CarPartsService.fetchCarParts(
          carId: _carId!,
          page: _currentPage,
          pageSize: _pageSize,
        );
      }

      print(
        '📄 [PARTS_PROVIDER] Moved to page ${_currentPage + 1}/$_totalPages',
      );
    } catch (e) {
      print('❌ [PARTS_PROVIDER] Error loading page: $e');
      _error = e.toString();
      _currentPage = oldPage; // Revert page change on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search parts with server-side pagination
  Future<void> searchParts(String query) async {
    if (_isLoading || _carId == null) return;

    _isLoading = true;
    _searchQuery = query;
    _currentPage = 0;
    notifyListeners();

    try {
      if (query.isEmpty) {
        // Return to normal pagination
        _totalPartsCount = await CarPartsService.getTotalPartsCount(_carId!);
        _totalPages = (_totalPartsCount / _pageSize).ceil();
        if (_totalPages == 0) _totalPages = 1;

        _parts = await CarPartsService.fetchCarParts(
          carId: _carId!,
          page: _currentPage,
          pageSize: _pageSize,
        );
      } else {
        // Perform search - for now, we'll get first page and estimate total
        _parts = await CarPartsService.searchCarParts(
          carId: _carId!,
          searchQuery: query,
          page: _currentPage,
          pageSize: _pageSize,
        );

        // For search, we'll use a simplified pagination approach
        // This could be enhanced with a proper search count endpoint
        _totalPages = _parts.length == _pageSize
            ? 10
            : 1; // Estimate based on results
      }

      print(
        '🔍 [PARTS_PROVIDER] Search completed: "${query}", ${_parts.length} results',
      );
    } catch (e) {
      print('❌ [PARTS_PROVIDER] Error searching parts: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear search and reload all parts
  Future<void> clearSearch() async {
    if (_carId == null) return;

    _searchQuery = '';
    _currentPage = 0;

    // Reload parts without search
    await loadPartsForCar(_carId!);
    notifyListeners();
  }

  /// Refresh parts data
  Future<void> refresh({bool forceRefresh = true}) async {
    if (_carId == null) return;

    print(
      '🔄 [PARTS_PROVIDER] Refreshing parts data (forceRefresh: $forceRefresh)',
    );

    if (_searchQuery.isNotEmpty) {
      await loadPartsForCar(_carId!, forceRefresh: forceRefresh);
      await searchParts(_searchQuery);
    } else {
      await loadPartsForCar(_carId!, forceRefresh: forceRefresh);
    }
  }

  /// Clear all data
  void clear() {
    _parts.clear();
    _totalPartsCount = 0;
    _error = null;
    _isLoading = false;
    _currentPage = 0;
    _totalPages = 1;
    _carId = null;
    _searchQuery = '';
    _lastRefreshTime = null;
    _stopAutoRefreshTimer();
    notifyListeners();
  }

  /// Start auto-refresh timer (refreshes every hour)
  void _startAutoRefreshTimer() {
    _stopAutoRefreshTimer(); // Cancel any existing timer

    _refreshTimer = Timer.periodic(_autoRefreshInterval, (timer) {
      print(
        '⏰ [PARTS_PROVIDER] Auto-refresh triggered after ${_autoRefreshInterval.inHours} hour(s)',
      );
      refresh(forceRefresh: true);
    });

    print(
      '✅ [PARTS_PROVIDER] Auto-refresh timer started (${_autoRefreshInterval.inHours}h interval)',
    );
  }

  /// Stop auto-refresh timer
  void _stopAutoRefreshTimer() {
    if (_refreshTimer != null) {
      _refreshTimer!.cancel();
      _refreshTimer = null;
      print('🛑 [PARTS_PROVIDER] Auto-refresh timer stopped');
    }
  }

  /// Clear cache for current car
  Future<void> clearCache() async {
    if (_carId != null) {
      await CacheService.clearCarCache(_carId!);
      print('🗑️ [PARTS_PROVIDER] Cache cleared for car ID: $_carId');
    }
  }

  /// Initialize cache service
  static Future<void> initializeCache() async {
    await CacheService.initialize();
    print('✅ [PARTS_PROVIDER] Cache service initialized');
  }

  /// Cleanup expired cache entries
  static Future<void> cleanupCache() async {
    await CacheService.cleanExpiredCache();
  }

  /// Get cache statistics for debugging
  Future<Map<String, dynamic>> getCacheStats() async {
    return await CacheService.getCacheStats();
  }

  /// Force a refresh (for testing)
  Future<void> forceRefresh() async {
    print('🔄 [PARTS_PROVIDER] Force refresh requested');
    await refresh(forceRefresh: true);
  }

  @override
  void dispose() {
    _stopAutoRefreshTimer();
    super.dispose();
  }
}
