import '../supabase_service.dart';
import 'vin_decoder_service.dart';

/// Service for looking up car IDs from Supabase based on vehicle information
class CarLookupService {
  static final SupabaseService _supabaseService = SupabaseService();

  /// Find car ID by exact make, model, and year match
  static Future<CarLookupResult?> findCarByExactMatch({
    required String make,
    required String model,
    required int year,
  }) async {
    try {
      print('🔍 [CAR_LOOKUP] Searching for exact match: $make $model $year');

      final response = await _supabaseService.client
          .from('cars')
          .select('id, make, model, year')
          .ilike('make', make)
          .ilike('model', model)
          .eq('year', year)
          .limit(1);

      if (response.isNotEmpty) {
        final carData = response.first;
        print(
          '✅ [CAR_LOOKUP] Found exact match: ${carData['id']} - ${carData['make']} ${carData['model']} ${carData['year']}',
        );

        return CarLookupResult(
          carId: carData['id'],
          make: carData['make'],
          model: carData['model'],
          year: carData['year'],
          matchType: CarMatchType.exactMatch,
          confidence: 100,
        );
      }

      print('⚠️ [CAR_LOOKUP] No exact match found');
      return null;
    } catch (e) {
      print('❌ [CAR_LOOKUP] Error finding exact match: $e');
      return null;
    }
  }

  /// Find car ID by fuzzy matching (similar make/model)
  static Future<List<CarLookupResult>> findCarsByFuzzyMatch({
    required String make,
    required String model,
    int? year,
  }) async {
    try {
      print(
        '🔍 [CAR_LOOKUP] Searching for fuzzy match: $make $model ${year ?? 'any year'}',
      );

      var query = _supabaseService.client
          .from('cars')
          .select('id, make, model, year')
          .ilike('make', '%$make%')
          .ilike('model', '%$model%');

      if (year != null) {
        // Search for year within ±2 years range
        query = query.gte('year', year - 2).lte('year', year + 2);
      }

      final response = await query.limit(10);

      List<CarLookupResult> results = [];

      for (final carData in response) {
        final similarity = _calculateSimilarity(
          make,
          model,
          year,
          carData['make'],
          carData['model'],
          carData['year'],
        );

        if (similarity > 0.3) {
          // Only include results with >30% similarity
          results.add(
            CarLookupResult(
              carId: carData['id'],
              make: carData['make'],
              model: carData['model'],
              year: carData['year'],
              matchType: CarMatchType.fuzzyMatch,
              confidence: (similarity * 100).round(),
            ),
          );
        }
      }

      // Sort by confidence descending
      results.sort((a, b) => b.confidence.compareTo(a.confidence));

      print('✅ [CAR_LOOKUP] Found ${results.length} fuzzy matches');
      return results;
    } catch (e) {
      print('❌ [CAR_LOOKUP] Error finding fuzzy matches: $e');
      return [];
    }
  }

  /// Find car ID from VIN decoding
  static Future<CarLookupResult?> findCarByVin(String vin) async {
    try {
      print('🔍 [CAR_LOOKUP] Looking up car by VIN: $vin');

      final vinResult = await VinDecoderService.decodeVin(vin);
      if (vinResult == null || !vinResult.hasValidData) {
        print('⚠️ [CAR_LOOKUP] VIN decoding failed or insufficient data');
        return null;
      }

      // Try exact match first
      if (vinResult.make != null &&
          vinResult.model != null &&
          vinResult.year != null) {
        final exactMatch = await findCarByExactMatch(
          make: vinResult.make!,
          model: vinResult.model!,
          year: vinResult.year!,
        );

        if (exactMatch != null) {
          return exactMatch.copyWith(
            vinData: vinResult,
            matchType: CarMatchType.vinExactMatch,
          );
        }
      }

      // Try fuzzy match if exact match fails
      if (vinResult.make != null && vinResult.model != null) {
        final fuzzyMatches = await findCarsByFuzzyMatch(
          make: vinResult.make!,
          model: vinResult.model!,
          year: vinResult.year,
        );

        if (fuzzyMatches.isNotEmpty) {
          return fuzzyMatches.first.copyWith(
            vinData: vinResult,
            matchType: CarMatchType.vinFuzzyMatch,
          );
        }
      }

      print('⚠️ [CAR_LOOKUP] No car found for VIN');
      return null;
    } catch (e) {
      print('❌ [CAR_LOOKUP] Error looking up car by VIN: $e');
      return null;
    }
  }

