import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/tool_product.dart';
import '../../services/cache_service.dart';

class ToolsService {
  // Shopify store credentials from environment variables
  static String get _shopDomain => dotenv.env['SHOPIFY_STORE_DOMAIN'] ?? '';
  static String get _adminApiAccessToken =>
      dotenv.env['SHOPIFY_ADMIN_API_ACCESS_TOKEN'] ?? '';
  static String get _apiVersion =>
      dotenv.env['SHOPIFY_API_VERSION'] ?? '2025-01';

  // Admin API endpoint for products
  static String get _baseUrl => 'https://$_shopDomain/admin/api/$_apiVersion';

  // Page size for pagination
  static const int _pageSize = 10;

  // Check if Shopify is properly configured
  static bool get isConfigured =>
      _shopDomain.isNotEmpty &&
      _adminApiAccessToken.isNotEmpty &&
      _shopDomain != 'your-shop.myshopify.com' &&
      _adminApiAccessToken != 'shpat_your-admin-api-access-token';

  /// Fetch tools products from Shopify with pagination
  static Future<List<ToolProduct>> fetchToolsProducts({
    int page = 0,
    int pageSize = _pageSize,
    bool forceRefresh = false,
  }) async {
    try {
      print(
        '🔧 [TOOLS] Fetching tools products (page: ${page + 1}, pageSize: $pageSize)',
      );

      // Skip if not configured
      if (!isConfigured) {
        print('⚠️ [TOOLS] Shopify API not configured, returning empty list');
        return [];
      }

      // Try to get from cache first (much faster)
      if (!forceRefresh) {
        final cachedTools = await _getPagedCachedTools(page, pageSize);
        if (cachedTools.isNotEmpty) {
          print(
            '✅ [TOOLS] Returning ${cachedTools.length} cached tools for page ${page + 1}',
          );
          return cachedTools;
        }
      }

      // If cache miss or force refresh, fetch all tools and cache them
      print('🌐 [TOOLS] Cache miss or refresh - fetching from Shopify...');
      final allTools = await _fetchAllToolsFromShopify(
        forceRefresh: forceRefresh,
      );

      // Calculate pagination slice
      final startIndex = page * pageSize;
      final endIndex = (startIndex + pageSize).clamp(0, allTools.length);

      if (startIndex >= allTools.length) {
        print(
          '✅ [TOOLS] Page ${page + 1} is beyond available data, returning empty list',
        );
        return [];
      }

      final pageTools = allTools.sublist(startIndex, endIndex);

      print(
        '✅ [TOOLS] Returning ${pageTools.length} tools for page ${page + 1} (items ${startIndex + 1}-${endIndex} of ${allTools.length})',
      );
      return pageTools;
    } catch (e) {
      print('❌ [TOOLS] Error fetching tools products: $e');
      return [];
    }
  }

  /// Internal method to fetch all tools from Shopify
  static Future<List<ToolProduct>> _fetchAllToolsFromShopify({
    bool forceRefresh = false,
  }) async {
    // Check if we have cached all tools
    if (!forceRefresh) {
      final cachedAllTools = await _getAllCachedTools();
      if (cachedAllTools.isNotEmpty) {
        print(
          '✅ [TOOLS] Returning ${cachedAllTools.length} cached tools (all)',
        );
        return cachedAllTools;
      }
    }

    // Build URL for fetching all tools products
    final productsUrl =
        '$_baseUrl/products.json'
        '?product_type=tools'
        '&limit=250' // Shopify max limit
        '&fields=id,title,variants,images,vendor,product_type,tags,status,handle,body_html';

    print('🔍 [TOOLS] Fetching all tools from: $productsUrl');

    final response = await http.get(
      Uri.parse(productsUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-Shopify-Access-Token': _adminApiAccessToken,
      },
    );

    if (response.statusCode == 403) {
      print('🔒 [TOOLS] Permission denied. Check Shopify app permissions.');
      return [];
    } else if (response.statusCode != 200) {
      print(
        '❌ [TOOLS] Error response: ${response.statusCode} - ${response.body}',
      );
      return [];
    }

    final data = jsonDecode(response.body);
    final products = data['products'] as List? ?? [];

    // Filter for tools products and convert to ToolProduct objects
    final toolProducts = <ToolProduct>[];

    for (final product in products) {
      final productType =
          product['product_type']?.toString().toLowerCase() ?? '';

      // Only include products with type "tools"
      if (productType == 'tools') {
        final variants = product['variants'] as List? ?? [];
        if (variants.isNotEmpty) {
          // Use first variant for basic product info
          final variant = variants.first;

          // Fetch metafields for this product
          final metafields = await _fetchProductMetafields(
            product['id'].toString(),
          );

          final toolProduct = ToolProduct.fromShopifyJson(
            product,
            variant,
            metafields,
          );
          toolProducts.add(toolProduct);

          print(
            '✅ [TOOLS] Added tool: ${toolProduct.title} | Subcategory: ${toolProduct.subcategory ?? "NONE"}',
          );
        }
      }
    }

    // Cache all tools
    await _cacheAllTools(toolProducts);

    print('✅ [TOOLS] Fetched ${toolProducts.length} total tools from Shopify');
    return toolProducts;
  }

