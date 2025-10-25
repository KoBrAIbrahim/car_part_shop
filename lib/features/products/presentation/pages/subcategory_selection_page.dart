import 'package:flutter/material.dart';
import '../../../user/pages/car_parts/car_parts_page.dart';
import 'category_selection_page.dart';

class SubcategorySelectionPage extends StatelessWidget {
  final int carId;
  final String carName;
  final String category;
  final List<String> subcategories;

  const SubcategorySelectionPage({
    super.key,
    required this.carId,
    required this.carName,
    required this.category,
    required this.subcategories,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;
    final cardPadding = screenWidth > 600 ? 16.0 : 12.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('اختر الفئة الفرعية - $category'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: cardPadding,
            mainAxisSpacing: cardPadding,
            childAspectRatio: 0.85,
          ),
          itemCount: subcategories.length,
          itemBuilder: (context, index) {
            final subcategory = subcategories[index];
            return _SubcategoryCard(
              subcategoryName: subcategory,
              categoryName: category,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CarPartsPage(
                      carId: carId,
                      carName: carName,
                      initialCategory: category,
                      initialSubcategory: subcategory,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SubcategoryCard extends StatelessWidget {
  final String subcategoryName;
  final String categoryName;
  final VoidCallback onTap;

  const _SubcategoryCard({
    required this.subcategoryName,
    required this.categoryName,
    required this.onTap,
  });

  IconData _getSubcategoryIcon(String subcategory) {
    final subLower = subcategory.toLowerCase();

    // Transmission & Belts subcategories
    if (subLower.contains('clutch')) return Icons.adjust;
    if (subLower.contains('belt')) return Icons.view_week;
    if (subLower.contains('gear')) return Icons.settings_input_component;

    // Generic icons
    if (subLower.contains('filter')) return Icons.filter_alt;
    if (subLower.contains('oil')) return Icons.opacity;
    if (subLower.contains('light')) return Icons.lightbulb;
    if (subLower.contains('sensor')) return Icons.sensors;

    return Icons.category_outlined;
  }

  Color _getCategoryColor(String category) {
    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('transmission') ||
        categoryLower.contains('belt')) {
      return Colors.deepPurple;
    } else if (categoryLower.contains('engine') ||
        categoryLower.contains('محرك')) {
      return Colors.blue;
    } else if (categoryLower.contains('brake') ||
        categoryLower.contains('فرامل')) {
      return Colors.red;
    } else if (categoryLower.contains('suspension') ||
        categoryLower.contains('تعليق')) {
      return Colors.orange;
    } else if (categoryLower.contains('electrical') ||
        categoryLower.contains('كهرباء')) {
      return Colors.amber;
    }
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(categoryName);
    final icon = _getSubcategoryIcon(subcategoryName);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 45, color: color),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  subcategoryName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color.darken(0.3),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: color.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
