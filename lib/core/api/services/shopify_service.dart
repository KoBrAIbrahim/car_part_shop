import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ShopifyService {
  // Shopify store credentials from environment variables only
  static String get _shopDomain => dotenv.env['SHOPIFY_STORE_DOMAIN'] ?? '';
  static String get _adminApiAccessToken =>
      dotenv.env['SHOPIFY_ADMIN_API_ACCESS_TOKEN'] ?? '';
  static String get _apiVersion =>
      dotenv.env['SHOPIFY_API_VERSION'] ?? '2025-01';

  // Admin API endpoint for products
  static String get _baseUrl => 'https://$_shopDomain/admin/api/$_apiVersion';

  // Check if Shopify is properly configured
  static bool get isConfigured =>
      _shopDomain.isNotEmpty &&
      _adminApiAccessToken.isNotEmpty &&
      _shopDomain != 'your-shop.myshopify.com' &&
      _adminApiAccessToken != 'shpat_your-admin-api-access-token';

  /// Get product details by SKU/part number from Shopify Admin API
  static Future<ShopifyProduct?> getProductByPartNumber(
    String partNumber,
  ) async {
    // Skip if not configured
    if (!isConfigured) {
      print(
        '⚠️ [SHOPIFY] Shopify Admin API not configured, skipping API call for: $partNumber',
      );
      return null;
    }

    try {
      print(
        '🛒 [SHOPIFY] Fetching product for part number: $partNumber using Admin API',
      );

      // Use the products endpoint to get all products and search manually
      // This is a workaround for Shopify's unreliable SKU search
      final productsUrl =
          '$_baseUrl/products.json'
          '?fields=id,title,variants,images,vendor,product_type,tags,status,handle,body_html'
          '&limit=250';

      print(
        '🔍 [SHOPIFY] Fetching all products to search for SKU: $partNumber',
      );

      final productsResponse = await http.get(
        Uri.parse(productsUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Shopify-Access-Token': _adminApiAccessToken,
        },
      );

      print(
        '📊 [SHOPIFY] Products response status: ${productsResponse.statusCode}',
      );

      if (productsResponse.statusCode == 403) {
        try {
          final errorData = jsonDecode(productsResponse.body);
          final errorMessage =
              errorData['errors']?.toString() ?? 'Unknown permission error';

          if (errorMessage.contains('merchant approval')) {
            print('🔒 [SHOPIFY] PERMISSION REQUIRED: $errorMessage');
            print(
              '💡 [SHOPIFY] Go to Shopify Admin → Settings → Apps and sales channels',
            );
            print(
              '📝 [SHOPIFY] Find your private app and approve "read_products" scope',
            );
          } else {
            print('❌ [SHOPIFY] Permission denied: $errorMessage');
          }
        } catch (e) {
          print('❌ [SHOPIFY] Permission error (403): ${productsResponse.body}');
        }
        return null;
      } else if (productsResponse.statusCode != 200) {
        print('❌ [SHOPIFY] Error response: ${productsResponse.body}');
        return null;
      }

      final productsData = jsonDecode(productsResponse.body);
      final products = productsData['products'] as List?;

      if (products == null || products.isEmpty) {
        print('📭 [SHOPIFY] No products found');
        return null;
      }

      // Search through all products and their variants for the exact SKU
      for (final product in products) {
        final variants = product['variants'] as List?;
        if (variants != null) {
          for (final variant in variants) {
            final variantSku = variant['sku']?.toString() ?? '';
            if (variantSku == partNumber) {
              print('✅ [SHOPIFY] Found exact SKU match: $partNumber');

              // Fetch metafields for this product
              final productId = product['id'];
              final metafieldsUrl =
                  '$_baseUrl/products/$productId/metafields.json';

              final metafieldsResponse = await http.get(
                Uri.parse(metafieldsUrl),
                headers: {
                  'Content-Type': 'application/json',
                  'X-Shopify-Access-Token': _adminApiAccessToken,
                },
              );

              Map<String, dynamic> metafields = {};
              if (metafieldsResponse.statusCode == 200) {
                final metafieldsData = jsonDecode(metafieldsResponse.body);
                final metafieldsList =
                    metafieldsData['metafields'] as List? ?? [];

                for (final metafield in metafieldsList) {
                  final key = metafield['key'] as String?;
                  final value = metafield['value'];
                  if (key != null) {
                    metafields[key] = value;
                  }
                }
                print(
                  '📋 [SHOPIFY] Found ${metafields.length} metafields: ${metafields.keys}',
                );
              } else {
                print(
                  '⚠️ [SHOPIFY] Could not fetch metafields: ${metafieldsResponse.statusCode}',
                );
              }

              // Create ShopifyProduct from Admin API response with metafields
              final shopifyProduct = ShopifyProduct.fromAdminApiJson(
                product,
                variant,
                partNumber,
                metafields,
              );

              print(
                '✅ [SHOPIFY] Successfully created product: ${shopifyProduct.title}',
              );
              return shopifyProduct;
            }
          }
        }
      }

      print('📭 [SHOPIFY] No exact match found for SKU: $partNumber');
    } catch (e) {
      print('❌ [SHOPIFY] Error fetching product: $e');
      return null;
    }

    return null;
  }

  /// Get multiple products by part numbers (batch request using Admin API)
  static Future<Map<String, ShopifyProduct>> getProductsByPartNumbers(
    List<String> partNumbers,
  ) async {
    final results = <String, ShopifyProduct>{};

    // Skip if not configured
    if (!isConfigured) {
      print(
        '⚠️ [SHOPIFY] Shopify Admin API not configured, skipping batch request for ${partNumbers.length} parts',
      );
      return results;
    }

    print(
      '🛒 [SHOPIFY] Starting Admin API batch request for ${partNumbers.length} parts',
    );

    // Process in smaller batches to respect Admin API rate limits (40 requests per app per store per minute)
    const batchSize = 5;
    for (int i = 0; i < partNumbers.length; i += batchSize) {
      final batch = partNumbers.skip(i).take(batchSize).toList();

      // Process batch concurrently but with rate limiting
      final futures = batch.map((partNumber) async {
        final product = await getProductByPartNumber(partNumber);
        return MapEntry(partNumber, product);
      });

      final batchResults = await Future.wait(futures);

      for (final entry in batchResults) {
        if (entry.value != null) {
          results[entry.key] = entry.value!;
        }
      }

      // Longer delay between batches to respect Admin API rate limits
      if (i + batchSize < partNumbers.length) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    print(
      '✅ [SHOPIFY] Admin API fetched ${results.length}/${partNumbers.length} products',
    );
    return results;
  }
}

class ShopifyProduct {
  final String id;
  final String title;
  final String description;
  final String vendor;
  final String productType;
  final List<String> tags;
  final String partNumber;

  // Variant info (first/primary variant)
  final String variantId;
  final String variantTitle;
  final double price;
  final double? compareAtPrice;
  final String currencyCode;
  final bool availableForSale;
  final int? quantityAvailable;

  // Images
  final List<String> imageUrls;
  final String? primaryImageUrl;

  // Metafields from Shopify
  final Map<String, dynamic> metafields;
  final String? garagePrice;
  final String? metafieldProductType;
  final String? metafieldPartNumber;
  final String? subcategories;

  ShopifyProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.vendor,
    required this.productType,
    required this.tags,
    required this.partNumber,
    required this.variantId,
    required this.variantTitle,
    required this.price,
    this.compareAtPrice,
    required this.currencyCode,
    required this.availableForSale,
    this.quantityAvailable,
    required this.imageUrls,
    this.primaryImageUrl,
    this.metafields = const {},
    this.garagePrice,
    this.metafieldProductType,
    this.metafieldPartNumber,
    this.subcategories,
  });

  factory ShopifyProduct.fromAdminApiJson(
    Map<String, dynamic> productJson,
    Map<String, dynamic> variantJson,
    String partNumber,
    Map<String, dynamic> metafields,
  ) {
    // Extract images from product
    final images = productJson['images'] as List? ?? [];
    final imageUrls = images.map((img) => img['src'] as String).toList();

    print(
      '📷 [SHOPIFY] Found ${imageUrls.length} images for product: ${productJson['title']}',
    );
    if (imageUrls.isNotEmpty) {
      print(
        '📷 [SHOPIFY] Image URLs: ${imageUrls.take(3).join(", ")}${imageUrls.length > 3 ? "..." : ""}',
      );
    }

    // Parse price from variant
    final price =
        double.tryParse(variantJson['price']?.toString() ?? '0') ?? 0.0;
    final compareAtPrice = variantJson['compare_at_price'] != null
        ? double.tryParse(variantJson['compare_at_price']?.toString() ?? '0')
        : null;

    // Extract metafields
    final garagePrice = metafields['garage_price']?.toString();
    final metafieldProductType = metafields['product_type']?.toString();
    final metafieldPartNumber = metafields['part_number']?.toString();
    final subcategories = metafields['subcategories']?.toString();

    return ShopifyProduct(
      id: productJson['id']?.toString() ?? '',
      title: productJson['title'] ?? '',
      description: _cleanDescription(productJson['body_html'] ?? ''),
      vendor: productJson['vendor'] ?? '',
      productType: productJson['product_type'] ?? '',
      tags:
          (productJson['tags'] as String?)
              ?.split(',')
              .map((tag) => tag.trim())
              .toList() ??
          [],
      partNumber: partNumber,
      variantId: variantJson['id']?.toString() ?? '',
      variantTitle: variantJson['title'] ?? '',
      price: price,
      compareAtPrice: compareAtPrice,
      currencyCode: 'ILS', // Israeli Shekel based on your store currency
      availableForSale: variantJson['available'] ?? false,
      quantityAvailable: variantJson['inventory_quantity'],
      imageUrls: imageUrls,
      primaryImageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
      metafields: metafields,
      garagePrice: garagePrice,
      metafieldProductType: metafieldProductType,
      metafieldPartNumber: metafieldPartNumber,
      subcategories: subcategories,
    );
  }

  factory ShopifyProduct.fromJson(
    Map<String, dynamic> json,
    String partNumber,
  ) {
    // Extract variant data (use first variant)
    final variants = json['variants']['edges'] as List;
    final variant = variants.isNotEmpty ? variants.first['node'] : {};

    // Extract images
    final images = json['images']['edges'] as List;
    final imageUrls = images
        .map((img) => img['node']['url'] as String)
        .toList();

    // Parse price
    final priceData = variant['price'];
    final price =
        double.tryParse(priceData?['amount']?.toString() ?? '0') ?? 0.0;

    final compareAtPriceData = variant['compareAtPrice'];
    final compareAtPrice = compareAtPriceData != null
        ? double.tryParse(compareAtPriceData['amount']?.toString() ?? '0')
        : null;

    return ShopifyProduct(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: _cleanDescription(json['description'] ?? ''),
      vendor: json['vendor'] ?? '',
      productType: json['productType'] ?? '',
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      partNumber: partNumber,
      variantId: variant['id'] ?? '',
      variantTitle: variant['title'] ?? '',
      price: price,
      compareAtPrice: compareAtPrice,
      currencyCode: priceData?['currencyCode'] ?? 'USD',
      availableForSale: variant['availableForSale'] ?? false,
      quantityAvailable: variant['quantityAvailable'],
      imageUrls: imageUrls,
      primaryImageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
    );
  }

  static String _cleanDescription(String description) {
    // Remove HTML tags and clean up description
    return description
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  String get displayPrice {
    // Use garage_price from metafields if available, otherwise use regular price
    if (garagePrice != null) {
      final gPrice = double.tryParse(garagePrice!) ?? 0.0;
      if (gPrice > 0) {
        return '₪${gPrice.toStringAsFixed(0)} (Garage Price)';
      }
    }

    if (compareAtPrice != null && compareAtPrice! > price) {
      return '₪${price.toStringAsFixed(0)} (was ₪${compareAtPrice!.toStringAsFixed(0)})';
    }
    return '₪${price.toStringAsFixed(0)}';
  }

  String get stockStatus {
    if (quantityAvailable != null) {
      if (quantityAvailable! > 10) {
        return 'In Stock (${quantityAvailable}+ available)';
      } else if (quantityAvailable! > 0) {
        return 'In Stock ($quantityAvailable available)';
      } else {
        return 'Out of Stock';
      }
    }
    // Fallback to availability flag when quantity is unknown
    if (!availableForSale) return 'Out of Stock';
    return 'In Stock';
  }

  bool get isInStock {
    // Prioritize quantity over availability flag for better UX
    // If quantity is available and > 0, consider it in stock
    if (quantityAvailable != null && quantityAvailable! > 0) {
      return true;
    }
    // Fallback to availability flag
    return availableForSale && (quantityAvailable ?? 1) > 0;
  }

  bool get isOnSale => compareAtPrice != null && compareAtPrice! > price;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'vendor': vendor,
      'productType': productType,
      'tags': tags,
      'partNumber': partNumber,
      'variantId': variantId,
      'variantTitle': variantTitle,
      'price': price,
      'compareAtPrice': compareAtPrice,
      'currencyCode': currencyCode,
      'availableForSale': availableForSale,
      'quantityAvailable': quantityAvailable,
      'imageUrls': imageUrls,
      'primaryImageUrl': primaryImageUrl,
      'metafields': metafields,
      'garagePrice': garagePrice,
      'metafieldProductType': metafieldProductType,
      'metafieldPartNumber': metafieldPartNumber,
      'subcategories': subcategories,
    };
  }

  // Get the best available product type (metafield first, then product type)
  String get bestProductType {
    if (metafieldProductType != null && metafieldProductType!.isNotEmpty) {
      return metafieldProductType!;
    }
    return productType;
  }

  // Get the best available part number (metafield first, then fallback)
  String get bestPartNumber {
    if (metafieldPartNumber != null && metafieldPartNumber!.isNotEmpty) {
      return metafieldPartNumber!;
    }
    return partNumber;
  }

  /// Convert to JSON for cache storage - includes all pricing data
  Map<String, dynamic> toCacheJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'vendor': vendor,
      'productType': productType,
      'tags': tags,
      'partNumber': partNumber,
      'variantId': variantId,
      'variantTitle': variantTitle,
      'price': price,
      'compareAtPrice': compareAtPrice,
      'currencyCode': currencyCode,
      'availableForSale': availableForSale,
      'quantityAvailable': quantityAvailable,
      'imageUrls': imageUrls,
      'primaryImageUrl': primaryImageUrl,
      'metafields': metafields,
      'garagePrice': garagePrice,
      'metafieldProductType': metafieldProductType,
      'metafieldPartNumber': metafieldPartNumber,
      'subcategories': subcategories,
    };
  }

  /// Create from cached JSON - restores all pricing data
  factory ShopifyProduct.fromCacheJson(Map<String, dynamic> json) {
    return ShopifyProduct(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      vendor: json['vendor'] ?? '',
      productType: json['productType'] ?? '',
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      partNumber: json['partNumber'] ?? '',
      variantId: json['variantId'] ?? '',
      variantTitle: json['variantTitle'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      compareAtPrice: (json['compareAtPrice'] as num?)?.toDouble(),
      currencyCode: json['currencyCode'] ?? 'ILS',
      availableForSale: json['availableForSale'] ?? false,
      quantityAvailable: json['quantityAvailable'],
      imageUrls: (json['imageUrls'] as List?)?.cast<String>() ?? [],
      primaryImageUrl: json['primaryImageUrl'],
      metafields: (json['metafields'] as Map<String, dynamic>?) ?? {},
      garagePrice: json['garagePrice'],
      metafieldProductType: json['metafieldProductType'],
      metafieldPartNumber: json['metafieldPartNumber'],
      subcategories: json['subcategories'],
    );
  }
}