  /// Search for cars by part number
  static Future<List<CarLookupResult>> findCarsByPartNumber(
    String partNumber,
  ) async {
    try {
      print('🔍 [CAR_LOOKUP] Searching cars by part number: $partNumber');

      final response = await _supabaseService.client
          .from('parts')
          .select('id_cars, cars(id, make, model, year)')
          .eq('part_number', partNumber)
          .limit(10);

      List<CarLookupResult> results = [];
      Set<int> seenCarIds = {};

      for (final partData in response) {
        final carData = partData['cars'];
        if (carData != null) {
          final carId = carData['id'];

          // Avoid duplicates
          if (!seenCarIds.contains(carId)) {
            seenCarIds.add(carId);

            results.add(
              CarLookupResult(
                carId: carId,
                make: carData['make'],
                model: carData['model'],
                year: carData['year'],
                matchType: CarMatchType.partNumberMatch,
                confidence: 95,
                partNumber: partNumber,
              ),
            );
          }
        }
      }

      print(
        '✅ [CAR_LOOKUP] Found ${results.length} cars for part number: $partNumber',
      );
      return results;
    } catch (e) {
      print('❌ [CAR_LOOKUP] Error finding cars by part number: $e');
      return [];
    }
  }

  /// Get all available years for a specific make and model
  static Future<List<int>> getAvailableYears({
    required String make,
    required String model,
  }) async {
    try {
      final response = await _supabaseService.client
          .from('cars')
          .select('year')
          .ilike('make', make)
          .ilike('model', model)
          .order('year', ascending: true);

      return response.map<int>((car) => car['year'] as int).toSet().toList();
    } catch (e) {
      print('❌ [CAR_LOOKUP] Error getting available years: $e');
      return [];
    }
  }

  /// Calculate similarity between car data
  static double _calculateSimilarity(
    String searchMake,
    String searchModel,
    int? searchYear,
    String dbMake,
    String dbModel,
    int dbYear,
  ) {
    double makeScore = _stringSimilarity(
      searchMake.toLowerCase(),
      dbMake.toLowerCase(),
    );
    double modelScore = _stringSimilarity(
      searchModel.toLowerCase(),
      dbModel.toLowerCase(),
    );
    double yearScore = 1.0;

    if (searchYear != null) {
      final yearDiff = (searchYear - dbYear).abs();
      yearScore = yearDiff == 0 ? 1.0 : (yearDiff <= 2 ? 0.8 : 0.3);
    }

    // Weighted average: make=40%, model=40%, year=20%
    return (makeScore * 0.4) + (modelScore * 0.4) + (yearScore * 0.2);
  }

  /// Calculate string similarity using Levenshtein distance
  static double _stringSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final matrix = List.generate(
      a.length + 1,
      (i) => List.generate(b.length + 1, (j) => 0),
    );

    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    final maxLength = a.length > b.length ? a.length : b.length;
    return 1.0 - (matrix[a.length][b.length] / maxLength);
  }
}

/// Result of car lookup operation
class CarLookupResult {
  final int carId;
  final String make;
  final String model;
  final int year;
  final CarMatchType matchType;
  final int confidence;
  final VinDecodeResult? vinData;
  final String? partNumber;

  CarLookupResult({
    required this.carId,
    required this.make,
    required this.model,
    required this.year,
    required this.matchType,
    required this.confidence,
    this.vinData,
    this.partNumber,
  });

  String get displayName => '$make $model $year';

  CarLookupResult copyWith({
    int? carId,
    String? make,
    String? model,
    int? year,
    CarMatchType? matchType,
    int? confidence,
    VinDecodeResult? vinData,
    String? partNumber,
  }) {
    return CarLookupResult(
      carId: carId ?? this.carId,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      matchType: matchType ?? this.matchType,
      confidence: confidence ?? this.confidence,
      vinData: vinData ?? this.vinData,
      partNumber: partNumber ?? this.partNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'carId': carId,
      'make': make,
      'model': model,
      'year': year,
      'matchType': matchType.index,
      'confidence': confidence,
      'vinData': vinData?.toJson(),
      'partNumber': partNumber,
    };
  }

  @override
  String toString() {
    return 'CarLookupResult(carId: $carId, make: $make, model: $model, year: $year, confidence: $confidence%, type: $matchType)';
  }
}

/// Types of car matches
enum CarMatchType {
  exactMatch,
  fuzzyMatch,
  vinExactMatch,
  vinFuzzyMatch,
  partNumberMatch,
}

/// Extension for CarMatchType to get display names
extension CarMatchTypeExtension on CarMatchType {
  String get displayName {
    switch (this) {
      case CarMatchType.exactMatch:
        return 'Exact Match';
      case CarMatchType.fuzzyMatch:
        return 'Similar Match';
      case CarMatchType.vinExactMatch:
        return 'VIN Exact Match';
      case CarMatchType.vinFuzzyMatch:
        return 'VIN Similar Match';
      case CarMatchType.partNumberMatch:
        return 'Part Number Match';
    }
  }

  bool get isHighConfidence {
    switch (this) {
      case CarMatchType.exactMatch:
      case CarMatchType.vinExactMatch:
      case CarMatchType.partNumberMatch:
        return true;
      case CarMatchType.fuzzyMatch:
      case CarMatchType.vinFuzzyMatch:
        return false;
    }
  }
}
