import 'package:flutter/material.dart';
import 'vin_decoder_service.dart';
import 'car_lookup_service.dart';

/// Service for handling search operations from the home page
class SearchService {
  /// Determine search type based on input
  static SearchType determineSearchType(String input) {
    final trimmed = input.trim();

    if (trimmed.isEmpty) return SearchType.empty;

    // Check if it's a VIN (17 alphanumeric characters, no I/O/Q)
    if (VinDecoderService.isValidVinFormat(trimmed)) {
      return SearchType.vin;
    }

    // Check if it looks like a part number (contains alphanumeric with dashes/underscores)
    if (_isPartNumberFormat(trimmed)) {
      return SearchType.partNumber;
    }

    // Default to general search (car make/model search)
    return SearchType.general;
  }

  /// Check if input looks like a part number
  static bool _isPartNumberFormat(String input) {
    // Part numbers typically contain:
    // - Letters and numbers
    // - May have dashes, underscores, or dots
    // - Usually 6+ characters
    // - No spaces
    final partNumberRegex = RegExp(r'^[A-Z0-9\-_.]{6,}$', caseSensitive: false);
    return partNumberRegex.hasMatch(input.replaceAll(' ', ''));
  }

  /// Perform search based on input type
  static Future<SearchResult> performSearch(String input) async {
    final searchType = determineSearchType(input);

    print('🔍 [SEARCH] Performing ${searchType.name} search for: "$input"');

    switch (searchType) {
      case SearchType.vin:
        return await _performVinSearch(input);
      case SearchType.partNumber:
        return await _performPartNumberSearch(input);
      case SearchType.general:
        return SearchResult(
          type: SearchType.general,
          success: false,
          message:
              'General search not implemented yet. Please enter a VIN or part number.',
        );
      case SearchType.empty:
        return SearchResult(
          type: SearchType.empty,
          success: false,
          message: 'Please enter a search term.',
        );
    }
  }

  /// Perform VIN-based search
  static Future<SearchResult> _performVinSearch(String vin) async {
    try {
      // First validate the VIN
      if (!VinDecoderService.isValidVinFormat(vin)) {
        return SearchResult(
          type: SearchType.vin,
          success: false,
          message:
              'Invalid VIN format. VIN must be 17 characters (A-Z, 0-9, no I/O/Q).',
        );
      }

      // Decode the VIN
      final vinResult = await VinDecoderService.decodeVin(vin);
      if (vinResult == null || !vinResult.hasValidData) {
        return SearchResult(
          type: SearchType.vin,
          success: false,
          message: 'Unable to decode VIN. Please verify the VIN is correct.',
          vinData: vinResult,
        );
      }

      // Find matching car in database
      final carResult = await CarLookupService.findCarByVin(vin);
      if (carResult == null) {
        // VIN decoded but no matching car found
        return SearchResult(
          type: SearchType.vin,
          success: false,
          message:
              'VIN decoded successfully, but no matching vehicle found in our database.',
          vinData: vinResult,
          suggestions: await _getVinSuggestions(vinResult),
        );
      }

      // Success!
      return SearchResult(
        type: SearchType.vin,
        success: true,
        message: 'Vehicle found: ${carResult.displayName}',
        carResult: carResult,
        vinData: vinResult,
      );
    } catch (e) {
      print('❌ [SEARCH] VIN search error: $e');
      return SearchResult(
        type: SearchType.vin,
        success: false,
        message: 'Error processing VIN. Please try again.',
      );
    }
  }

