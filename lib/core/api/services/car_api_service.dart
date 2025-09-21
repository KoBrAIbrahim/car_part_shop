import '../models/car_make.dart';
import '../../supabase_service.dart';

class CarApiService {
  static final SupabaseService _supabaseService = SupabaseService();

  /// Get car makes from Supabase with their logos from GitHub dataset
  static Future<List<CarMake>> fetchCarMakesFromSupabase() async {
    try {
      print('🔍 [DEBUG] Fetching car makes from Supabase...');

      // Get unique car makes from Supabase
      final List<String> makeNames = await _supabaseService.getCarMakes();

      print('📊 [DEBUG] Total unique makes found: ${makeNames.length}');
      print('🚗 [DEBUG] Car makes list:');
      for (int i = 0; i < makeNames.length; i++) {
        print('   ${i + 1}. ${makeNames[i]}');
      }

      // Convert to CarMake objects with GitHub logos
      List<CarMake> carMakes = [];
      for (int i = 0; i < makeNames.length; i++) {
        final makeName = makeNames[i];
        final logoUrl = _getCarLogoUrl(makeName);
        print('🔗 [DEBUG] ${makeName} -> ${logoUrl}');
        carMakes.add(CarMake(id: i + 1, name: makeName, logoUrl: logoUrl));
      }

      print(
        '✅ [DEBUG] Successfully created ${carMakes.length} CarMake objects',
      );
      return carMakes;
    } catch (e) {
      // If Supabase fails, return empty list or throw error
      print('❌ [DEBUG] Error fetching car makes: $e');
      throw Exception('Failed to fetch car makes from Supabase: $e');
    }
  }

  /// Generate GitHub car logo URL for a given make
  static String _getCarLogoUrl(String makeName) {
    // Convert make name to lowercase and replace spaces with hyphens for GitHub dataset
    final formattedName = makeName
        .toLowerCase()
        .replaceAll(' ', '-')
        .replaceAll('_', '-');

    return 'https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/original/$formattedName.png';
  }
}
