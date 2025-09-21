import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart_item.dart';
import '../api/models/car_part.dart';
import '../api/models/tool_product.dart';

class CartService {
  static const String _cartBoxName = 'cart_items';
  static Box<CartItem>? _cartBox;

  /// Initialize cart service
  static Future<void> init() async {
    // Register CartItem adapter if not already registered
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CartItemAdapter());
    }

    // Open cart box
    _cartBox = await Hive.openBox<CartItem>(_cartBoxName);
  }

  /// Get cart box
  static Box<CartItem> get cartBox {
    if (_cartBox == null || !_cartBox!.isOpen) {
      throw Exception(
        'Cart box is not initialized. Call CartService.init() first.',
      );
    }
    return _cartBox!;
  }

  /// Add item to cart
  static Future<void> addToCart(
    CarPart carPart, {
    required String carMake,
    String? carModel,
    String? carYear,
    int quantity = 1,
  }) async {
    final existingItemIndex = _findItemIndex(carPart.partNumber);

    if (existingItemIndex != -1) {
      // Item already exists, update quantity
      final existingItem = cartBox.getAt(existingItemIndex);
      if (existingItem != null) {
        final updatedItem = existingItem.copyWith(
          quantity: existingItem.quantity + quantity,
        );
        await cartBox.putAt(existingItemIndex, updatedItem);
      }
    } else {
      // Add new item
      final cartItem = CartItem(
        partNumber: carPart.partNumber,
        title: carPart.displayTitle,
        description: carPart.displayDescription,
        price: carPart.actualPrice ?? 0.0,
        imageUrl: carPart.displayImageUrl,
        brand: carPart.displayBrand,
        category: carPart.displayCategory,
        quantity: quantity,
        carMake: carMake,
        carModel: carModel,
        carYear: carYear,
      );

      await cartBox.add(cartItem);
    }
  }

  /// Add tool to cart
  static Future<void> addToolToCart(
    ToolProduct tool, {
    int quantity = 1,
  }) async {
    final existingItemIndex = _findItemIndex(tool.id);

    if (existingItemIndex != -1) {
      // Item already exists, update quantity
      final existingItem = cartBox.getAt(existingItemIndex);
      if (existingItem != null) {
        final updatedItem = existingItem.copyWith(
          quantity: existingItem.quantity + quantity,
        );
        await cartBox.putAt(existingItemIndex, updatedItem);
      }
    } else {
      // Add new item
      final cartItem = CartItem(
        partNumber: tool.id, // Use tool ID as partNumber
        title: tool.title,
        description: tool.description,
        price: tool.actualPrice,
        imageUrl: tool.displayImageUrl,
        brand: tool.vendor.isNotEmpty ? tool.vendor : 'Unknown',
        category: 'Tool', // Set category as Tool
        quantity: quantity,
        carMake: 'Tool', // Use "Tool" as carMake to distinguish from car parts
        carModel: tool.productType.isNotEmpty ? tool.productType : null,
        carYear: null,
      );

      await cartBox.add(cartItem);
    }
  }

  /// Remove item from cart
  static Future<void> removeFromCart(String partNumber) async {
    final index = _findItemIndex(partNumber);
    if (index != -1) {
      await cartBox.deleteAt(index);
    }
  }

  /// Update item quantity
  static Future<void> updateQuantity(String partNumber, int quantity) async {
    final index = _findItemIndex(partNumber);
    if (index != -1) {
      final item = cartBox.getAt(index);
      if (item != null) {
        if (quantity <= 0) {
          await cartBox.deleteAt(index);
        } else {
          final updatedItem = item.copyWith(quantity: quantity);
          await cartBox.putAt(index, updatedItem);
        }
      }
    }
  }

  /// Get all cart items
  static List<CartItem> getCartItems() {
    return cartBox.values.toList();
  }

  /// Get cart item count
  static int getCartItemCount() {
    return cartBox.values.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  /// Get total cart price
  static double getTotalPrice() {
    return cartBox.values.fold<double>(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
  }

  /// Check if item is in cart
  static bool isInCart(String partNumber) {
    return _findItemIndex(partNumber) != -1;
  }

  /// Get item quantity in cart
  static int getItemQuantity(String partNumber) {
    final index = _findItemIndex(partNumber);
    if (index != -1) {
      final item = cartBox.getAt(index);
      return item?.quantity ?? 0;
    }
    return 0;
  }

  /// Clear all cart items
  static Future<void> clearCart() async {
    await cartBox.clear();
  }

  /// Find item index by part number
  static int _findItemIndex(String partNumber) {
    final items = cartBox.values.toList();
    for (int i = 0; i < items.length; i++) {
      if (items[i].partNumber == partNumber) {
        return i;
      }
    }
    return -1;
  }

  /// Get cart items grouped by car
  static Map<String, List<CartItem>> getCartItemsGroupedByCar() {
    final items = getCartItems();
    final grouped = <String, List<CartItem>>{};

    for (final item in items) {
      final carKey =
          '${item.carMake} ${item.carModel ?? ''} ${item.carYear ?? ''}'.trim();
      if (!grouped.containsKey(carKey)) {
        grouped[carKey] = [];
      }
      grouped[carKey]!.add(item);
    }

    return grouped;
  }

  /// Close cart box
  static Future<void> close() async {
    await _cartBox?.close();
  }
}
