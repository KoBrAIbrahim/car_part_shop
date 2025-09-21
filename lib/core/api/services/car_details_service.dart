import '../models/car_details.dart';
import '../../supabase_service.dart';

class CarDetailsService {
  static final SupabaseService _supabaseService = SupabaseService();

  /// Get all car details for a specific make from Supabase
  static Future<List<CarDetails>> fetchCarDetailsByMake(String make) async {
    try {
      print('🔍 [DEBUG] Fetching car details for make: $make');

      final data = await _supabaseService.getCarPartsByMake(make);
      print('📊 [DEBUG] Raw data from Supabase: ${data.length} records');

      if (data.isNotEmpty) {
        print(
          '📋 [DEBUG] Sample record structure: ${data.first.keys.toList()}',
        );
        print('📋 [DEBUG] Sample record: ${data.first}');
      }

      List<CarDetails> carDetails = [];
      for (final item in data) {
        try {
          final carDetail = CarDetails.fromJson(item);
          carDetails.add(carDetail);
        } catch (e) {
          print('⚠️ [DEBUG] Error parsing record: $item - Error: $e');
        }
      }

      print(
        '📊 [DEBUG] Successfully parsed ${carDetails.length} car details for $make',
      );
      return carDetails;
    } catch (e) {
      print('❌ [DEBUG] Error fetching car details: $e');
      throw Exception('Failed to fetch car details: $e');
    }
  }

  /// Get unique models for a specific make
  static Future<List<CarDetailOption>> getUniqueModels(String make) async {
    try {
      final carDetails = await fetchCarDetailsByMake(make);
      final Set<String> uniqueModels = {};

      for (final detail in carDetails) {
        if (detail.model.isNotEmpty) {
          uniqueModels.add(detail.model);
        }
      }

      final models = uniqueModels
          .map((model) => CarDetailOption(value: model))
          .toList();
      models.sort((a, b) => a.value.compareTo(b.value));

      print('🚗 [DEBUG] Found ${models.length} unique models for $make');
      return models;
    } catch (e) {
      print('❌ [DEBUG] Error fetching models: $e');
      return [];
    }
  }

  /// Get unique years for a specific make and model
  static Future<List<CarDetailOption>> getUniqueYears(
    String make, [
    String? model,
  ]) async {
    try {
      final carDetails = await fetchCarDetailsByMake(make);
      final Set<int> uniqueYears = {};

      for (final detail in carDetails) {
        if (model == null || detail.model == model) {
          if (detail.year > 0) {
            uniqueYears.add(detail.year);
          }
        }
      }

      final years = uniqueYears
          .map((year) => CarDetailOption(value: year.toString()))
          .toList();
      years.sort(
        (a, b) => b.value.compareTo(a.value),
      ); // Sort descending (newest first)

      print(
        '📅 [DEBUG] Found ${years.length} unique years for $make${model != null ? " $model" : ""}',
      );
      return years;
    } catch (e) {
      print('❌ [DEBUG] Error fetching years: $e');
      return [];
    }
  }

  /// Get unique engines for a specific make, model, and year
  static Future<List<CarDetailOption>> getUniqueEngines(
    String make, [
    String? model,
    String? year,
  ]) async {
    try {
      final carDetails = await fetchCarDetailsByMake(make);
      final Set<String> uniqueEngines = {};

      for (final detail in carDetails) {
        bool matches = true;

        if (model != null && detail.model != model) {
          matches = false;
        }

        if (year != null && detail.year.toString() != year) {
          matches = false;
        }

        if (matches && detail.engine.isNotEmpty) {
          uniqueEngines.add(detail.engine);
        }
      }

      final engines = uniqueEngines
          .map((engine) => CarDetailOption(value: engine))
          .toList();
      engines.sort((a, b) => a.value.compareTo(b.value));

      print(
        '🔧 [DEBUG] Found ${engines.length} unique engines for $make${model != null ? " $model" : ""}${year != null ? " $year" : ""}',
      );
      return engines;
    } catch (e) {
      print('❌ [DEBUG] Error fetching engines: $e');
      return [];
    }
  }

  /// Check if a specific combination is available
  static Future<bool> isCombinatonAvailable(
    String make,
    String model,
    String year,
    String engine,
  ) async {
    try {
      final carDetails = await fetchCarDetailsByMake(make);

      for (final detail in carDetails) {
        if (detail.make == make &&
            detail.model == model &&
            detail.year.toString() == year &&
            detail.engine == engine) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('❌ [DEBUG] Error checking combination availability: $e');
      return false;
    }
  }

  /// Get car ID for a specific combination
  static Future<int?> getCarId(
    String make,
    String model,
    String year,
    String engine,
  ) async {
    try {
      print('🔍 [DEBUG] Looking for car ID with: $make $model $year $engine');
      final carDetails = await fetchCarDetailsByMake(make);

      for (final detail in carDetails) {
        if (detail.make == make &&
            detail.model == model &&
            detail.year.toString() == year &&
            detail.engine == engine) {
          print('✅ [DEBUG] Found car ID: ${detail.id}');
          return detail.id;
        }
      }

      print('❌ [DEBUG] No car found with the specified criteria');
      return null;
    } catch (e) {
      print('❌ [DEBUG] Error getting car ID: $e');
      return null;
    }
  }
}
