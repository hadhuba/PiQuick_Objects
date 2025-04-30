import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';

/// A reusable input field specifically designed for filter values.
/// Provides a labeled text field for entering numerical filter criteria.
class FilterInputField extends StatelessWidget {
  final String label;
  final String? initialValue;
  final void Function(String) onChanged;

  const FilterInputField({
    required this.label,
    this.initialValue,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        TextFormField(
          initialValue: initialValue,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: label,
          ),
          keyboardType: TextInputType.number,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
