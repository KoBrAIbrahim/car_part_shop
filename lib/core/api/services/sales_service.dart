import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/car_part.dart';
import '../models/tool_product.dart';
import 'tools_service.dart';
import 'shopify_service.dart';

class SalesService {
  static String get _shopDomain => dotenv.env['SHOPIFY_STORE_DOMAIN'] ?? '';
  static String get _adminApiAccessToken =>
      dotenv.env['SHOPIFY_ADMIN_API_ACCESS_TOKEN'] ?? '';
  static String get _apiVersion =>
      dotenv.env['SHOPIFY_API_VERSION'] ?? '2025-01';
  static String get _baseUrl => 'https://$_shopDomain/admin/api/$_apiVersion';

  static bool get isConfigured =>
      _shopDomain.isNotEmpty &&
      _adminApiAccessToken.isNotEmpty &&
      _shopDomain != 'your-shop.myshopify.com' &&
      _adminApiAccessToken != 'shpat_your-admin-api-access-token';

  static List<CarPart>? _cachedSaleCarParts;
  static List<ToolProduct>? _cachedSaleTools;
  static DateTime? _carPartsLastFetch;
  static DateTime? _toolsLastFetch;
  static const Duration _cacheDuration = Duration(hours: 2);

  Future<Map<String, dynamic>> getSaleCarParts({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      if (_cachedSaleCarParts != null &&
          _carPartsLastFetch != null &&
          DateTime.now().difference(_carPartsLastFetch!) < _cacheDuration) {
        print('[SALES] Using cached sale car parts (page $page)');
        return _paginateCarParts(_cachedSaleCarParts!, page, limit);
      }

      print('[SALES] Fetching ALL products from Shopify...');

      if (!isConfigured) {
        print('[SALES] WARNING: Shopify API not configured');
        return {'items': <CarPart>[], 'total': 0, 'page': page, 'limit': limit};
      }

      final productsUrl =
          '$_baseUrl/products.json?limit=250&fields=id,title,variants,images,vendor,product_type,tags,status,handle,body_html';
      print('[SALES] Fetching from: $productsUrl');

      final response = await http.get(
        Uri.parse(productsUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Shopify-Access-Token': _adminApiAccessToken,
        },
      );

      if (response.statusCode != 200) {
        print('[SALES] ERROR: Response ${response.statusCode}');
        return {'items': <CarPart>[], 'total': 0, 'page': page, 'limit': limit};
      }

      final data = json.decode(response.body);
      final products = data['products'] as List? ?? [];
      print('[SALES] Fetched ${products.length} products');

      final saleCarParts = <CarPart>[];

      for (final product in products) {
        final productType =
            product['product_type']?.toString().toLowerCase() ?? '';
        if (productType.contains('tool')) continue;

        final variants = product['variants'] as List? ?? [];
        if (variants.isEmpty) continue;

        final variant = variants.first;
        final price =
            double.tryParse(variant['price']?.toString() ?? '0') ?? 0.0;
        final compareAtPrice =
            double.tryParse(variant['compare_at_price']?.toString() ?? '0') ??
            0.0;

        if (compareAtPrice <= 0 || compareAtPrice <= price) continue;

        final metafields = await _fetchProductMetafields(
          product['id'].toString(),
        );
        final metafieldProductType =
            metafields['product_type']?.toString().toLowerCase() ?? '';
        if (metafieldProductType.contains('tool')) continue;

        final partNumber =
            metafields['part_number']?.toString() ??
            metafields['partnumber']?.toString() ??
            product['handle']?.toString() ??
            'PART-${product['id']}';

        final shopifyProduct = ShopifyProduct.fromAdminApiJson(
          product,
          variant,
          partNumber,
          metafields,
        );
        final carPart = CarPart.fromShopifyProduct(shopifyProduct, 0);
        saleCarParts.add(carPart);
      }

      print('[SALES] Found ${saleCarParts.length} car parts on sale');
      _cachedSaleCarParts = saleCarParts;
      _carPartsLastFetch = DateTime.now();

      return _paginateCarParts(saleCarParts, page, limit);
    } catch (e) {
      print('[SALES] ERROR: $e');
      return {'items': <CarPart>[], 'total': 0, 'page': page, 'limit': limit};
    }
  }

  Future<Map<String, dynamic>> _fetchProductMetafields(String productId) async {
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
        final data = json.decode(response.body);
        final metafieldsList = data['metafields'] as List? ?? [];
        final metafields = <String, dynamic>{};
        for (final metafield in metafieldsList) {
          final key = metafield['key']?.toString();
          final value = metafield['value'];
          if (key != null) metafields[key] = value;
        }
        return metafields;
      }
    } catch (e) {
      print('[SALES] WARNING: Error fetching metafields: $e');
    }
    return {};
  }

  Future<Map<String, dynamic>> getSaleTools({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      if (_cachedSaleTools != null &&
          _toolsLastFetch != null &&
          DateTime.now().difference(_toolsLastFetch!) < _cacheDuration) {
        print('[SALES] Using cached sale tools (page $page)');
        return _paginateTools(_cachedSaleTools!, page, limit);
      }

      print('[SALES] Fetching all tools to filter sales...');
      final allTools = await ToolsService.fetchAllToolsProducts();
      final saleTools = allTools.where((tool) => tool.isOnSale).toList();
      print('[SALES] Found ${saleTools.length} tools on sale');

      _cachedSaleTools = saleTools;
      _toolsLastFetch = DateTime.now();

      return _paginateTools(saleTools, page, limit);
    } catch (e) {
      print('[SALES] ERROR: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _paginateCarParts(
    List<CarPart> carParts,
    int page,
    int limit,
  ) {
    final startIndex = (page - 1) * limit;
    final endIndex = (startIndex + limit).clamp(0, carParts.length);
    final paginatedList = startIndex < carParts.length
        ? carParts.sublist(startIndex, endIndex)
        : <CarPart>[];
    return {
      'items': paginatedList,
      'total': carParts.length,
      'page': page,
      'limit': limit,
    };
  }

  Map<String, dynamic> _paginateTools(
    List<ToolProduct> tools,
    int page,
    int limit,
  ) {
    final startIndex = (page - 1) * limit;
    final endIndex = (startIndex + limit).clamp(0, tools.length);
    final paginatedList = startIndex < tools.length
        ? tools.sublist(startIndex, endIndex)
        : <ToolProduct>[];
    return {
      'items': paginatedList,
      'total': tools.length,
      'page': page,
      'limit': limit,
    };
  }

  Future<void> clearCache() async {
    _cachedSaleCarParts = null;
    _cachedSaleTools = null;
    _carPartsLastFetch = null;
    _toolsLastFetch = null;
    print('[SALES] Cleared sales cache');
  }
}
