import '../services/shopify_service.dart';

class CarPart {
  final int? id;
  final String partNumber;
  final int idCars;
  final String? description;
  final double? price;
  final String? category;
  final String? brand;
  final bool? inStock;
  final String? imageUrl;

  // Shopify product data (loaded separately)
  ShopifyProduct? shopifyProduct;

  CarPart({
    this.id,
    required this.partNumber,
    required this.idCars,
    this.description,
    this.price,
    this.category,
    this.brand,
    this.inStock,
    this.imageUrl,
    this.shopifyProduct,
  });

  factory CarPart.fromJson(Map<String, dynamic> json) {
    final carPart = CarPart(
      id: json['id'],
      partNumber: json['part_number']?.toString() ?? '',
      idCars: _parseId(json['id_cars']),
      description: json['description']?.toString(),
      price: _parsePrice(json['price']),
      category: json['category']?.toString(),
      brand: json['brand']?.toString(),
      inStock: json['in_stock'] as bool?,
      imageUrl: json['image_url']?.toString(),
    );

    // Restore Shopify product data if available in cache
    if (json['shopify_product'] != null) {
      carPart.shopifyProduct = ShopifyProduct.fromCacheJson(
        json['shopify_product'] as Map<String, dynamic>,
      );
    }

    return carPart;
  }

  /// Create CarPart primarily from Shopify product data
  factory CarPart.fromShopifyProduct(ShopifyProduct shopifyProduct, int carId) {
    // Determine stock status based on quantity and availability
    bool isInStock =
        shopifyProduct.availableForSale &&
        (shopifyProduct.quantityAvailable == null ||
            shopifyProduct.quantityAvailable! > 0);

    // Use metafield product_type if available, otherwise use Shopify product_type
    String category =
        shopifyProduct.metafieldProductType ??
        (shopifyProduct.productType.isNotEmpty
            ? shopifyProduct.productType
            : 'Auto Part');

    return CarPart(
      id: null, // No Supabase ID when created from Shopify
      partNumber: shopifyProduct.partNumber,
      idCars: carId,
      description: shopifyProduct.description,
      price: shopifyProduct.price,
      category: category,
      brand: shopifyProduct.vendor,
      inStock: isInStock,
      imageUrl: shopifyProduct.primaryImageUrl,
      shopifyProduct: shopifyProduct,
    );
  }

  /// Create minimal CarPart when both Supabase and Shopify data are unavailable
  factory CarPart.createMinimal(String partNumber, int carId) {
    final temp = CarPart(partNumber: partNumber, idCars: carId);

    return CarPart(
      partNumber: partNumber,
      idCars: carId,
      description: temp._generateDescriptionFromPartNumber(),
      category: temp._extractCategoryFromPartNumber(),
      brand: temp._extractBrandFromPartNumber(),
      inStock: true, // Assume available for better UX
    );
  }

  static int _parseId(dynamic idValue) {
    if (idValue == null) return 0;
    if (idValue is int) return idValue;
    if (idValue is String) {
      return int.tryParse(idValue) ?? 0;
    }
    return 0;
  }

  static double? _parsePrice(dynamic priceValue) {
    if (priceValue == null) return null;
    if (priceValue is double) return priceValue;
    if (priceValue is int) return priceValue.toDouble();
    if (priceValue is String) {
      return double.tryParse(priceValue);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'part_number': partNumber,
      'id_cars': idCars,
      'description': description,
      'price': price,
      'category': category,
      'brand': brand,
      'in_stock': inStock,
      'image_url': imageUrl,
    };

    // Include Shopify product data for cache persistence
    if (shopifyProduct != null) {
      json['shopify_product'] = shopifyProduct!.toCacheJson();
    }

    return json;
  }

  // Enhanced getters that prioritize Shopify data
  String get displayTitle {
    return shopifyProduct?.title ?? partNumber;
  }

  String get displayDescription {
    if (shopifyProduct?.description != null) {
      return shopifyProduct!.description;
    }
    if (description != null && description!.isNotEmpty) {
      return description!;
    }
    // Create a basic description from the part number
    return _generateDescriptionFromPartNumber();
  }

  String get displayPrice {
    if (shopifyProduct != null) {
      return shopifyProduct!.displayPrice;
    }
    if (price != null) {
      return '\$${price!.toStringAsFixed(2)}';
    }
    return 'Contact for pricing';
  }

