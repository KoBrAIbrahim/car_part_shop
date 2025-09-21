import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../core/models/cart_item.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CartItem> _cartItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  void _loadCartItems() {
    setState(() {
      _isLoading = true;
    });

    try {
      _cartItems = CartService.getCartItems();
    } catch (e) {
      print('Error loading cart items: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateQuantity(String partNumber, int newQuantity) async {
    try {
      await CartService.updateQuantity(partNumber, newQuantity);
      _loadCartItems(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantity updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating quantity: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeItem(String partNumber) async {
    try {
      await CartService.removeFromCart(partNumber);
      _loadCartItems(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item removed from cart'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing item: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to locale changes to rebuild the widget immediately
    context.locale; // This triggers rebuild when locale changes

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cartItems.isEmpty) {
      return _buildEmptyCart();
    }

    return _buildCartWithItems();
  }

  Widget _buildEmptyCart() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_rounded,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'user.cart.title'.tr(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'user.cart.empty_message'.tr(),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textDark.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Text(
              'user.cart.start_shopping'.tr(),
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartWithItems() {
    final totalPrice = CartService.getTotalPrice();
    final totalItems = CartService.getCartItemCount();

    return Column(
      children: [
        // Cart summary header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          margin: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalItems item${totalItems > 1 ? 's' : ''} in cart',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),

        // Cart items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _cartItems.length,
            itemBuilder: (context, index) {
              final item = _cartItems[index];
              return _buildCartItem(item);
            },
          ),
        ),

        // Checkout button
        Container(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Checkout functionality coming soon!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Checkout (\$${totalPrice.toStringAsFixed(2)})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.settings, color: Colors.grey[400]),
                    )
                  : Icon(Icons.settings, size: 40, color: Colors.grey[400]),
            ),
            const SizedBox(width: 16),

            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Part: ${item.partNumber}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    'Car: ${item.carMake} ${item.carModel ?? ''} ${item.carYear ?? ''}'
                        .trim(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity controls and remove button
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: item.quantity > 1
                          ? () => _updateQuantity(
                              item.partNumber,
                              item.quantity - 1,
                            )
                          : null,
                      icon: const Icon(Icons.remove),
                      iconSize: 20,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.quantity.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          _updateQuantity(item.partNumber, item.quantity + 1),
                      icon: const Icon(Icons.add),
                      iconSize: 20,
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _removeItem(item.partNumber),
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  iconSize: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
