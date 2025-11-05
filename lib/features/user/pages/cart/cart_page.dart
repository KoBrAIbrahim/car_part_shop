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

class _CartPageState extends State<CartPage> with SingleTickerProviderStateMixin {
  List<CartItem> _cartItems = [];
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadCartItems();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadCartItems() {
    setState(() {
      _isLoading = true;
    });

    try {
      _cartItems = CartService.getCartItems();
      _animationController.forward(from: 0);
    } catch (e) {
      debugPrint('Error loading cart items: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateQuantity(String partNumber, int newQuantity) async {
    try {
      await CartService.updateQuantity(partNumber, newQuantity);
      _loadCartItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('user.cart.item_updated'.tr()),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('user.cart.error_updating'.tr()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _removeItem(String partNumber) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('user.cart.confirm_remove'.tr()),
        content: Text('user.cart.confirm_remove_message'.tr()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('user.cart.remove'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await CartService.removeFromCart(partNumber);
        _loadCartItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('user.cart.item_removed'.tr()),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('user.cart.error_removing'.tr()),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _clearCart() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('user.cart.confirm_clear'.tr()),
        content: Text('user.cart.confirm_clear_message'.tr()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('user.cart.clear_all'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await CartService.clearCart();
        _loadCartItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('user.cart.cart_cleared'.tr()),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('user.cart.error_removing'.tr()),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to locale changes to rebuild the widget immediately
    context.locale;
    
    // Get theme mode
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: AppColors.getBackground(isDark),
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.yellow),
              ),
            )
          : _cartItems.isEmpty
              ? _buildEmptyCart(isDark)
              : _buildCartWithItems(isDark),
    );
  }

  Widget _buildEmptyCart(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.yellowGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yellow.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 100,
                color: isDark ? Colors.black87 : Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'user.cart.empty_message'.tr(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.getTextColor(isDark),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'user.cart.start_shopping'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.getTextSecondaryColor(isDark),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.yellowGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yellow.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: Text('user.cart.continue_shopping'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.black87,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartWithItems(bool isDark) {
    final totalPrice = CartService.getTotalPrice();
    final totalItems = CartService.getCartItemCount();
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        // Header with items count and clear button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.yellowGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.yellow.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBackground : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.shopping_cart,
                      color: isDark ? AppColors.yellow : Colors.black87,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalItems ${totalItems > 1 ? 'user.cart.items_count'.tr() : 'user.cart.item_count'.tr()}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'user.cart.subtotal'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBackground : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton.icon(
                  onPressed: _clearCart,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: Text('user.cart.clear_all'.tr()),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Cart items list
        Expanded(
          child: Container(
            color: AppColors.getBackground(isDark),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                return FadeTransition(
                  opacity: _animationController,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        index * 0.1,
                        1.0,
                        curve: Curves.easeOut,
                      ),
                    )),
                    child: _buildCartItem(_cartItems[index], screenWidth, isDark),
                  ),
                );
              },
            ),
          ),
        ),

        // Summary and Checkout section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.getCardBackground(isDark),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Subtotal row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'user.cart.subtotal'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '\$${totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                // Total row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'user.cart.total'.tr(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Checkout button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: AppColors.yellowGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.yellow.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('user.cart.checkout_coming_soon'.tr()),
                          backgroundColor: AppColors.yellow,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.black87,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'user.cart.checkout'.tr(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItem(CartItem item, double screenWidth, bool isDark) {
    final isSmallScreen = screenWidth < 600;

    return Dismissible(
      key: Key(item.partNumber),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 32,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('user.cart.confirm_remove'.tr()),
            content: Text('user.cart.confirm_remove_message'.tr()),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'common.cancel'.tr(),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('user.cart.remove'.tr()),
              ),
            ],
          ),
        ) ??
            false;
      },
      onDismissed: (direction) {
        CartService.removeFromCart(item.partNumber);
        _loadCartItems();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('user.cart.item_removed'.tr()),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(isDark),
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(
            color: AppColors.yellow.withOpacity(0.2),
            width: 1,
          ) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: isSmallScreen
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildItemImage(item, isDark),
                          const SizedBox(width: 12),
                          Expanded(child: _buildItemDetails(item, isDark)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildQuantityControls(item, isDark),
                          _buildPriceSection(item, isDark),
                        ],
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildItemImage(item, isDark),
                      const SizedBox(width: 16),
                      Expanded(child: _buildItemDetails(item, isDark)),
                      const SizedBox(width: 16),
                      _buildQuantityControls(item, isDark),
                      const SizedBox(width: 16),
                      _buildPriceSection(item, isDark),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemImage(CartItem item, bool isDark) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? AppColors.darkSurface : Colors.grey[100],
        border: Border.all(
          color: isDark ? AppColors.yellow.withOpacity(0.2) : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: item.imageUrl != null
            ? CachedNetworkImage(
                imageUrl: item.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.settings,
                  color: Colors.grey[400],
                  size: 40,
                ),
              )
            : Icon(
                Icons.settings,
                size: 40,
                color: Colors.grey[400],
              ),
      ),
    );
  }

  Widget _buildItemDetails(CartItem item, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextColor(isDark),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.yellow.withOpacity(0.15),
                AppColors.yellowDark.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.yellow.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            '${'user.cart.part_number'.tr()}: ${item.partNumber}',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (item.carMake.toLowerCase() != 'tool') ...[
          Text(
            '${item.carMake} ${item.carModel ?? ''} ${item.carYear ?? ''}'
                .trim(),
            style: TextStyle(
              fontSize: 13,
              color: AppColors.getTextSecondaryColor(isDark),
            ),
          ),
        ] else ...[
          Text(
            item.carModel ?? 'Tool',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.getTextSecondaryColor(isDark),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.business,
              size: 14,
              color: AppColors.getTextSecondaryColor(isDark),
            ),
            const SizedBox(width: 4),
            Text(
              item.brand,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.getTextSecondaryColor(isDark),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantityControls(CartItem item, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.yellow.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.yellow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: item.quantity > 1
                ? () => _updateQuantity(item.partNumber, item.quantity - 1)
                : () => _removeItem(item.partNumber),
            icon: Icon(
              item.quantity > 1 ? Icons.remove_circle_outline : Icons.delete_outline,
              size: 22,
            ),
            color: item.quantity > 1 ? Colors.black87 : Colors.red,
            splashRadius: 20,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.yellowGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.quantity.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          IconButton(
            onPressed: () =>
                _updateQuantity(item.partNumber, item.quantity + 1),
            icon: const Icon(Icons.add_circle_outline, size: 22),
            color: Colors.black87,
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(CartItem item, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.yellowGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.yellow.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '\$${item.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${item.price.toStringAsFixed(2)} ${'user.cart.per_item'.tr()}',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.getTextSecondaryColor(isDark),
          ),
        ),
      ],
    );
  }
}