  String get stockStatus {
    if (shopifyProduct != null) {
      return shopifyProduct!.stockStatus;
    }
    if (inStock != null) {
      return inStock! ? 'In Stock' : 'Out of Stock';
    }
    return 'Contact for availability';
  }

  bool get isInStock {
    if (shopifyProduct != null) {
      return shopifyProduct!.isInStock;
    }
    // If we don't have stock info, assume available for better UX
    return inStock ?? true;
  }

  String? get displayImageUrl {
    // Try exact match first
    if (shopifyProduct?.primaryImageUrl != null) {
      return shopifyProduct!.primaryImageUrl;
    }

    // Fallback to legacy image
    if (imageUrl != null) {
      return imageUrl;
    }

    // If no image found, try fuzzy matching for common typos
    // This helps with cases like BALL-JIONT-022 vs BALL-JOINT-022
    return null;
  }

  List<String> get allImageUrls {
    final List<String> images = [];

    // Add Shopify images first
    if (shopifyProduct != null && shopifyProduct!.imageUrls.isNotEmpty) {
      images.addAll(shopifyProduct!.imageUrls);
    }

    // Add legacy image if different from primary
    if (imageUrl != null && !images.contains(imageUrl)) {
      images.add(imageUrl!);
    }

    return images;
  }

  String get displayBrand {
    if (shopifyProduct?.vendor != null) {
      return shopifyProduct!.vendor;
    }
    if (brand != null && brand!.isNotEmpty) {
      return brand!;
    }
    // Extract brand from part number if possible
    return _extractBrandFromPartNumber();
  }

  String get displayCategory {
    if (shopifyProduct?.productType != null) {
      return shopifyProduct!.productType;
    }
    if (category != null && category!.isNotEmpty) {
      return category!;
    }
    // Extract category from part number if possible
    return _extractCategoryFromPartNumber();
  }

  // Helper method to generate description from part number
  String _generateDescriptionFromPartNumber() {
    final parts = partNumber.split('-');
    if (parts.length >= 2) {
      final category = parts.first.toLowerCase();
      switch (category) {
        case 'fuel':
          return 'Fuel system component - ${partNumber}';
        case 'brake':
          return 'Brake system component - ${partNumber}';
        case 'susp':
        case 'suspension':
          return 'Suspension component - ${partNumber}';
        case 'engine':
          return 'Engine component - ${partNumber}';
        case 'trans':
        case 'transmission':
          return 'Transmission component - ${partNumber}';
        case 'air':
          return 'Air system component - ${partNumber}';
        case 'oil':
          return 'Oil system component - ${partNumber}';
        case 'cool':
        case 'cooling':
          return 'Cooling system component - ${partNumber}';
        case 'elect':
        case 'electrical':
          return 'Electrical component - ${partNumber}';
        case 'exhaust':
          return 'Exhaust system component - ${partNumber}';
        case 'ball':
          return 'Ball joint component - ${partNumber}';
        case 'evap':
        case 'evaporator':
          return 'Evaporator component - ${partNumber}';
        default:
          return 'Automotive part - ${partNumber}';
      }
    }
    return 'Automotive part - ${partNumber}';
  }

  // Helper method to extract brand from part number
  String _extractBrandFromPartNumber() {
    // Common brand patterns in part numbers
    final partLower = partNumber.toLowerCase();
    if (partLower.contains('oem')) return 'OEM';
    if (partLower.contains('bmw')) return 'BMW';
    if (partLower.contains('audi')) return 'Audi';
    if (partLower.contains('vw')) return 'Volkswagen';
    if (partLower.contains('mb') || partLower.contains('merc'))
      return 'Mercedes-Benz';
    if (partLower.contains('ford')) return 'Ford';
    if (partLower.contains('gm')) return 'General Motors';
    if (partLower.contains('toyota')) return 'Toyota';
    if (partLower.contains('honda')) return 'Honda';
    if (partLower.contains('nissan')) return 'Nissan';
    return 'Aftermarket';
  }

  // Helper method to extract category from part number
  String _extractCategoryFromPartNumber() {
    final parts = partNumber.split('-');
    if (parts.isNotEmpty) {
      final category = parts.first.toLowerCase();
      switch (category) {
        case 'fuel':
          return 'Fuel System';
        case 'brake':
          return 'Brake System';
        case 'susp':
        case 'suspension':
          return 'Suspension';
        case 'engine':
          return 'Engine';
        case 'trans':
        case 'transmission':
          return 'Transmission';
        case 'air':
          return 'Air System';
        case 'oil':
          return 'Oil System';
        case 'cool':
        case 'cooling':
          return 'Cooling System';
        case 'elect':
        case 'electrical':
          return 'Electrical';
        case 'exhaust':
          return 'Exhaust System';
        case 'ball':
          return 'Suspension';
        case 'evap':
        case 'evaporator':
          return 'Climate Control';
        case 'alt':
        case 'alternator':
          return 'Electrical';
        case 'starter':
          return 'Electrical';
        case 'filter':
          return 'Filters';
        case 'belt':
          return 'Engine';
        case 'hose':
          return 'Cooling System';
        default:
          return 'General';
      }
    }
    return 'General';
  }

