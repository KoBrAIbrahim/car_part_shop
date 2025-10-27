import '../models/car_part.dart';
import '../../supabase_service.dart';
import '../../services/cache_service.dart';
import 'shopify_service.dart';

class CarPartsService {
  static const int _pageSize =
      10; // Number of parts per page (changed from 20 to 10)
  static final SupabaseService _supabaseService = SupabaseService();

  // Configuration option to enable/disable Shopify enrichment globally
  static const bool _enableShopifyEnrichment =
      true; // Set to false to disable Shopify calls

  /// Fetch parts for a specific car with pagination - prioritizing Shopify data
  static Future<List<CarPart>> fetchCarParts({
    required int carId,
    int page = 0,
    int pageSize = _pageSize,
    bool enrichWithShopify = true,
    bool forceRefresh = false,
    String? category,
    String? subcategory,
  }) async {
    try {
      print(
        '🔍 [PARTS] Fetching parts for car ID: $carId (page: $page, pageSize: $pageSize, forceRefresh: $forceRefresh)',
      );

      // Check cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedParts = await CacheService.getCachedCarParts(
          carId: carId,
          page: page,
        );

        if (cachedParts != null) {
          print('✅ [PARTS] Returning ${cachedParts.length} parts from cache');
          return cachedParts;
        }
      }

      print('🌐 [PARTS] Cache miss or force refresh - fetching from API');

      final offset = page * pageSize;

