import 'dart:convert';
import 'package:http/http.dart' as http;

/// VIN Decoder Service for extracting vehicle information from VIN codes
class VinDecoderService {
  // VIN validation regex - 17 characters, excludes I, O, Q
  static final RegExp _vinRegex = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');

  /// Validate VIN format
  static bool isValidVinFormat(String vin) {
    return _vinRegex.hasMatch(vin.toUpperCase());
  }

  /// Decode VIN to extract vehicle information
  static Future<VinDecodeResult?> decodeVin(String vin) async {
    final normalizedVin = vin.toUpperCase().replaceAll(RegExp(r'\s+'), '');

    if (!isValidVinFormat(normalizedVin)) {
      return null;
    }

    try {
      // Use NHTSA vPIC API for VIN decoding
      final url =
          'https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVinValues/$normalizedVin?format=json';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['Results'];

        if (results != null && results.isNotEmpty) {
          final result = results[0];

          return VinDecodeResult(
            vin: normalizedVin,
            make: _cleanString(result['Make']),
            model: _cleanString(result['Model']),
            year: _parseYear(result['ModelYear']),
            vehicleType: _cleanString(result['VehicleType']),
            bodyClass: _cleanString(result['BodyClass']),
            engineSize: _cleanString(result['DisplacementL']),
            fuelType: _cleanString(result['FuelTypePrimary']),
            plantCountry: _cleanString(result['PlantCountry']),
            manufacturer: _cleanString(result['Manufacturer']),
            confidence: _calculateConfidence(result),
          );
        }
      }
    } catch (e) {
      print('❌ [VIN_DECODER] Error decoding VIN: $e');
    }