  bool get hasShopifyData => shopifyProduct != null;

  bool get isOnSale => shopifyProduct?.isOnSale ?? false;

  double? get actualPrice => shopifyProduct?.price ?? price;

  double? get compareAtPrice => shopifyProduct?.compareAtPrice;

  /// Get price based on user type - supports cached pricing data
  String getPrice({required bool isGarageOwner}) {
    if (shopifyProduct != null) {
      final shopifyProduct = this.shopifyProduct!;

      // For garage owners with garage price available
      if (isGarageOwner && shopifyProduct.garagePrice != null) {
        final gPrice = double.tryParse(shopifyProduct.garagePrice!) ?? 0.0;
        if (gPrice > 0) {
          // If garage price < regular price: show garage price only
          if (gPrice < shopifyProduct.price) {
            return '₪${gPrice.toStringAsFixed(0)}';
          }

          // If sale price < garage price: show sale price
          if (shopifyProduct.compareAtPrice != null &&
              shopifyProduct.compareAtPrice! > shopifyProduct.price &&
              shopifyProduct.price < gPrice) {
            return '₪${shopifyProduct.price.toStringAsFixed(0)}';
          }

          // Default: show garage price
          return '₪${gPrice.toStringAsFixed(0)}';
        }
      }

      // For regular customers or when garage price not available
      return '₪${shopifyProduct.price.toStringAsFixed(0)}';
    }

    // Fallback to Supabase price
    if (price != null && price! > 0) {
      return '₪${price!.toStringAsFixed(0)}';
    }

    return 'Contact for pricing';
  }

  /// Get sale percentage for user type - supports cached pricing data
  int getSalePercentage({required bool isGarageOwner}) {
    if (shopifyProduct != null) {
      final shopifyProduct = this.shopifyProduct!;

      // For garage owners with garage price
      if (isGarageOwner && shopifyProduct.garagePrice != null) {
        final gPrice = double.tryParse(shopifyProduct.garagePrice!) ?? 0.0;
        if (gPrice > 0) {
          // If sale price < garage price: show sale percentage
          if (shopifyProduct.compareAtPrice != null &&
              shopifyProduct.compareAtPrice! > shopifyProduct.price &&
              shopifyProduct.price < gPrice) {
            final discountAmount =
                shopifyProduct.compareAtPrice! - shopifyProduct.price;
            return ((discountAmount / shopifyProduct.compareAtPrice!) * 100)
                .round();
          }
        }
      }

      // Check for regular sale (compareAtPrice > price)
      if (shopifyProduct.compareAtPrice != null &&
          shopifyProduct.compareAtPrice! > shopifyProduct.price) {
        final discountAmount =
            shopifyProduct.compareAtPrice! - shopifyProduct.price;
        return ((discountAmount / shopifyProduct.compareAtPrice!) * 100)
            .round();
      }
    }
    return 0;
  }

  /// Check if part has sale price for user type - supports cached pricing data
  bool hasSalePrice({required bool isGarageOwner}) {
    if (shopifyProduct != null) {
      final shopifyProduct = this.shopifyProduct!;

      // For garage owners with garage price
      if (isGarageOwner && shopifyProduct.garagePrice != null) {
        final gPrice = double.tryParse(shopifyProduct.garagePrice!) ?? 0.0;
        if (gPrice > 0) {
          // If garage price < regular price: no sale
          if (gPrice < shopifyProduct.price) {
            return false;
          }

          // If sale price < garage price: show sale badge
          if (shopifyProduct.compareAtPrice != null &&
              shopifyProduct.compareAtPrice! > shopifyProduct.price &&
              shopifyProduct.price < gPrice) {
            return true;
          }
        }
      }

      // Check for regular sale (compareAtPrice > price)
      return shopifyProduct.compareAtPrice != null &&
          shopifyProduct.compareAtPrice! > shopifyProduct.price;
    }
    return false;
  }
}
