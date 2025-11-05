import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/api/models/tool_product.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../core/providers/theme_provider.dart';

class ToolDetailsPage extends StatefulWidget {
  final ToolProduct tool;

  const ToolDetailsPage({super.key, required this.tool});

  @override
  State<ToolDetailsPage> createState() => _ToolDetailsPageState();
}

class _ToolDetailsPageState extends State<ToolDetailsPage> {
  int _quantity = 1;
  bool _adding = false;
  int _currentImageIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    setState(() => _adding = true);
    try {
      await CartService.addToolToCart(widget.tool, quantity: _quantity);

      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          // Auto-close after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (Navigator.canPop(dialogContext)) {
              Navigator.of(dialogContext).pop();
            }
          });

          final isDark = Provider.of<ThemeProvider>(
            context,
            listen: false,
          ).isDarkMode;

          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.getCardBackground(isDark),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yellow.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success icon with animation
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 50,
                      color: AppColors.yellow,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Success message
                  Text(
                    'user.car_parts.added_to_cart'.tr(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextColor(isDark),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Product name
                  Text(
                    widget.tool.title,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.getTextColor(isDark).withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Quantity
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.yellow.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '${'user.car_parts.quantity'.tr()}: $_quantity',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.getTextColor(isDark),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // View Cart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        context.go('/cart');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'user.car_parts.view_cart'.tr(),
                        style: const TextStyle(
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
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('user.car_parts.error_adding_to_cart'.tr()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final qtyAvailable = tool.quantityAvailable;
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getBackground(isDark),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.getTextColor(isDark)),
        title: Text(
          tool.title,
          style: TextStyle(color: AppColors.getTextColor(isDark)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image gallery - horizontal scroll
                    SizedBox(
                      height: 220,
                      child: tool.imageUrls.isNotEmpty
                          ? Stack(
                              children: [
                                PageView.builder(
                                  controller: _pageController,
                                  onPageChanged: (index) {
                                    setState(() => _currentImageIndex = index);
                                  },
                                  itemCount: tool.imageUrls.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: CachedNetworkImage(
                                          imageUrl: tool.imageUrls[index],
                                          width: double.infinity,
                                          height: 220,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: AppColors.getSurface(isDark),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(AppColors.yellow),
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                                color: AppColors.getSurface(
                                                  isDark,
                                                ),
                                                child: Icon(
                                                  Icons.build_rounded,
                                                  size: 48,
                                                  color: AppColors.getTextColor(
                                                    isDark,
                                                  ).withOpacity(0.3),
                                                ),
                                              ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Discount badge
                                if (tool.isOnSale && tool.salePercentage > 0)
                                  Positioned(
                                    top: 12,
                                    right: 24,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        '-${tool.salePercentage}%',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                height: 220,
                                color: AppColors.getSurface(isDark),
                                child: Center(
                                  child: Icon(
                                    Icons.build_rounded,
                                    size: 48,
                                    color: AppColors.getTextColor(
                                      isDark,
                                    ).withOpacity(0.3),
                                  ),
                                ),
                              ),
                            ),
                    ),

                    // Image indicators
                    if (tool.imageUrls.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            tool.imageUrls.length,
                            (index) => Container(
                              width: index == _currentImageIndex ? 24 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: index == _currentImageIndex
                                    ? AppColors.yellow
                                    : AppColors.getDivider(
                                        isDark,
                                      ).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Title
                    Text(
                      tool.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.getTextColor(isDark),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Vendor
                    if (tool.vendor.isNotEmpty)
                      Text(
                        '${'user.tools.vendor'.tr()}: ${tool.vendor}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.getTextColor(
                            isDark,
                          ).withOpacity(0.8),
                        ),
                      ),

                    const SizedBox(height: 6),

                    // Product Type
                    Row(
                      children: [
                        Text(
                          '${'user.tools.product_type'.tr()}: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextColor(isDark),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            tool.bestProductType,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.getTextColor(
                                isDark,
                              ).withOpacity(0.8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Price
                    Row(
                      children: [
                        Text(
                          tool.displayPrice,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: tool.isOnSale
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                        if (tool.isOnSale && tool.compareAtPrice != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              '₪${tool.compareAtPrice!.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                decoration: TextDecoration.lineThrough,
                                color: AppColors.getTextColor(
                                  isDark,
                                ).withOpacity(0.5),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Stock indicator
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: tool.isInStock
                                ? AppColors.yellow.withOpacity(0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.getDivider(isDark),
                            ),
                          ),
                          child: Text(
                            tool.quantityAvailable != null
                                ? '${tool.quantityAvailable} ${'user.tools.in_stock'.tr()}'
                                : (tool.isInStock
                                      ? 'user.tools.in_stock'.tr()
                                      : 'user.tools.out_of_stock'.tr()),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.getTextColor(
                                isDark,
                              ).withOpacity(0.9),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Quantity selector
                    Row(
                      children: [
                        Text(
                          'user.car_parts.quantity'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.getDivider(isDark),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: _quantity > 1
                                    ? () => setState(() => _quantity--)
                                    : null,
                                icon: const Icon(Icons.remove_rounded),
                              ),
                              Text(
                                '$_quantity',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                onPressed:
                                    qtyAvailable == null ||
                                        _quantity < qtyAvailable
                                    ? () => setState(() => _quantity++)
                                    : null,
                                icon: const Icon(Icons.add_rounded),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Tabs
                    DefaultTabController(
                      length: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TabBar(
                            labelColor: isDark
                                ? AppColors.yellow
                                : Colors.black,
                            unselectedLabelColor: AppColors.getTextColor(
                              isDark,
                            ).withOpacity(0.7),
                            indicatorColor: AppColors.yellow,
                            tabs: const [
                              Tab(text: 'Description'),
                              Tab(text: 'Specifications'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 240,
                            child: TabBarView(
                              children: [
                                // Description
                                SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tool.bestDescription,
                                        style: TextStyle(
                                          color: AppColors.getTextColor(
                                            isDark,
                                          ).withOpacity(0.9),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                                ),

                                // Specifications
                                SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSpecRow(
                                        'SKU',
                                        tool.variantId,
                                        isDark,
                                      ),
                                      _buildSpecRow(
                                        'Variant',
                                        tool.variantTitle,
                                        isDark,
                                      ),
                                      _buildSpecRow(
                                        'Currency',
                                        tool.currencyCode,
                                        isDark,
                                      ),
                                      if (tool.tags.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: tool.tags
                                                .map(
                                                  (tag) => Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.yellow
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      border: Border.all(
                                                        color: AppColors.yellow
                                                            .withOpacity(0.3),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      tag,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            AppColors.getTextColor(
                                                              isDark,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 120), // space for bottom bar
                  ],
                ),
              ),
            ),
          ),

          // Bottom bar: Back and Add to Cart
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.getCardBackground(isDark),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.getDivider(isDark)),
                      ),
                      child: Text(
                        'common.back'.tr(),
                        style: TextStyle(color: AppColors.getTextColor(isDark)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: tool.isInStock && !_adding ? _addToCart : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _adding
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text('user.car_parts.add_to_cart'.tr()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.getTextColor(isDark),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.getTextColor(isDark).withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
