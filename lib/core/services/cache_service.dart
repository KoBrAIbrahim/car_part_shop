import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../api/models/car_part.dart';

class CacheEntry {
  final String data;
  final DateTime timestamp;
  final Duration expiryDuration;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.expiryDuration,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > expiryDuration;

  Map<String, dynamic> toJson() => {
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'expiryDuration': expiryDuration.inMilliseconds,
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      expiryDuration: Duration(milliseconds: json['expiryDuration']),
    );
  }
}

class CacheService {
  static const String _boxName = 'car_parts_cache';
  static const Duration _defaultExpiry = Duration(hours: 1);
  static Box<String>? _box;

  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox<String>(_boxName);
      print('✅ [CACHE] Cache service initialized successfully');
    } catch (e) {
      print('❌ [CACHE] Failed to initialize cache service: $e');
      rethrow;
    }
  }

  /// Generate cache key for car parts
  static String _generateCacheKey({
    required int carId,
    int? page,
    String? searchQuery,
  }) {
    final key = 'car_parts_${carId}';
    if (searchQuery != null && searchQuery.isNotEmpty) {
      return '${key}_search_${searchQuery.hashCode}';
    }
    if (page != null) {
      return '${key}_page_$page';
    }
    return '${key}_all';
  }

  /// Cache car parts data
  static Future<void> cacheCarParts({
    required int carId,
    required List<CarPart> parts,
    int? page,
    String? searchQuery,
    Duration? customExpiry,
  }) async {
    if (_box == null) {
      print('⚠️ [CACHE] Cache not initialized, skipping cache operation');
      return;
    }

    try {
      final key = _generateCacheKey(
        carId: carId,
        page: page,
        searchQuery: searchQuery,
      );

      // Convert parts to JSON
      final partsJson = parts.map((part) => part.toJson()).toList();
      final dataString = jsonEncode(partsJson);

      // Create cache entry
      final cacheEntry = CacheEntry(
        data: dataString,
        timestamp: DateTime.now(),
        expiryDuration: customExpiry ?? _defaultExpiry,
      );

      // Store in cache
      await _box!.put(key, jsonEncode(cacheEntry.toJson()));

      print('✅ [CACHE] Cached ${parts.length} parts for key: $key');
    } catch (e) {
      print('❌ [CACHE] Failed to cache car parts: $e');
    }
  }

  /// Get cached car parts data
  static Future<List<CarPart>?> getCachedCarParts({
    required int carId,
    int? page,
    String? searchQuery,
  }) async {
    if (_box == null) {
      print('⚠️ [CACHE] Cache not initialized, returning null');
      return null;
    }

    try {
      final key = _generateCacheKey(
        carId: carId,
        page: page,
        searchQuery: searchQuery,
      );

      final cachedString = _box!.get(key);
      if (cachedString == null) {
        print('📭 [CACHE] No cached data found for key: $key');
        return null;
      }

      // Parse cache entry
      final cacheEntryJson = jsonDecode(cachedString);
      final cacheEntry = CacheEntry.fromJson(cacheEntryJson);

      // Check if expired
      if (cacheEntry.isExpired) {
        print('⏰ [CACHE] Cache expired for key: $key, removing...');
        await _box!.delete(key);
        return null;
      }

      // Parse car parts data
      final partsJsonList = jsonDecode(cacheEntry.data) as List;
      final parts = partsJsonList
          .map((json) => CarPart.fromJson(json))
          .toList();

      print('✅ [CACHE] Retrieved ${parts.length} cached parts for key: $key');
      return parts;
    } catch (e) {
      print('❌ [CACHE] Failed to get cached car parts: $e');
      return null;
    }
  }

  /// Check if cache exists and is valid
  static Future<bool> isCacheValid({
    required int carId,
    int? page,
    String? searchQuery,
  }) async {
    if (_box == null) return false;

    try {
      final key = _generateCacheKey(
        carId: carId,
        page: page,
        searchQuery: searchQuery,
      );

      final cachedString = _box!.get(key);
      if (cachedString == null) return false;

      final cacheEntryJson = jsonDecode(cachedString);
      final cacheEntry = CacheEntry.fromJson(cacheEntryJson);

      return !cacheEntry.isExpired;
    } catch (e) {
      print('❌ [CACHE] Error checking cache validity: $e');
      return false;
    }
  }

  /// Clear cache for specific car
  static Future<void> clearCarCache(int carId) async {
    if (_box == null) return;

    try {
      final keys = _box!.keys
          .where((key) => key.toString().contains('car_parts_$carId'))
          .toList();

      for (final key in keys) {
        await _box!.delete(key);
      }

      print(
        '✅ [CACHE] Cleared cache for car ID: $carId (${keys.length} entries)',
      );
    } catch (e) {
      print('❌ [CACHE] Failed to clear car cache: $e');
    }
  }

  /// Clear all cache
  static Future<void> clearAllCache() async {
    if (_box == null) return;

    try {
      await _box!.clear();
      print('✅ [CACHE] Cleared all cache');
    } catch (e) {
      print('❌ [CACHE] Failed to clear all cache: $e');
    }
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    if (_box == null) return {'error': 'Cache not initialized'};

    try {
      final totalKeys = _box!.keys.length;
      int validEntries = 0;
      int expiredEntries = 0;

      for (final key in _box!.keys) {
        try {
          final cachedString = _box!.get(key);
          if (cachedString != null) {
            final cacheEntryJson = jsonDecode(cachedString);
            final cacheEntry = CacheEntry.fromJson(cacheEntryJson);

            if (cacheEntry.isExpired) {
              expiredEntries++;
            } else {
              validEntries++;
            }
          }
        } catch (e) {
          expiredEntries++;
        }
      }

      return {
        'totalKeys': totalKeys,
        'validEntries': validEntries,
        'expiredEntries': expiredEntries,
        'defaultExpiryHours': _defaultExpiry.inHours,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Clean expired cache entries
  static Future<void> cleanExpiredCache() async {
    if (_box == null) return;

    try {
      final keysToDelete = <String>[];

      for (final key in _box!.keys) {
        try {
          final cachedString = _box!.get(key);
          if (cachedString != null) {
            final cacheEntryJson = jsonDecode(cachedString);
            final cacheEntry = CacheEntry.fromJson(cacheEntryJson);

            if (cacheEntry.isExpired) {
              keysToDelete.add(key.toString());
            }
          }
        } catch (e) {
          keysToDelete.add(key.toString());
        }
      }

      for (final key in keysToDelete) {
        await _box!.delete(key);
      }

      print('✅ [CACHE] Cleaned ${keysToDelete.length} expired cache entries');
    } catch (e) {
      print('❌ [CACHE] Failed to clean expired cache: $e');
    }
  }

  /// Generic cache data method
  static Future<void> cacheData({
    required String key,
    required String data,
    Duration? expiry,
  }) async {
    if (_box == null) {
      print('⚠️ [CACHE] Cache not initialized, skipping cache operation');
      return;
    }

    try {
      final cacheEntry = CacheEntry(
        data: data,
        timestamp: DateTime.now(),
        expiryDuration: expiry ?? _defaultExpiry,
      );

      await _box!.put(key, jsonEncode(cacheEntry.toJson()));
      print('✅ [CACHE] Cached data for key: $key');
    } catch (e) {
      print('❌ [CACHE] Failed to cache data for key $key: $e');
    }
  }

  /// Generic get cached data method
  static Future<String?> getCachedData(String key) async {
    if (_box == null) {
      print('⚠️ [CACHE] Cache not initialized, returning null');
      return null;
    }

    try {
      final cachedString = _box!.get(key);
      if (cachedString == null) {
        print('📭 [CACHE] No cached data found for key: $key');
        return null;
      }

      final cacheEntryJson = jsonDecode(cachedString);
      final cacheEntry = CacheEntry.fromJson(cacheEntryJson);

      if (cacheEntry.isExpired) {
        print('⏰ [CACHE] Cache expired for key: $key, removing...');
        await _box!.delete(key);
        return null;
      }

      print('✅ [CACHE] Retrieved cached data for key: $key');
      return cacheEntry.data;
    } catch (e) {
      print('❌ [CACHE] Failed to get cached data for key $key: $e');
      return null;
    }
  }
}
