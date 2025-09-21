import 'package:flutter/material.dart';

class CountryCodePicker extends StatelessWidget {
  final String initialValue;
  final Function(String) onChanged;

  const CountryCodePicker({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  static const Map<String, String> _countryCodes = {
    '+972': 'Israel',
    '+970': 'Palestine',
    '+962': 'Jordan',
    '+20': 'Egypt',
    '+966': 'Saudi Arabia',
    '+971': 'UAE',
    '+974': 'Qatar',
    '+973': 'Bahrain',
    '+968': 'Oman',
    '+965': 'Kuwait',
    '+961': 'Lebanon',
    '+963': 'Syria',
    // Add more country codes as needed
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: initialValue,
          items: _countryCodes.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text('${entry.key} (${entry.value})'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}
