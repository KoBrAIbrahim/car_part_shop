import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';

class CitySelector extends StatelessWidget {
  final String? selectedCity;
  final Function(String?) onCityChanged;
  final String? Function(String?)? validator;
  final bool enabled;

  const CitySelector({
    super.key,
    required this.selectedCity,
    required this.onCityChanged,
    this.validator,
    this.enabled = true,
  });

  // Major Palestinian cities in English
  static const List<String> palestinianCities = [
    'Ramallah',
    'Nablus',
    'Bethlehem',
    'Hebron',
    'Jenin',
    'Tulkarm',
    'Qalqilya',
    'Salfit',
    'Jericho',
    'Tubas',
    'Al-Bireh',
    'Gaza',
    'Khan Younis',
    'Rafah',
    'Deir al-Balah',
    'Beit Lahia',
    'Beit Hanoun',
    'Jabalya',
  ];

  // Get translated city name based on current language
  String _getTranslatedCityName(String cityKey) {
    try {
      final translatedName = tr('cities.$cityKey');
      // If translation returns the key itself (meaning not found), return original name
      if (translatedName == 'cities.$cityKey') {
        return cityKey;
      }
      return translatedName;
    } catch (e) {
      // If translation not found, return the original English name
      return cityKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedCity,
      onChanged: enabled ? onCityChanged : null,
      validator: validator,
      decoration: InputDecoration(
        labelText: tr('auth.city'),
        prefixIcon: Icon(
          Icons.location_city_rounded,
          color: enabled ? AppColors.primary : Colors.grey,
        ),
        filled: true,
        fillColor: enabled
            ? AppColors.primary.withOpacity(0.05)
            : Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        labelStyle: TextStyle(color: enabled ? AppColors.primary : Colors.grey),
      ),
      dropdownColor: Theme.of(context).cardColor,
      icon: Icon(
        Icons.arrow_drop_down,
        color: enabled ? AppColors.primary : Colors.grey,
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            tr('auth.select_city'),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        ...palestinianCities.map((city) {
          return DropdownMenuItem<String>(
            value: city,
            child: Text(
              _getTranslatedCityName(city),
              style: const TextStyle(fontSize: 16),
            ),
          );
        }).toList(),
      ],
      isExpanded: true,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
        fontSize: 16,
      ),
    );
  }
}