    // Fallback: Extract basic info from VIN structure
    return _extractBasicInfoFromVin(normalizedVin);
  }

  /// Extract basic information from VIN structure when API fails
  static VinDecodeResult _extractBasicInfoFromVin(String vin) {
    return VinDecodeResult(
      vin: vin,
      make: null,
      model: null,
      year: _guessModelYearFromVin(vin),
      vehicleType: null,
      bodyClass: null,
      engineSize: null,
      fuelType: null,
      plantCountry: _getRegionFromVin(vin),
      manufacturer: null,
      confidence: 30, // Low confidence for manual extraction
    );
  }

  /// Guess model year from VIN 10th digit
  static int? _guessModelYearFromVin(String vin) {
    if (vin.length != 17) return null;

    final yearChar = vin[9];
    final yearMap = {
      'A': 2010,
      'B': 2011,
      'C': 2012,
      'D': 2013,
      'E': 2014,
      'F': 2015,
      'G': 2016,
      'H': 2017,
      'J': 2018,
      'K': 2019,
      'L': 2020,
      'M': 2021,
      'N': 2022,
      'P': 2023,
      'R': 2024,
      'S': 2025,
      'T': 2026,
      'V': 2027,
      'W': 2028,
      'X': 2029,
      'Y': 2030,
      '1': 2001,
      '2': 2002,
      '3': 2003,
      '4': 2004,
      '5': 2005,
      '6': 2006,
      '7': 2007,
      '8': 2008,
      '9': 2009,
    };

    final yearValue = yearMap[yearChar];
    if (yearValue == null) return null;

    // Adjust for 30-year cycle
    final currentYear = DateTime.now().year;
    int adjustedYear = yearValue;

    while (adjustedYear + 30 <= currentYear + 1) {
      adjustedYear = adjustedYear + 30;
    }
    while (adjustedYear - 30 >= 1981 && adjustedYear > currentYear + 1) {
      adjustedYear = adjustedYear - 30;
    }

    return adjustedYear;
  }

  /// Get region from VIN first digit
  static String _getRegionFromVin(String vin) {
    if (vin.isEmpty) return 'Unknown';

    final firstChar = vin[0];

    if ('12345'.contains(firstChar)) return 'North America';
    if ('678'.contains(firstChar)) return 'Oceania';
    if ('J-R'.contains(firstChar)) return 'Asia';
    if ('S-Z'.contains(firstChar)) return 'Europe';
    if ('A-H'.contains(firstChar)) return 'Africa';

    return 'Unknown';
  }

  /// Clean and validate string from API response
  static String? _cleanString(dynamic value) {
    if (value == null) return null;
    final cleaned = value.toString().trim();
    if (cleaned.isEmpty || cleaned == 'Not Applicable' || cleaned == 'N/A') {
      return null;
    }
    return cleaned;
  }

  /// Parse year from API response
  static int? _parseYear(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  /// Calculate confidence score based on available data
  static int _calculateConfidence(Map<String, dynamic> result) {
    int score = 0;

    if (_cleanString(result['Make']) != null) score += 25;
    if (_cleanString(result['Model']) != null) score += 25;
    if (_parseYear(result['ModelYear']) != null) score += 20;
    if (_cleanString(result['VehicleType']) != null) score += 10;
    if (_cleanString(result['Manufacturer']) != null) score += 10;
    if (_cleanString(result['PlantCountry']) != null) score += 10;

    return score.clamp(0, 100);
  }

  /// Verify VIN check digit (optional validation)
  static bool verifyCheckDigit(String vin) {
    if (!isValidVinFormat(vin)) return false;

    final transliteration = {
      'A': 1,
      'B': 2,
      'C': 3,
      'D': 4,
      'E': 5,
      'F': 6,
      'G': 7,
      'H': 8,
      'J': 1,
      'K': 2,
      'L': 3,
      'M': 4,
      'N': 5,
      'P': 7,
      'R': 9,
      'S': 2,
      'T': 3,
      'U': 4,
      'V': 5,
      'W': 6,
      'X': 7,
      'Y': 8,
      'Z': 9,
    };

    final weights = [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2];

    int sum = 0;
    for (int i = 0; i < 17; i++) {
      final char = vin[i];
      int value;

      if (RegExp(r'\d').hasMatch(char)) {
        value = int.parse(char);
      } else {
        value = transliteration[char] ?? 0;
      }

      sum += value * weights[i];
    }

    final remainder = sum % 11;
    final expectedCheckDigit = remainder == 10 ? 'X' : remainder.toString();

    return vin[8] == expectedCheckDigit;
  }

  /// Search for similar VINs or partial matches
  static List<String> getSimilarVins(
    String partialVin,
    List<String> vinDatabase,
  ) {
    if (partialVin.length < 3) return [];

    final normalized = partialVin.toUpperCase();
    return vinDatabase
        .where((vin) => vin.toUpperCase().contains(normalized))
        .take(10)
        .toList();
  }
}

/// Result of VIN decoding operation
class VinDecodeResult {
  final String vin;
  final String? make;
  final String? model;
  final int? year;
  final String? vehicleType;
  final String? bodyClass;
  final String? engineSize;
  final String? fuelType;
  final String? plantCountry;
  final String? manufacturer;
  final int confidence;

  VinDecodeResult({
    required this.vin,
    this.make,
    this.model,
    this.year,
    this.vehicleType,
    this.bodyClass,
    this.engineSize,
    this.fuelType,
    this.plantCountry,
    this.manufacturer,
    required this.confidence,
  });

  bool get hasValidData => make != null || model != null || year != null;

  Map<String, dynamic> toJson() {
    return {
      'vin': vin,
      'make': make,
      'model': model,
      'year': year,
      'vehicleType': vehicleType,
      'bodyClass': bodyClass,
      'engineSize': engineSize,
      'fuelType': fuelType,
      'plantCountry': plantCountry,
      'manufacturer': manufacturer,
      'confidence': confidence,
    };
  }

  factory VinDecodeResult.fromJson(Map<String, dynamic> json) {
    return VinDecodeResult(
      vin: json['vin'],
      make: json['make'],
      model: json['model'],
      year: json['year'],
      vehicleType: json['vehicleType'],
      bodyClass: json['bodyClass'],
      engineSize: json['engineSize'],
      fuelType: json['fuelType'],
      plantCountry: json['plantCountry'],
      manufacturer: json['manufacturer'],
      confidence: json['confidence'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'VinDecodeResult(vin: $vin, make: $make, model: $model, year: $year, confidence: $confidence%)';
  }
}
