class ToolProduct {
  final String id;
  final String title;
  final String description;
  final String vendor;
  final String productType;
  final List<String> tags;

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
  final String? metafieldDescription;

  ToolProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.vendor,
    required this.productType,
    required this.tags,
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
    this.metafieldDescription,
  });

  /// Create from Shopify Admin API JSON response
  factory ToolProduct.fromShopifyJson(
    Map<String, dynamic> productJson,
    Map<String, dynamic> variantJson,
    Map<String, dynamic> metafields,
  ) {
    // Extract images from product
    final images = productJson['images'] as List? ?? [];
    final imageUrls = images.map((img) => img['src'] as String).toList();

    // Parse price from variant
    final price =
        double.tryParse(variantJson['price']?.toString() ?? '0') ?? 0.0;
    final compareAtPrice = variantJson['compare_at_price'] != null
        ? double.tryParse(variantJson['compare_at_price']?.toString() ?? '0')
        : null;

    // Extract metafields
    final garagePrice = metafields['garage_price']?.toString();
    final metafieldProductType = metafields['product_type']?.toString();
    final metafieldDescription = metafields['description']?.toString();

    return ToolProduct(
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
      variantId: variantJson['id']?.toString() ?? '',
      variantTitle: variantJson['title'] ?? '',
      price: price,
      compareAtPrice: compareAtPrice,
      currencyCode: 'ILS', // Israeli Shekel
      availableForSale: variantJson['available'] ?? false,
      quantityAvailable: variantJson['inventory_quantity'],
      imageUrls: imageUrls,
      primaryImageUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
      metafields: metafields,
      garagePrice: garagePrice,
      metafieldProductType: metafieldProductType,
      metafieldDescription: metafieldDescription,
    );
  }

  /// Create from JSON (for caching/storage)
  factory ToolProduct.fromJson(Map<String, dynamic> json) {
    return ToolProduct(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      vendor: json['vendor'] ?? '',
      productType: json['productType'] ?? '',
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
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
      metafieldDescription: json['metafieldDescription'],
    );
  }

  /// Convert to JSON (for caching/storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'vendor': vendor,
      'productType': productType,
      'tags': tags,
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
      'metafieldDescription': metafieldDescription,
    };
  }

  /// Clean HTML description
  static String _cleanDescription(String description) {
    return description
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  /// Get display price with garage pricing logic
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

  /// Get stock status display text
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
    return availableForSale ? 'In Stock' : 'Out of Stock';
  }

  /// Check if product is in stock
  bool get isInStock {
    if (quantityAvailable != null && quantityAvailable! > 0) {
      return true;
    }
    return availableForSale && (quantityAvailable ?? 1) > 0;
  }

  /// Check if product is on sale
  bool get isOnSale => compareAtPrice != null && compareAtPrice! > price;

  /// Get the best available description (metafield first, then product description)
  String get bestDescription {
    if (metafieldDescription != null && metafieldDescription!.isNotEmpty) {
      return metafieldDescription!;
    }
    return description;
  }

  /// Get the best available product type (metafield first, then product type)
  String get bestProductType {
    if (metafieldProductType != null && metafieldProductType!.isNotEmpty) {
      return metafieldProductType!;
    }
    return productType;
  }

  /// Get display image URL (primary or placeholder)
  String get displayImageUrl {
    return primaryImageUrl ??
        'https://via.placeholder.com/300x200/f0f0f0/999999?text=No+Image';
  }

  /// Get actual price (considering garage pricing)
  double get actualPrice {
    if (garagePrice != null) {
      final gPrice = double.tryParse(garagePrice!) ?? 0.0;
      if (gPrice > 0) {
        return gPrice;
      }
    }
    return price;
  }

  /// Get sale percentage if on sale
  int get salePercentage {
    if (isOnSale && compareAtPrice != null) {
      final discountAmount = compareAtPrice! - price;
      return ((discountAmount / compareAtPrice!) * 100).round();
    }
    return 0;
  }
}
