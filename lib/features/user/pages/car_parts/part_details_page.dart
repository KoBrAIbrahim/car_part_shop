import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/models/car_part.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../core/services/car_lookup_service.dart';
import '../../../../core/providers/theme_provider.dart';

class PartDetailsPage extends StatefulWidget {
  final CarPart part;

  const PartDetailsPage({super.key, required this.part});

  @override
  State<PartDetailsPage> createState() => _PartDetailsPageState();
}

class _PartDetailsPageState extends State<PartDetailsPage> {
  int _quantity = 1;
  bool _adding = false;

  Future<void> _addToCart() async {
    setState(() => _adding = true);
    try {
      await CartService.addToCart(
        widget.part,
        carMake: widget.part.displayBrand,
        quantity: _quantity,
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
  final part = widget.part;
    final qtyAvailable = part.shopifyProduct?.quantityAvailable;
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      // Use a clear AppBar for the details page so the part title is shown correctly
      appBar: AppBar(
        backgroundColor: AppColors.getBackground(isDark),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.getTextColor(isDark)),
        title: Text(part.displayTitle, style: TextStyle(color: AppColors.getTextColor(isDark))),
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
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: part.allImageUrls.isNotEmpty ? part.allImageUrls.length : 1,
                        itemBuilder: (context, index) {
                          final imageUrl = part.allImageUrls.isNotEmpty ? part.allImageUrls[index] : null;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: imageUrl != null
                                  ? Image.network(
                                      imageUrl,
                                      width: 320,
                                      height: 220,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 320,
                                        height: 220,
                                        color: AppColors.getSurface(isDark),
                                        child: Icon(Icons.car_repair_rounded, size: 48, color: AppColors.getTextColor(isDark).withOpacity(0.3)),
                                      ),
                                    )
                                  : Container(
                                      width: 320,
                                      height: 220,
                                      color: AppColors.getSurface(isDark),
                                      child: Center(child: Icon(Icons.car_repair_rounded, size: 48, color: AppColors.getTextColor(isDark).withOpacity(0.3))),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      part.displayTitle,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.getTextColor(isDark)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${'user.car_parts.part_number'.tr()}: ${part.partNumber}',
                      style: TextStyle(fontSize: 14, color: AppColors.getTextColor(isDark).withOpacity(0.8)),
                    ),

                    const SizedBox(height: 6),
                    // Explicitly show category so it's obvious and uses the priority logic from the model
                    Row(
                      children: [
                        Text('${'user.car_parts.category'.tr()}: ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.getTextColor(isDark))),
                        Expanded(
                          child: Text(part.displayCategory, style: TextStyle(fontSize: 14, color: AppColors.getTextColor(isDark).withOpacity(0.8)), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Stock indicator moved here (under category)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: part.isInStock ? AppColors.yellow.withOpacity(0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.getDivider(isDark)),
                          ),
                          child: Text(
                            part.shopifyProduct?.quantityAvailable != null
                                ? '${part.shopifyProduct!.quantityAvailable} ${'user.car_parts.in_stock'.tr()}'
                                : (part.isInStock ? 'user.car_parts.in_stock'.tr() : 'user.car_parts.out_of_stock'.tr()),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.getTextColor(isDark).withOpacity(0.9)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Quantity selector
                    Row(
                      children: [
                        Text('user.car_parts.quantity'.tr(), style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.getDivider(isDark)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                                icon: const Icon(Icons.remove_rounded),
                              ),
                              Text('$_quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              IconButton(
                                onPressed: qtyAvailable == null || _quantity < qtyAvailable ? () => setState(() => _quantity++) : null,
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
                            // When in dark mode, make the selected tab label yellow to match the design
                            labelColor: isDark ? AppColors.yellow : Colors.black,
                            unselectedLabelColor: AppColors.getTextColor(isDark).withOpacity(0.7),
                            indicatorColor: AppColors.yellow,
                            tabs: [
                              Tab(text: 'Description'),
                              Tab(text: 'Installed In'),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 240,
                            child: TabBarView(
                              children: [
                                // Description + stock
                                SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(part.displayDescription, style: TextStyle(color: AppColors.getTextColor(isDark).withOpacity(0.9))),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                                ),

                                // Installed in - list cars
                                FutureBuilder<List<CarLookupResult>>(
                                  future: CarLookupService.findCarsByPartNumber(part.partNumber),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.yellow)));
                                    }

                                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                      return Center(child: Text('No vehicles found for this part'));
                                    }

                                    final cars = snapshot.data!;
                                    return ListView.separated(
                                      itemCount: cars.length,
                                      separatorBuilder: (_, __) => const Divider(),
                                      itemBuilder: (context, idx) {
                                        final car = cars[idx];
                                        return ListTile(
                                          title: Text(car.displayName),
                                          subtitle: Text('${car.make} ${car.model}'),
                                          trailing: Text('${car.year}'),
                                          onTap: () {
                                            // navigate to car details if desired
                                            // context.push('/car/${car.carId}');
                                          },
                                        );
                                      },
                                    );
                                  },
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
              color: AppColors.getCardBackground(isDark),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.getDivider(isDark)),
                      ),
                      child: Text('Back', style: TextStyle(color: AppColors.getTextColor(isDark))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: part.isInStock && !_adding ? _addToCart : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _adding ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : Text('user.car_parts.add_to_cart'.tr()),
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
}
