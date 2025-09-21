class CarDetails {
  final int? id;
  final String make;
  final String model;
  final int year;
  final String country;
  final String engine;

  CarDetails({
    this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.country,
    required this.engine,
  });

  factory CarDetails.fromJson(Map<String, dynamic> json) {
    return CarDetails(
      id: json['id'],
      make: json['make']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      year: _parseYear(json['year']),
      country: json['country']?.toString() ?? '',
      engine: json['engine']?.toString() ?? '',
    );
  }

  static int _parseYear(dynamic yearValue) {
    if (yearValue == null) return 0;
    if (yearValue is int) return yearValue;
    if (yearValue is String) {
      return int.tryParse(yearValue) ?? 0;
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'country': country,
      'engine': engine,
    };
  }
}

class CarDetailOption {
  final String value;
  final bool isAvailable;

  CarDetailOption({required this.value, this.isAvailable = true});
}
