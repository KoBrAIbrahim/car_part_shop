import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/models/car_part.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../core/routing/app_router.dart';

class CarPartCard extends StatefulWidget {
  final CarPart part;
  final String carName;
  final Function(CarPart) onTap;
  final bool isGarageOwner;
  final int index;

  const CarPartCard({
    super.key,
    required this.part,
    required this.carName,
    required this.onTap,
    required this.isGarageOwner,
    this.index = 0,
  });

  @override
  State<CarPartCard> createState() => _CarPartCardState();
}

class _CarPartCardState extends State<CarPartCard> {
  bool _adding = false;

  Future<void> _addToCart() async {
    if (_adding) return;
    setState(() => _adding = true);
    try {
      await CartService.addToCart(
        widget.part,
        carMake: widget.carName,
        quantity: 1,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.part.displayTitle} ${'user.car_parts.added_to_cart'.tr()}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'user.car_parts.view_cart'.tr(),
            textColor: Colors.white,
            onPressed: () => context.go('/cart'),
          ),
        ),
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
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final part = widget.part;
    final hasSale = part.hasSalePrice(isGarageOwner: widget.isGarageOwner);
    final isInStock = part.isInStock;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.getDivider(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: part.allImageUrls.isNotEmpty
                ? AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      part.allImageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.getSurface(isDark),
                        child: Icon(Icons.car_repair_rounded, size: 48, color: AppColors.getTextColor(isDark).withOpacity(0.3)),
                      ),
                    ),
                  )
                : Container(
                    height: 140,
                    color: AppColors.getSurface(isDark),
                    child: Center(
                      child: Icon(Icons.car_repair_rounded, size: 48, color: AppColors.getTextColor(isDark).withOpacity(0.3)),
                    ),
                  ),
          ),

          // Yellow line under image
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(0)),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and part number
                Text(
                  part.displayTitle,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.getTextColor(isDark)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${'user.car_parts.part_number'.tr()}: ${part.partNumber}',
                  style: TextStyle(fontSize: 12, color: AppColors.getTextColor(isDark).withOpacity(0.7)),
                ),

                const SizedBox(height: 10),

                // Category + Stock on same row with yellow border
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.getCardBackground(isDark),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.yellow, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          part.displayCategory,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.getTextColor(isDark)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isInStock ? AppColors.success.withOpacity(0.08) : AppColors.error.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.yellow, width: 1),
                        ),
                        child: Text(
                          // If we have an exact quantity from Shopify, show the number when in stock
                          () {
                            if (isInStock) {
                              final qty = part.shopifyProduct?.quantityAvailable;
                              if (qty != null) {
                                return '${qty.toString()} ${'user.car_parts.in_stock'.tr()}';
                              }
                              return 'user.car_parts.in_stock'.tr();
                            }
                            return 'user.car_parts.out_of_stock'.tr();
                          }(),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isInStock ? AppColors.success : AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Price and discount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          part.getPrice(isGarageOwner: widget.isGarageOwner),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: hasSale ? AppColors.error : AppColors.success),
                        ),
                        if (hasSale && part.shopifyProduct?.compareAtPrice != null)
                          Text(
                            '₪${part.shopifyProduct!.compareAtPrice!.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 13, color: AppColors.getTextColor(isDark).withOpacity(0.6), decoration: TextDecoration.lineThrough),
                          ),
                      ],
                    ),

                    // Actions
                    // Use Wrap to avoid overflow on small widths and provide spacing
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.end,
                      children: [
                        // View Details - oblong/text button
                        TextButton(
                          onPressed: () => context.push(AppRouter.partDetails, extra: widget.part),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            shape: const StadiumBorder(),
                            backgroundColor: AppColors.yellow,
                            foregroundColor: Colors.black,
                            textStyle: const TextStyle(inherit: false, fontWeight: FontWeight.w600),
                          ),
                          child: Text('user.car_parts.part_details'.tr()),
                        ),

                        // Add to Cart - oblong elevated button
                        ElevatedButton(
                          onPressed: isInStock && !_adding ? _addToCart : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            shape: const StadiumBorder(),
                            // Ensure textStyle has same "inherit" behavior to avoid AnimatedDefaultTextStyle interpolation errors
                            textStyle: const TextStyle(inherit: false, fontWeight: FontWeight.w600),
                          ),
                          child: _adding
                              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text('user.car_parts.add_to_cart'.tr()),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}