  /// Perform part number search
  static Future<SearchResult> _performPartNumberSearch(
    String partNumber,
  ) async {
    try {
      final cleanPartNumber = partNumber.trim().toUpperCase();

      // Find cars that have this part number
      final carResults = await CarLookupService.findCarsByPartNumber(
        cleanPartNumber,
      );

      if (carResults.isEmpty) {
        return SearchResult(
          type: SearchType.partNumber,
          success: false,
          message: 'Part number "$cleanPartNumber" not found in our database.',
        );
      }

      // If multiple cars found, use the first one but provide alternatives
      final primaryCar = carResults.first;
      final alternatives = carResults.length > 1
          ? carResults.skip(1).toList()
          : <CarLookupResult>[];

      return SearchResult(
        type: SearchType.partNumber,
        success: true,
        message: carResults.length == 1
            ? 'Part found for: ${primaryCar.displayName}'
            : 'Part found for ${carResults.length} vehicles. Showing: ${primaryCar.displayName}',
        carResult: primaryCar,
        partNumber: cleanPartNumber,
        alternatives: alternatives,
      );
    } catch (e) {
      print('❌ [SEARCH] Part number search error: $e');
      return SearchResult(
        type: SearchType.partNumber,
        success: false,
        message: 'Error searching for part number. Please try again.',
      );
    }
  }

  /// Get suggestions for VIN that couldn't find exact car match
  static Future<List<CarLookupResult>> _getVinSuggestions(
    VinDecodeResult vinResult,
  ) async {
    if (vinResult.make == null || vinResult.model == null) return [];

    try {
      return await CarLookupService.findCarsByFuzzyMatch(
        make: vinResult.make!,
        model: vinResult.model!,
        year: vinResult.year,
      );
    } catch (e) {
      print('❌ [SEARCH] Error getting VIN suggestions: $e');
      return [];
    }
  }

  /// Get user-friendly validation message for input
  static String getValidationMessage(String input) {
    final type = determineSearchType(input);

    switch (type) {
      case SearchType.empty:
        return 'Enter a VIN code or part number to search';
      case SearchType.vin:
        if (VinDecoderService.isValidVinFormat(input)) {
          return 'Valid VIN format ✓';
        } else {
          return 'Invalid VIN format (must be 17 characters, no I/O/Q)';
        }
      case SearchType.partNumber:
        return 'Searching for part number...';
      case SearchType.general:
        return 'General search (not yet supported)';
    }
  }

  /// Get search type icon
  static IconData getSearchTypeIcon(SearchType type) {
    switch (type) {
      case SearchType.vin:
        return Icons.qr_code_scanner;
      case SearchType.partNumber:
        return Icons.precision_manufacturing;
      case SearchType.general:
        return Icons.search;
      case SearchType.empty:
        return Icons.search;
    }
  }

  /// Get search type color
  static Color getSearchTypeColor(SearchType type, bool isValid) {
    switch (type) {
      case SearchType.vin:
        return isValid ? Colors.green : Colors.orange;
      case SearchType.partNumber:
        return Colors.blue;
      case SearchType.general:
        return Colors.grey;
      case SearchType.empty:
        return Colors.grey;
    }
  }
}

/// Types of search supported
enum SearchType { empty, vin, partNumber, general }

/// Result of a search operation
class SearchResult {
  final SearchType type;
  final bool success;
  final String message;
  final CarLookupResult? carResult;
  final VinDecodeResult? vinData;
  final String? partNumber;
  final List<CarLookupResult>? alternatives;
  final List<CarLookupResult>? suggestions;

  SearchResult({
    required this.type,
    required this.success,
    required this.message,
    this.carResult,
    this.vinData,
    this.partNumber,
    this.alternatives,
    this.suggestions,
  });

  bool get hasCarResult => carResult != null;
  bool get hasAlternatives => alternatives != null && alternatives!.isNotEmpty;
  bool get hasSuggestions => suggestions != null && suggestions!.isNotEmpty;

  @override
  String toString() {
    return 'SearchResult(type: $type, success: $success, message: $message, hasCarResult: $hasCarResult)';
  }
}

/// Extension for SearchType to get display names
extension SearchTypeExtension on SearchType {
  String get displayName {
    switch (this) {
      case SearchType.empty:
        return 'Empty';
      case SearchType.vin:
        return 'VIN Code';
      case SearchType.partNumber:
        return 'Part Number';
      case SearchType.general:
        return 'General Search';
    }
  }

  String get hint {
    switch (this) {
      case SearchType.empty:
        return 'Enter VIN or part number...';
      case SearchType.vin:
        return 'Enter 17-character VIN...';
      case SearchType.partNumber:
        return 'Enter part number...';
      case SearchType.general:
        return 'Search cars...';
    }
  }
}
