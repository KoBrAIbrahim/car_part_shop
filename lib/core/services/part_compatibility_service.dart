import '../supabase_service.dart';

/// Service for fetching cars that use specific parts
class PartCompatibilityService {
  static final SupabaseService _supabaseService = SupabaseService();

  /// Get all cars that use a specific part number
  static Future<List<CompatibleCar>> getCarsForPart(String partNumber) async {
    try {
      print('🔍 [PART_COMPATIBILITY] Fetching cars for part: $partNumber');

      final response = await _supabaseService.client
          .from('parts')
          .select('''
            part_number,
            cars!inner(
              id,
              make,
              model,
              year
            )
          ''')
          .eq('part_number', partNumber);

      List<CompatibleCar> compatibleCars = [];
      Set<String> seenCars = {}; // To avoid duplicates

      for (final record in response) {
        final carData = record['cars'];
        if (carData != null) {
          final carKey =
              '${carData['make']}_${carData['model']}_${carData['year']}';

          // Avoid duplicates
          if (!seenCars.contains(carKey)) {
            seenCars.add(carKey);

            compatibleCars.add(
              CompatibleCar(
                id: carData['id'],
                make: carData['make'] ?? 'Unknown',
                model: carData['model'] ?? 'Unknown',
                year: carData['year'] ?? 0,
              ),
            );
          }
        }
      }

      // Sort by make, then model, then year
      compatibleCars.sort((a, b) {
        int makeComparison = a.make.compareTo(b.make);
        if (makeComparison != 0) return makeComparison;

        int modelComparison = a.model.compareTo(b.model);
        if (modelComparison != 0) return modelComparison;

        return a.year.compareTo(b.year);
      });

      print(
        '✅ [PART_COMPATIBILITY] Found ${compatibleCars.length} compatible cars',
      );
      return compatibleCars;
    } catch (e) {
      print('❌ [PART_COMPATIBILITY] Error fetching compatible cars: $e');
      return [];
    }
  }

  /// Get cars grouped by make for better organization
  static Future<Map<String, List<CompatibleCar>>> getCarsGroupedByMake(
    String partNumber,
  ) async {
    try {
      final cars = await getCarsForPart(partNumber);

      Map<String, List<CompatibleCar>> groupedCars = {};

      for (final car in cars) {
        final make = car.make;
        if (!groupedCars.containsKey(make)) {
          groupedCars[make] = [];
        }
        groupedCars[make]!.add(car);
      }

      return groupedCars;
    } catch (e) {
      print('❌ [PART_COMPATIBILITY] Error grouping cars by make: $e');
      return {};
    }
  }

  /// Get summary statistics for part compatibility
  static Future<PartCompatibilityStats> getPartCompatibilityStats(
    String partNumber,
  ) async {
    try {
      final cars = await getCarsForPart(partNumber);

      Set<String> uniqueMakes = {};
      Set<String> uniqueModels = {};
      Set<int> uniqueYears = {};

      for (final car in cars) {
        uniqueMakes.add(car.make);
        uniqueModels.add('${car.make} ${car.model}');
        uniqueYears.add(car.year);
      }

      return PartCompatibilityStats(
        totalCars: cars.length,
        uniqueMakes: uniqueMakes.length,
        uniqueModels: uniqueModels.length,
        yearRange: uniqueYears.isEmpty
            ? 'Unknown'
            : '${uniqueYears.reduce((a, b) => a < b ? a : b)}-${uniqueYears.reduce((a, b) => a > b ? a : b)}',
        makes: uniqueMakes.toList()..sort(),
      );
    } catch (e) {
      print('❌ [PART_COMPATIBILITY] Error getting compatibility stats: $e');
      return PartCompatibilityStats(
        totalCars: 0,
        uniqueMakes: 0,
        uniqueModels: 0,
        yearRange: 'Unknown',
        makes: [],
      );
    }
  }
}

/// Represents a car that is compatible with a specific part
class CompatibleCar {
  final int id;
  final String make;
  final String model;
  final int year;

  CompatibleCar({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
  });

  String get displayName => '$make $model ($year)';
  String get shortName => '$make $model';

  Map<String, dynamic> toJson() {
    return {'id': id, 'make': make, 'model': model, 'year': year};
  }

  factory CompatibleCar.fromJson(Map<String, dynamic> json) {
    return CompatibleCar(
      id: json['id'],
      make: json['make'],
      model: json['model'],
      year: json['year'],
    );
  }

  @override
  String toString() {
    return 'CompatibleCar(id: $id, make: $make, model: $model, year: $year)';
  }
}

/// Statistics about part compatibility across vehicles
class PartCompatibilityStats {
  final int totalCars;
  final int uniqueMakes;
  final int uniqueModels;
  final String yearRange;
  final List<String> makes;

  PartCompatibilityStats({
    required this.totalCars,
    required this.uniqueMakes,
    required this.uniqueModels,
    required this.yearRange,
    required this.makes,
  });

  bool get hasData => totalCars > 0;

  String get summary {
    if (!hasData) return 'No compatibility data available';

    return 'Compatible with $totalCars vehicles across $uniqueMakes brands ($yearRange)';
  }

  @override
  String toString() {
    return 'PartCompatibilityStats(totalCars: $totalCars, uniqueMakes: $uniqueMakes, yearRange: $yearRange)';
  }
}
