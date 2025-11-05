import 'package:flutter/material.dart';
import 'dart:async';
import '../api/models/tool_product.dart';
import '../api/services/tools_service.dart';

class ToolsProvider extends ChangeNotifier {
  List<ToolProduct> _tools = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalToolsCount = 0;
  bool _hasMoreData = true;
  String _searchQuery = '';
  String? _selectedSubcategory; // Track selected subcategory
  Timer? _refreshTimer;
  DateTime? _lastRefreshTime;

  // Auto refresh interval (2 hours for tools)
  static const Duration _autoRefreshInterval = Duration(hours: 2);

  // Page size
  static const int _pageSize = 10;

  List<ToolProduct> get tools => _tools;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMoreData => _hasMoreData;
  bool get hasData => _tools.isNotEmpty;
  int get totalTools => _totalToolsCount;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  String get searchQuery => _searchQuery;
  String? get selectedSubcategory => _selectedSubcategory;
  DateTime? get lastRefreshTime => _lastRefreshTime;
  bool get isAutoRefreshActive => _refreshTimer?.isActive ?? false;
  bool get canGoToNextPage => _currentPage < _totalPages - 1;
  bool get canGoToPreviousPage => _currentPage > 0;

  /// Load tools (first page)
  Future<void> loadTools({
    bool forceRefresh = false,
    String? subcategory,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _currentPage = 0;
    _tools.clear();
    _hasMoreData = true;
    _selectedSubcategory = subcategory;
    notifyListeners();

    try {
      print(
        '🔧 [TOOLS_PROVIDER] Loading tools (forceRefresh: $forceRefresh, subcategory: $subcategory)',
      );

      if (subcategory != null && subcategory.toLowerCase() != 'all') {
        // Load tools for specific subcategory
        _totalToolsCount = await ToolsService.getToolsCountBySubcategory(
          subcategory: subcategory,
          forceRefresh: forceRefresh,
        );
        _totalPages = (_totalToolsCount / _pageSize).ceil();

        final newTools = await ToolsService.fetchToolsBySubcategory(
          subcategory: subcategory,
          page: _currentPage,
          pageSize: _pageSize,
          forceRefresh: forceRefresh,
        );

        _tools = newTools;
      } else {
        // Load all tools
        _totalToolsCount = await ToolsService.getTotalToolsCount();
        _totalPages = (_totalToolsCount / _pageSize).ceil();

        final newTools = await ToolsService.fetchToolsProducts(
          page: _currentPage,
          pageSize: _pageSize,
          forceRefresh: forceRefresh,
        );

        _tools = newTools;
      }

      _hasMoreData = _currentPage < _totalPages - 1;

      _lastRefreshTime = DateTime.now();
      _startAutoRefreshTimer();

      print(
        '✅ [TOOLS_PROVIDER] Loaded ${_tools.length} tools (Page ${_currentPage + 1}/$_totalPages)',
      );
    } catch (e) {
      _error = e.toString();
      print('❌ [TOOLS_PROVIDER] Error loading tools: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Go to next page
  Future<void> goToNextPage() async {
    if (!canGoToNextPage || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      print('🔧 [TOOLS_PROVIDER] Loading page ${nextPage + 1}');

      List<ToolProduct> newTools;
      if (_selectedSubcategory != null &&
          _selectedSubcategory!.toLowerCase() != 'all') {
        newTools = await ToolsService.fetchToolsBySubcategory(
          subcategory: _selectedSubcategory!,
          page: nextPage,
          pageSize: _pageSize,
        );
      } else {
        newTools = await ToolsService.fetchToolsProducts(
          page: nextPage,
          pageSize: _pageSize,
        );
      }

      _tools = newTools;
      _currentPage = nextPage;
      _hasMoreData = _currentPage < _totalPages - 1;

      print(
        '✅ [TOOLS_PROVIDER] Loaded page ${_currentPage + 1}/$_totalPages (${_tools.length} tools)',
      );
    } catch (e) {
      _error = e.toString();
      print('❌ [TOOLS_PROVIDER] Error loading next page: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Go to previous page
  Future<void> goToPreviousPage() async {
    if (!canGoToPreviousPage || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prevPage = _currentPage - 1;
      print('🔧 [TOOLS_PROVIDER] Loading page ${prevPage + 1}');

      List<ToolProduct> newTools;
      if (_selectedSubcategory != null &&
          _selectedSubcategory!.toLowerCase() != 'all') {
        newTools = await ToolsService.fetchToolsBySubcategory(
          subcategory: _selectedSubcategory!,
          page: prevPage,
          pageSize: _pageSize,
        );
      } else {
        newTools = await ToolsService.fetchToolsProducts(
          page: prevPage,
          pageSize: _pageSize,
        );
      }

      _tools = newTools;
      _currentPage = prevPage;
      _hasMoreData = _currentPage < _totalPages - 1;

      print(
        '✅ [TOOLS_PROVIDER] Loaded page ${_currentPage + 1}/$_totalPages (${_tools.length} tools)',
      );
    } catch (e) {
      _error = e.toString();
      print('❌ [TOOLS_PROVIDER] Error loading previous page: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Go to specific page
  Future<void> goToPage(int page) async {
    if (page < 0 || page >= _totalPages || page == _currentPage || _isLoading)
      return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔧 [TOOLS_PROVIDER] Loading page ${page + 1}');

      List<ToolProduct> newTools;
      if (_selectedSubcategory != null &&
          _selectedSubcategory!.toLowerCase() != 'all') {
        newTools = await ToolsService.fetchToolsBySubcategory(
          subcategory: _selectedSubcategory!,
          page: page,
          pageSize: _pageSize,
        );
      } else {
        newTools = await ToolsService.fetchToolsProducts(
          page: page,
          pageSize: _pageSize,
        );
      }

      _tools = newTools;
      _currentPage = page;
      _hasMoreData = _currentPage < _totalPages - 1;

      print(
        '✅ [TOOLS_PROVIDER] Loaded page ${_currentPage + 1}/$_totalPages (${_tools.length} tools)',
      );
    } catch (e) {
      _error = e.toString();
      print('❌ [TOOLS_PROVIDER] Error loading page ${page + 1}: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search tools
  Future<void> searchTools(String query) async {
    if (_isLoading) return;

    _searchQuery = query.trim();
    _isLoading = true;
    _error = null;
    _currentPage = 0;
    _hasMoreData = false; // Disable pagination for search
    notifyListeners();

    try {
      print('🔍 [TOOLS_PROVIDER] Searching tools: "$_searchQuery"');

      if (_searchQuery.isEmpty) {
        // If search is cleared, reload all tools
        await loadTools();
        return;
      }

      final searchResults = await ToolsService.searchToolsProducts(
        query: _searchQuery,
      );

      _tools = searchResults;
      _totalToolsCount = searchResults.length;
      _totalPages = (_totalToolsCount / _pageSize).ceil();

      print(
        '✅ [TOOLS_PROVIDER] Found ${_tools.length} tools matching "$_searchQuery"',
      );
    } catch (e) {
      _error = e.toString();
      print('❌ [TOOLS_PROVIDER] Error searching tools: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear search and reload tools
  Future<void> clearSearch() async {
    if (_searchQuery.isEmpty) return;

    _searchQuery = '';
    await loadTools();
  }

  /// Refresh tools (pull to refresh)
  Future<void> refresh() async {
    print('🔄 [TOOLS_PROVIDER] Refreshing tools');

    if (_searchQuery.isNotEmpty) {
      await searchTools(_searchQuery);
    } else {
      await loadTools(forceRefresh: true);
    }
  }

  /// Add a tool to cart (method for potential future use)
  Future<void> addToolToCart(ToolProduct tool, int quantity) async {
    try {
      // This would integrate with CartService when implemented
      print(
        '🛒 [TOOLS_PROVIDER] Adding tool to cart: ${tool.title} (qty: $quantity)',
      );

      // For now, just log the action
      // TODO: Integrate with CartService
    } catch (e) {
      print('❌ [TOOLS_PROVIDER] Error adding tool to cart: $e');
      rethrow;
    }
  }

  /// Start auto-refresh timer
  void _startAutoRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(_autoRefreshInterval, () {
      if (_searchQuery.isEmpty) {
        print('⏰ [TOOLS_PROVIDER] Auto-refreshing tools');
        loadTools(forceRefresh: true);
      }
    });
  }

  /// Stop auto-refresh timer
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Get tools count by availability
  Map<String, int> get toolsStats {
    final inStock = _tools.where((tool) => tool.isInStock).length;
    final outOfStock = _tools.length - inStock;
    final onSale = _tools.where((tool) => tool.isOnSale).length;

    return {
      'total': _tools.length,
      'inStock': inStock,
      'outOfStock': outOfStock,
      'onSale': onSale,
    };
  }

  /// Get tools grouped by vendor
  Map<String, List<ToolProduct>> get toolsByVendor {
    final grouped = <String, List<ToolProduct>>{};

    for (final tool in _tools) {
      final vendor = tool.vendor.isNotEmpty ? tool.vendor : 'Unknown';
      grouped.putIfAbsent(vendor, () => []).add(tool);
    }

    return grouped;
  }

  /// Get tools in price range
  List<ToolProduct> getToolsInPriceRange(double minPrice, double maxPrice) {
    return _tools.where((tool) {
      final price = tool.actualPrice;
      return price >= minPrice && price <= maxPrice;
    }).toList();
  }

  /// Get tools by availability
  List<ToolProduct> getToolsByAvailability({required bool inStock}) {
    return _tools.where((tool) => tool.isInStock == inStock).toList();
  }

  /// Get tools on sale
  List<ToolProduct> getToolsOnSale() {
    return _tools.where((tool) => tool.isOnSale).toList();
  }

  /// Get all subcategories (tags) from tools
  Future<List<String>> getAllSubcategories({bool forceRefresh = false}) async {
    try {
      print('🔧 [TOOLS_PROVIDER] Fetching all subcategories');
      final subcategories = await ToolsService.getAllSubcategories(
        forceRefresh: forceRefresh,
      );
      print('✅ [TOOLS_PROVIDER] Found ${subcategories.length} subcategories');
      return subcategories;
    } catch (e) {
      print('❌ [TOOLS_PROVIDER] Error fetching subcategories: $e');
      return [];
    }
  }

  /// Set selected subcategory and reload tools
  Future<void> setSubcategory(String? subcategory) async {
    if (_selectedSubcategory == subcategory) return;
    await loadTools(subcategory: subcategory);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