  /// Fetch all tools products without pagination (for search)
  static Future<List<ToolProduct>> fetchAllToolsProducts({
    bool forceRefresh = false,
  }) async {
    try {
      print('🔧 [TOOLS] Fetching ALL tools products for search');
      return await _fetchAllToolsFromShopify(forceRefresh: forceRefresh);
    } catch (e) {
      print('❌ [TOOLS] Error fetching all tools: $e');
      return [];
    }
  }

  /// Search tools products
  static Future<List<ToolProduct>> searchToolsProducts({
    required String query,
    bool forceRefresh = false,
  }) async {
    try {
      print('🔍 [TOOLS] Searching tools for: "$query"');

      // Get all tools first
      final allTools = await fetchAllToolsProducts(forceRefresh: forceRefresh);

      // Filter based on search query
      final searchResults = allTools.where((tool) {
        final searchText = query.toLowerCase();
        return tool.title.toLowerCase().contains(searchText) ||
            tool.description.toLowerCase().contains(searchText) ||
            tool.vendor.toLowerCase().contains(searchText) ||
            tool.tags.any((tag) => tag.toLowerCase().contains(searchText));
      }).toList();

      print('✅ [TOOLS] Found ${searchResults.length} tools matching "$query"');
      return searchResults;
    } catch (e) {
      print('❌ [TOOLS] Error searching tools: $e');
      return [];
    }
  }

