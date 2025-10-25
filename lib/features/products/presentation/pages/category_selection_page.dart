import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/car_parts_provider.dart';
import '../../../user/pages/car_parts/car_parts_page.dart';
import 'subcategory_selection_page.dart';

class CategorySelectionPage extends StatefulWidget {
  final int carId;
  final String carName;

  const CategorySelectionPage({
    super.key,
    required this.carId,
    required this.carName,
  });

  @override
  State<CategorySelectionPage> createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  List<String> _categories = [];
  Map<String, Set<String>> _categorySubcategories = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final provider = Provider.of<CarPartsProvider>(context, listen: false);
    await provider.loadPartsForCar(widget.carId);

    if (mounted) {
      final categories = provider.allParts
          .map((part) => part.displayCategory)
          .toSet()
          .toList();
      categories.sort();

      // Build subcategories map
      final Map<String, Set<String>> subcategoriesMap = {};
      for (final part in provider.allParts) {
        final category = part.displayCategory;
        final subcategory = part.displaySubcategory;

        if (subcategory != null && subcategory.isNotEmpty) {
          subcategoriesMap.putIfAbsent(category, () => <String>{});
          subcategoriesMap[category]!.add(subcategory);
        }
      }

      setState(() {
        _categories = categories;
        _categorySubcategories = subcategoriesMap;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;
    final cardPadding = screenWidth > 600 ? 16.0 : 12.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('اختر الفئة - ${widget.carName}'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد فئات متاحة',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : Padding(
              padding: EdgeInsets.all(cardPadding),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: cardPadding,
                  mainAxisSpacing: cardPadding,
                  childAspectRatio: 0.85,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final subcategories = _categorySubcategories[category];

                  return _CategoryCard(
                    categoryName: category,
                    onTap: () {
                      // Check if category has subcategories
                      if (subcategories != null && subcategories.isNotEmpty) {
                        // Navigate to subcategory selection page
                        final subcategoryList = subcategories.toList()..sort();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubcategorySelectionPage(
                              carId: widget.carId,
                              carName: widget.carName,
                              category: category,
                              subcategories: subcategoryList,
                            ),
                          ),
                        );
                      } else {
                        // Navigate directly to products page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CarPartsPage(
                              carId: widget.carId,
                              carName: widget.carName,
                              initialCategory: category,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String categoryName;
  final VoidCallback onTap;

  const _CategoryCard({required this.categoryName, required this.onTap});

  IconData _getCategoryIcon(String category) {
    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('engine') || categoryLower.contains('محرك')) {
      return Icons.settings;
    } else if (categoryLower.contains('brake') ||
        categoryLower.contains('فرامل')) {
      return Icons.stop_circle;
    } else if (categoryLower.contains('suspension') ||
        categoryLower.contains('تعليق')) {
      return Icons.directions_car;
    } else if (categoryLower.contains('electrical') ||
        categoryLower.contains('كهرباء')) {
      return Icons.electric_bolt;
    } else if (categoryLower.contains('body') ||
        categoryLower.contains('هيكل')) {
      return Icons.car_repair;
    } else if (categoryLower.contains('interior') ||
        categoryLower.contains('داخلي')) {
      return Icons.airline_seat_recline_normal;
    } else if (categoryLower.contains('wheel') ||
        categoryLower.contains('عجل')) {
      return Icons.album;
    } else {
      return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('engine') || categoryLower.contains('محرك')) {
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
    } else if (categoryLower.contains('body') ||
        categoryLower.contains('هيكل')) {
      return Colors.green;
    } else if (categoryLower.contains('interior') ||
        categoryLower.contains('داخلي')) {
      return Colors.purple;
    } else if (categoryLower.contains('wheel') ||
        categoryLower.contains('عجل')) {
      return Colors.teal;
    } else {
      return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(categoryName);
    final icon = _getCategoryIcon(categoryName);

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
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 50, color: color),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  categoryName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color.darken(0.3),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: color.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension ColorExtension on Color {
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
