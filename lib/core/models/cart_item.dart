import 'package:hive/hive.dart';

part 'cart_item.g.dart';

@HiveType(typeId: 1)
class CartItem extends HiveObject {
  @HiveField(0)
  final String partNumber;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final double price;

  @HiveField(4)
  final String? imageUrl;

  @HiveField(5)
  final String brand;

  @HiveField(6)
  final String category;

  @HiveField(7)
  int quantity;

  @HiveField(8)
  final String carMake;

  @HiveField(9)
  final String? carModel;

  @HiveField(10)
  final String? carYear;

  @HiveField(11)
  final DateTime addedAt;

  CartItem({
    required this.partNumber,
    required this.title,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.brand,
    required this.category,
    this.quantity = 1,
    required this.carMake,
    this.carModel,
    this.carYear,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  double get totalPrice => price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'partNumber': partNumber,
      'title': title,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'brand': brand,
      'category': category,
      'quantity': quantity,
      'carMake': carMake,
      'carModel': carModel,
      'carYear': carYear,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      partNumber: json['partNumber'],
      title: json['title'],
      description: json['description'],
      price: json['price'].toDouble(),
      imageUrl: json['imageUrl'],
      brand: json['brand'],
      category: json['category'],
      quantity: json['quantity'],
      carMake: json['carMake'],
      carModel: json['carModel'],
      carYear: json['carYear'],
      addedAt: DateTime.parse(json['addedAt']),
    );
  }

  CartItem copyWith({
    String? partNumber,
    String? title,
    String? description,
    double? price,
    String? imageUrl,
    String? brand,
    String? category,
    int? quantity,
    String? carMake,
    String? carModel,
    String? carYear,
    DateTime? addedAt,
  }) {
    return CartItem(
      partNumber: partNumber ?? this.partNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      carMake: carMake ?? this.carMake,
      carModel: carModel ?? this.carModel,
      carYear: carYear ?? this.carYear,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
