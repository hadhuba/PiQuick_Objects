// Extracted reusable widget for the filter list
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/filters/model/filter.dart';
import 'package:frontend/features/filters/view/widgets/filter_input_field.dart';
import 'package:frontend/features/filters/viewModel/filters_view_model.dart';

class FilterList extends StatelessWidget {
  final List<Filter> filtersList;
  final WidgetRef ref;

  const FilterList({
    required this.filtersList,
    required this.ref,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: filtersList.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final filter = filtersList[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tooltip(
                message: filter.description ?? '',
                child: Text(
                  filter.type,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilterInputField(
                      label: 'Min:',
                      initialValue: filter.minValue?.toString(),
                      onChanged: (value) {
                        final num? newMin = value.isEmpty ? null : num.tryParse(value);
                        ref.read(filtersViewModelProvider.notifier).updateFilter(
                          type: filter.type,
                          minValue: newMin,
                          maxValue: filter.maxValue,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilterInputField(
                      label: 'Max:',
                      initialValue: filter.maxValue?.toString(),
                      onChanged: (value) {
                        final num? newMax = value.isEmpty ? null : num.tryParse(value);
                        ref.read(filtersViewModelProvider.notifier).updateFilter(
                          type: filter.type,
                          minValue: filter.minValue,
                          maxValue: newMax,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
