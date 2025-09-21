import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  // Query all cars
  Future<List<Map<String, dynamic>>> getCars() async {
    final response = await client.from('cars').select().then((data) => data);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // Query unique car makes
  Future<List<String>> getCarMakes() async {
    final response = await client
        .from('cars')
        .select('make')
        .then((data) => data);

    final List<String> makes = (response as List)
        .map((item) => item['make'] as String)
        .where((make) => make.isNotEmpty)
        .toSet() // Remove duplicates
        .toList();

    makes.sort(); // Sort alphabetically
    return makes;
  }

  // Query car details by make from cars table
  Future<List<Map<String, dynamic>>> getCarPartsByMake(String make) async {
    print('🔍 [SUPABASE] Fetching car data for make: $make');

    final response = await client
        .from('cars')
        .select('*')
        .eq('make', make)
        .then((data) => data);

    print('📊 [SUPABASE] Found ${(response as List).length} records for $make');
    return List<Map<String, dynamic>>.from(response as List);
  }

  // Query all parts for a specific car
  Future<List<Map<String, dynamic>>> getPartsForCar(int carId) async {
    final response = await client.from('parts').select().eq('id_cars', carId);
    return List<Map<String, dynamic>>.from(response as List);
  }

  // Query all cars for a specific part
  Future<List<Map<String, dynamic>>> getCarsForPart(String partNumber) async {
    final response = await client
        .from('parts')
        .select('id_cars')
        .eq('part_number', partNumber);
    return List<Map<String, dynamic>>.from(response as List);
  }
}
