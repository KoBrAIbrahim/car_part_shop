import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/models/car_make.dart';
import '../api/services/car_api_service.dart';

class CarMakesProvider extends ChangeNotifier {
  static const String _cacheKey = 'cached_car_makes';
  static const String _cacheTimestampKey = 'cached_car_makes_timestamp';
  static const Duration _cacheExpiry = Duration(days: 1); // Cache for 1 day

  List<CarMake> _carMakes = [];
  bool _isLoading = false;
  String? _error;

  List<CarMake> get carMakes => _carMakes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _carMakes.isNotEmpty;

  /// Load car makes with caching
  Future<void> loadCarMakes({bool forceRefresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 [CACHE] Loading car makes (forceRefresh: $forceRefresh)...');

      // Try to load from cache first
      if (!forceRefresh) {
        final cachedData = await _loadFromCache();
        if (cachedData != null) {
          print('✅ [CACHE] Loaded ${cachedData.length} car makes from cache');
          _carMakes = cachedData;
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      print('🌐 [API] Fetching fresh data from Supabase...');
      // Load from API
      final makes = await CarApiService.fetchCarMakesFromSupabase();
      _carMakes = makes;

      // Cache the data
      await _saveToCache(makes);
      print('💾 [CACHE] Saved ${makes.length} car makes to cache');
    } catch (e) {
      print('❌ [ERROR] Failed to load car makes: $e');
      _error = e.toString();

      // Try to load from cache as fallback
      final cachedData = await _loadFromCache();
      if (cachedData != null) {
        print('🔄 [FALLBACK] Using cached data as fallback');
        _carMakes = cachedData;
        _error = null; // Clear error if we have cached data
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load data from local cache
  Future<List<CarMake>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      final timestampString = prefs.getString(_cacheTimestampKey);

      if (cachedJson == null || timestampString == null) {
        print('📭 [CACHE] No cached data found');
        return null;
      }

      final timestamp = DateTime.parse(timestampString);
      final now = DateTime.now();
      final cacheAge = now.difference(timestamp);

      print(
        '📅 [CACHE] Cache age: ${cacheAge.inHours} hours, ${cacheAge.inMinutes % 60} minutes',
      );

      // Check if cache is expired (older than 1 day)
      if (cacheAge > _cacheExpiry) {
        print(
          '⏰ [CACHE] Cache expired (older than 1 day), will fetch fresh data',
        );
        return null;
      }

      print('✅ [CACHE] Cache is valid, loading from storage');
      final List<dynamic> jsonList = json.decode(cachedJson);
      return jsonList.map((json) => CarMake.fromJson(json)).toList();
    } catch (e) {
      print('❌ [CACHE] Error loading from cache: $e');
      debugPrint('Error loading from cache: $e');
      return null;
    }
  }

  /// Save data to local cache
  Future<void> _saveToCache(List<CarMake> makes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = makes.map((make) => make.toJson()).toList();
      final jsonString = json.encode(jsonList);

      await prefs.setString(_cacheKey, jsonString);
      await prefs.setString(
        _cacheTimestampKey,
        DateTime.now().toIso8601String(),
      );

      print('💾 [CACHE] Successfully saved ${makes.length} car makes to cache');
      print('📅 [CACHE] Cache will expire in 24 hours');
    } catch (e) {
      print('❌ [CACHE] Error saving to cache: $e');
      debugPrint('Error saving to cache: $e');
    }
  }

  /// Clear cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimestampKey);
      print('🗑️ [CACHE] Cache cleared successfully');
    } catch (e) {
      print('❌ [CACHE] Error clearing cache: $e');
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Get logo URL for a car make
  String? getLogoUrl(String makeName) {
    final carMake = _carMakes.firstWhere(
      (make) => make.name.toLowerCase() == makeName.toLowerCase(),
      orElse: () => CarMake(id: 0, name: '', logoUrl: ''),
    );
    return carMake.logoUrl.isNotEmpty ? carMake.logoUrl : null;
  }

  /// Refresh data from API
  Future<void> refresh() async {
    print('🔄 [REFRESH] Forcing refresh of car makes data...');
    await loadCarMakes(forceRefresh: true);
  }
}