      // First, get the list of part numbers from Supabase for this car
      // Apply category/subcategory filters server-side if provided
      var query = _supabaseService.client
          .from('parts')
          .select('part_number, id_cars')
          .eq('id_cars', carId);

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }
      if (subcategory != null && subcategory.isNotEmpty) {
        query = query.eq('subcategory', subcategory);
      }

      final data = await query.range(offset, offset + pageSize - 1).order('part_number');

      print('📦 [PARTS] Found ${data.length} part numbers in Supabase');

      if (data.isEmpty) {
        print('⚠️ [PARTS] No parts found for car ID: $carId');
        return [];
      }

      // Extract part numbers
      final partNumbers = data
          .map((item) => item['part_number'] as String)
          .toList();
      print('🔍 [PARTS] Part numbers to fetch: ${partNumbers.join(", ")}');

      List<CarPart> parts = [];

      // Get detailed data from Shopify (priority source)
      if (_enableShopifyEnrichment && ShopifyService.isConfigured) {
        print('🛒 [SHOPIFY] Fetching detailed product data from Shopify...');

        final shopifyProducts = await ShopifyService.getProductsByPartNumbers(
          partNumbers,
        );

        for (final partNumber in partNumbers) {
          final shopifyProduct = shopifyProducts[partNumber];

          if (shopifyProduct != null) {
            // Create CarPart from Shopify data (this is the primary source now)
            final carPart = CarPart.fromShopifyProduct(shopifyProduct, carId);
            parts.add(carPart);
            print('✅ [SHOPIFY] Created part from Shopify: ${partNumber}');
          } else {
            // Fallback: get basic data from Supabase for this specific part
            print(
              '⚠️ [SHOPIFY] Part not found in Shopify, using Supabase fallback: ${partNumber}',
            );
            try {
              final supabaseData = await _supabaseService.client
                  .from('parts')
                  .select('*')
                  .eq('part_number', partNumber)
                  .eq('id_cars', carId)
                  .single();

              // If category/subcategory filters are present ensure fallback matches them
              if (category != null && category.isNotEmpty) {
                if (supabaseData['category'] != category) {
                  // Skip this fallback as it doesn't match filters
                  continue;
                }
              }
              if (subcategory != null && subcategory.isNotEmpty) {
                if (supabaseData['subcategory'] != subcategory) {
                  continue;
                }
              }

              final carPart = CarPart.fromJson(supabaseData);
              parts.add(carPart);
              print(
                '✅ [SUPABASE] Created part from Supabase fallback: ${partNumber}',
              );
            } catch (e) {
              print(
                '❌ [SUPABASE] Error fetching fallback data for ${partNumber}: $e',
              );
              // Create minimal part with available data
              final carPart = CarPart.createMinimal(partNumber, carId);
              parts.add(carPart);
            }
          }
        }

        print(
          '✅ [PARTS] Created ${parts.length} parts (Shopify: ${shopifyProducts.length}, Fallbacks: ${parts.length - shopifyProducts.length})',
        );
      } else {
        // Shopify not configured, use traditional Supabase-only approach
        print('⚠️ [SHOPIFY] Shopify not configured, using Supabase-only data');

        final supabaseData = await _supabaseService.client
            .from('parts')
            .select('*')
            .eq('id_cars', carId)
            .range(offset, offset + pageSize - 1)
            .order('part_number');

        parts = supabaseData
            .map((json) {
              try {
                return CarPart.fromJson(json);
              } catch (e) {
                print('❌ [PARTS] Error parsing part record: $json');
                print('❌ [PARTS] Parse error: $e');
                return null;
              }
            })
            .whereType<CarPart>()
            .toList();

        print(
          '✅ [PARTS] Successfully parsed ${parts.length} parts from Supabase',
        );
      }

      // Cache the results
      await CacheService.cacheCarParts(carId: carId, parts: parts, page: page);

      return parts;
    } catch (e) {
      print('❌ [PARTS] Error fetching car parts: $e');
      throw Exception('Failed to fetch car parts: $e');
    }
  }

  /// Get total count of parts for a car (for pagination)
  static Future<int> getTotalPartsCount(int carId,
      {String? category, String? subcategory}) async {
    try {
      print('🔢 [PARTS] Getting total count for car ID: $carId');

      var query = _supabaseService.client.from('parts').select('*').eq('id_cars', carId);
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }
      if (subcategory != null && subcategory.isNotEmpty) {
        query = query.eq('subcategory', subcategory);
      }

      final response = await query;

      final count = (response as List).length;
      print('📊 [PARTS] Total parts count: $count');
      return count;
    } catch (e) {
      print('❌ [PARTS] Error getting parts count: $e');
      return 0;
    }
  }

  /// Check if more parts are available (for lazy loading)
  static Future<bool> hasMoreParts({
    required int carId,
    required int currentPage,
    int pageSize = _pageSize,
  }) async {
    try {
      final totalCount = await getTotalPartsCount(carId);
      final loadedCount = (currentPage + 1) * pageSize;
      return loadedCount < totalCount;
    } catch (e) {
      print('❌ [PARTS] Error checking if more parts available: $e');
      return false;
    }
  }

  /// Search parts by part number or description - prioritizing Shopify data
  static Future<List<CarPart>> searchCarParts({
    required int carId,
    required String searchQuery,
    int page = 0,
    int pageSize = _pageSize,
    bool enrichWithShopify = true,
    bool forceRefresh = false,
  }) async {
    try {
      print(
        '🔍 [PARTS] Searching parts for car ID: $carId, query: "$searchQuery", forceRefresh: $forceRefresh',
      );

      // Check cache first (unless force refresh is requested)
      if (!forceRefresh) {
        final cachedParts = await CacheService.getCachedCarParts(
          carId: carId,
          page: page,
          searchQuery: searchQuery,
        );

        if (cachedParts != null) {
          print(
            '✅ [PARTS] Returning ${cachedParts.length} search results from cache',
          );
          return cachedParts;
        }
      }

      print('🌐 [PARTS] Cache miss or force refresh - searching via API');

      final offset = page * pageSize;

      // Get part numbers from Supabase that match the search
      final data = await _supabaseService.client
          .from('parts')
          .select('part_number, id_cars') // Only get essential fields
          .eq('id_cars', carId)
          .or('part_number.ilike.%$searchQuery%')
          .range(offset, offset + pageSize - 1)
          .order('part_number');

      print('🔍 [PARTS] Search found ${data.length} matching part numbers');

      if (data.isEmpty) {
        return [];
      }

      // Extract part numbers
      final partNumbers = data
          .map((item) => item['part_number'] as String)
          .toList();

      List<CarPart> parts = [];

      // Get detailed data from Shopify (priority source)
      if (_enableShopifyEnrichment && ShopifyService.isConfigured) {
        print('🛒 [SHOPIFY] Fetching detailed search results from Shopify...');

        final shopifyProducts = await ShopifyService.getProductsByPartNumbers(
          partNumbers,
        );

        for (final partNumber in partNumbers) {
          final shopifyProduct = shopifyProducts[partNumber];

          if (shopifyProduct != null) {
            // Also search in Shopify product title and description
            final searchLower = searchQuery.toLowerCase();
            final titleMatch = shopifyProduct.title.toLowerCase().contains(
              searchLower,
            );
            final descriptionMatch = shopifyProduct.description
                .toLowerCase()
                .contains(searchLower);
            final partNumberMatch = partNumber.toLowerCase().contains(
              searchLower,
            );

            if (titleMatch || descriptionMatch || partNumberMatch) {
              final carPart = CarPart.fromShopifyProduct(shopifyProduct, carId);
              parts.add(carPart);
              print(
                '✅ [SHOPIFY] Added search result from Shopify: ${partNumber}',
              );
            }
          } else {
            // Fallback: get data from Supabase for this specific part
            try {
              final supabaseData = await _supabaseService.client
                  .from('parts')
                  .select('*')
                  .eq('part_number', partNumber)
                  .eq('id_cars', carId)
                  .single();

              final carPart = CarPart.fromJson(supabaseData);
              parts.add(carPart);
              print(
                '✅ [SUPABASE] Added search result from Supabase fallback: ${partNumber}',
              );
            } catch (e) {
              print(
                '❌ [SUPABASE] Error fetching search fallback for ${partNumber}: $e',
              );
            }
          }
        }
      } else {
        // Shopify not configured, use traditional Supabase search
        print(
          '⚠️ [SHOPIFY] Shopify not configured, using Supabase-only search',
        );

        final supabaseData = await _supabaseService.client
            .from('parts')
            .select('*')
            .eq('id_cars', carId)
            .or(
              'part_number.ilike.%$searchQuery%,description.ilike.%$searchQuery%',
            )
            .range(offset, offset + pageSize - 1)
            .order('part_number');

        parts = supabaseData
            .map((json) {
              try {
                return CarPart.fromJson(json);
              } catch (e) {
                print('❌ [PARTS] Error parsing search result: $json');
                return null;
              }
            })
            .whereType<CarPart>()
            .toList();
      }

      // Cache the search results
      await CacheService.cacheCarParts(
        carId: carId,
        parts: parts,
        page: page,
        searchQuery: searchQuery,
      );

      print('✅ [PARTS] Search completed: ${parts.length} results');
      return parts;
    } catch (e) {
      print('❌ [PARTS] Error searching car parts: $e');
      throw Exception('Failed to search car parts: $e');
    }
  }
}
