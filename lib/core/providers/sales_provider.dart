import 'package:flutter/foundation.dart';
import '../api/models/car_part.dart';
import '../api/models/tool_product.dart';
import '../api/services/sales_service.dart';

class SalesProvider with ChangeNotifier {
  final SalesService _salesService = SalesService();

  // Car Parts state
  List<CarPart> _saleCarParts = [];
  bool _isLoadingCarParts = false;
  String? _carPartsError;
  int _currentCarPartsPage = 1;
  int _totalCarParts = 0;
  final int _carPartsPerPage = 10;

  // Tools state
  List<ToolProduct> _saleTools = [];
  bool _isLoadingTools = false;
  String? _toolsError;
  int _currentToolsPage = 1;
  int _totalTools = 0;
  final int _toolsPerPage = 10;

  // Car Parts getters
  List<CarPart> get saleCarParts => _saleCarParts;
  bool get isLoadingCarParts => _isLoadingCarParts;
  String? get carPartsError => _carPartsError;
  int get currentCarPartsPage => _currentCarPartsPage;
  int get totalCarParts => _totalCarParts;
  bool get hasCarPartsData => _saleCarParts.isNotEmpty;
  
  int get totalCarPartsPages => (_totalCarParts / _carPartsPerPage).ceil();
  bool get canGoToPreviousCarPartsPage => _currentCarPartsPage > 1;
  bool get canGoToNextCarPartsPage => _currentCarPartsPage < totalCarPartsPages;

  // Tools getters
  List<ToolProduct> get saleTools => _saleTools;
  bool get isLoadingTools => _isLoadingTools;
  String? get toolsError => _toolsError;
  int get currentToolsPage => _currentToolsPage;
  int get totalTools => _totalTools;
  bool get hasToolsData => _saleTools.isNotEmpty;
  
  int get totalToolsPages => (_totalTools / _toolsPerPage).ceil();
  bool get canGoToPreviousToolsPage => _currentToolsPage > 1;
  bool get canGoToNextToolsPage => _currentToolsPage < totalToolsPages;

  // Load sale car parts
  Future<void> loadSaleCarParts({int page = 1}) async {
    _isLoadingCarParts = true;
    _carPartsError = null;
    notifyListeners();

    try {
      final result = await _salesService.getSaleCarParts(
        page: page,
        limit: _carPartsPerPage,
      );

      _saleCarParts = result['items'] as List<CarPart>;
      _totalCarParts = result['total'] as int;
      _currentCarPartsPage = page;
      _carPartsError = null;
    } catch (e) {
      _carPartsError = e.toString();
      debugPrint('Error loading sale car parts: $e');
    } finally {
      _isLoadingCarParts = false;
      notifyListeners();
    }
  }

  // Load sale tools
  Future<void> loadSaleTools({int page = 1}) async {
    _isLoadingTools = true;
    _toolsError = null;
    notifyListeners();

    try {
      final result = await _salesService.getSaleTools(
        page: page,
        limit: _toolsPerPage,
      );

      _saleTools = result['items'] as List<ToolProduct>;
      _totalTools = result['total'] as int;
      _currentToolsPage = page;
      _toolsError = null;
    } catch (e) {
      _toolsError = e.toString();
      debugPrint('Error loading sale tools: $e');
    } finally {
      _isLoadingTools = false;
      notifyListeners();
    }
  }

  // Car Parts pagination
  Future<void> goToCarPartsPage(int page) async {
    if (page < 1 || page > totalCarPartsPages || page == _currentCarPartsPage) {
      return;
    }
    await loadSaleCarParts(page: page);
  }

  Future<void> goToPreviousCarPartsPage() async {
    if (canGoToPreviousCarPartsPage) {
      await goToCarPartsPage(_currentCarPartsPage - 1);
    }
  }

  Future<void> goToNextCarPartsPage() async {
    if (canGoToNextCarPartsPage) {
      await goToCarPartsPage(_currentCarPartsPage + 1);
    }
  }

  // Tools pagination
  Future<void> goToToolsPage(int page) async {
    if (page < 1 || page > totalToolsPages || page == _currentToolsPage) {
      return;
    }
    await loadSaleTools(page: page);
  }

  Future<void> goToPreviousToolsPage() async {
    if (canGoToPreviousToolsPage) {
      await goToToolsPage(_currentToolsPage - 1);
    }
  }

  Future<void> goToNextToolsPage() async {
    if (canGoToNextToolsPage) {
      await goToToolsPage(_currentToolsPage + 1);
    }
  }

  // Refresh methods
  Future<void> refreshCarParts() async {
    await loadSaleCarParts(page: _currentCarPartsPage);
  }

  Future<void> refreshTools() async {
    await loadSaleTools(page: _currentToolsPage);
  }

  // Clear cache
  Future<void> clearCache() async {
    await _salesService.clearCache();
  }
}