  /// Get total count of tools products
  static Future<int> getTotalToolsCount() async {
    try {
      if (!isConfigured) return 0;

      final countUrl = '$_baseUrl/products/count.json?product_type=tools';

      final response = await http.get(
        Uri.parse(countUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Shopify-Access-Token': _adminApiAccessToken,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final count = data['count'] ?? 0;
        print('📊 [TOOLS] Total tools count: $count');
        return count;
      }

      return 0;
    } catch (e) {
      print('❌ [TOOLS] Error getting tools count: $e');
      return 0;
    }
  }

  /// Check if more tools are available for pagination
  static Future<bool> hasMoreTools({
    required int currentPage,
    int pageSize = _pageSize,
  }) async {
    try {
      final totalCount = await getTotalToolsCount();
      final loadedCount = (currentPage + 1) * pageSize;
      return loadedCount < totalCount;
    } catch (e) {
      print('❌ [TOOLS] Error checking if more tools available: $e');
      return false;
    }
  }

  /// Get all unique subcategories from tools (from metafield)
  static Future<List<String>> getAllSubcategories({
    bool forceRefresh = false,
  }) async {
    try {
      print('🔧 [TOOLS] Fetching all subcategories from metafields');

      // Get all tools first
      final allTools = await fetchAllToolsProducts(forceRefresh: forceRefresh);

      print('🔧 [TOOLS] Total tools fetched: ${allTools.length}');

      // Extract unique subcategories from metafield
      final Set<String> uniqueSubcategories = {};
      for (final tool in allTools) {
        if (tool.subcategory != null && tool.subcategory!.isNotEmpty) {
          print(
            '🔧 [TOOLS] Tool "${tool.title}" has subcategory: ${tool.subcategory}',
          );
          uniqueSubcategories.add(tool.subcategory!);
        }
      }

      final subcategories = uniqueSubcategories.toList()..sort();
      print(
        '✅ [TOOLS] Found ${subcategories.length} unique subcategories: $subcategories',
      );
      return subcategories;
    } catch (e) {
      print('❌ [TOOLS] Error fetching subcategories: $e');
      return [];
    }
  }

  /// Fetch tools by subcategory (from metafield)
  static Future<List<ToolProduct>> fetchToolsBySubcategory({
    required String subcategory,
    int page = 0,
    int pageSize = _pageSize,
    bool forceRefresh = false,
  }) async {
    try {
      print(
        '🔧 [TOOLS] Fetching tools for subcategory: "$subcategory" (page: ${page + 1})',
      );

      // Get all tools first
      final allTools = await fetchAllToolsProducts(forceRefresh: forceRefresh);

      // Filter by subcategory metafield
      final filteredTools = subcategory.toLowerCase() == 'all'
          ? allTools
          : subcategory.toLowerCase() == 'other'
          ? allTools.where((tool) {
              // "Other" includes tools with no subcategory or empty subcategory
              return tool.subcategory == null || tool.subcategory!.isEmpty;
            }).toList()
          : allTools.where((tool) {
              return tool.subcategory != null &&
                  tool.subcategory!.toLowerCase() == subcategory.toLowerCase();
            }).toList();

      print(
        '🔧 [TOOLS] Filtered ${filteredTools.length} tools for subcategory "$subcategory"',
      );

      // Apply pagination
      final startIndex = page * pageSize;
      final endIndex = (startIndex + pageSize).clamp(0, filteredTools.length);

      if (startIndex >= filteredTools.length) {
        print(
          '✅ [TOOLS] Page ${page + 1} is beyond available data for subcategory "$subcategory"',
        );
        return [];
      }

      final pageTools = filteredTools.sublist(startIndex, endIndex);

      print(
        '✅ [TOOLS] Returning ${pageTools.length} tools for subcategory "$subcategory" (page ${page + 1})',
      );
      return pageTools;
    } catch (e) {
      print('❌ [TOOLS] Error fetching tools by subcategory: $e');
      return [];
    }
  }

  /// Get total count of tools for a specific subcategory
  static Future<int> getToolsCountBySubcategory({
    required String subcategory,
    bool forceRefresh = false,
  }) async {
    try {
      final allTools = await fetchAllToolsProducts(forceRefresh: forceRefresh);

      final count = subcategory.toLowerCase() == 'all'
          ? allTools.length
          : subcategory.toLowerCase() == 'other'
          ? allTools.where((tool) {
              return tool.subcategory == null || tool.subcategory!.isEmpty;
            }).length
          : allTools.where((tool) {
              return tool.subcategory != null &&
                  tool.subcategory!.toLowerCase() == subcategory.toLowerCase();
            }).length;

      print('📊 [TOOLS] Total tools for subcategory "$subcategory": $count');
      return count;
    } catch (e) {
      print('❌ [TOOLS] Error getting tools count by subcategory: $e');
      return 0;
    }
  }

  // Private helper methods

  /// Fetch metafields for a product
  static Future<Map<String, dynamic>> _fetchProductMetafields(
    String productId,
  ) async {
    try {
      final metafieldsUrl = '$_baseUrl/products/$productId/metafields.json';

      final response = await http.get(
        Uri.parse(metafieldsUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Shopify-Access-Token': _adminApiAccessToken,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final metafieldsList = data['metafields'] as List? ?? [];

        print(
          '🔍 [TOOLS] Product $productId has ${metafieldsList.length} metafields',
        );

        final metafields = <String, dynamic>{};
        for (final metafield in metafieldsList) {
          final key = metafield['key'] as String?;
          final value = metafield['value'];
          if (key != null) {
            metafields[key] = value;
            print('🔍 [TOOLS] Metafield: $key = $value');
          }
        }

        // Check for both 'subcategory' and 'subcategories'
        if (metafields.containsKey('subcategory')) {
          print('✅ [TOOLS] Found subcategory: ${metafields['subcategory']}');
        } else if (metafields.containsKey('subcategories')) {
          print(
            '✅ [TOOLS] Found subcategories (plural): ${metafields['subcategories']}',
          );
        } else {
          print(
            '⚠️ [TOOLS] No subcategory/subcategories metafield found for product $productId',
          );
        }

        return metafields;
      }

      print(
        '❌ [TOOLS] Failed to fetch metafields, status: ${response.statusCode}',
      );
      return {};
    } catch (e) {
      print('❌ [TOOLS] Error fetching metafields for product $productId: $e');
      return {};
    }
  }

  // Cache methods for all tools

  /// Cache all tools
  static Future<void> _cacheAllTools(List<ToolProduct> tools) async {
    try {
      final cacheKey = 'all_tools';
      final data = tools.map((tool) => tool.toJson()).toList();

      await CacheService.cacheData(
        key: cacheKey,
        data: jsonEncode(data),
        expiry: const Duration(hours: 2),
      );

      print('💾 [TOOLS] Cached ${tools.length} tools (all)');
    } catch (e) {
      print('❌ [TOOLS] Error caching all tools: $e');
    }
  }

  /// Get all cached tools
  static Future<List<ToolProduct>> _getAllCachedTools() async {
    try {
      final cacheKey = 'all_tools';
      final cachedData = await CacheService.getCachedData(cacheKey);

      if (cachedData != null) {
        final List<dynamic> data = jsonDecode(cachedData);
        final tools = data.map((item) => ToolProduct.fromJson(item)).toList();
        print('💾 [TOOLS] Retrieved ${tools.length} cached tools (all)');
        return tools;
      }

      return [];
    } catch (e) {
      print('❌ [TOOLS] Error retrieving cached tools: $e');
      return [];
    }
  }

  /// Get paged cached tools (optimized for pagination)
  static Future<List<ToolProduct>> _getPagedCachedTools(
    int page,
    int pageSize,
  ) async {
    try {
      // Get all cached tools
      final allCachedTools = await _getAllCachedTools();

      if (allCachedTools.isEmpty) {
        return [];
      }

      // Calculate pagination slice
      final startIndex = page * pageSize;
      final endIndex = (startIndex + pageSize).clamp(0, allCachedTools.length);

      if (startIndex >= allCachedTools.length) {
        return [];
      }

      final pagedTools = allCachedTools.sublist(startIndex, endIndex);
      print(
        '💾 [TOOLS] Retrieved ${pagedTools.length} cached tools for page ${page + 1} (from ${startIndex + 1} to $endIndex)',
      );
      return pagedTools;
    } catch (e) {
      print('❌ [TOOLS] Error retrieving paged cached tools: $e');
      return [];
    }
  }
}
