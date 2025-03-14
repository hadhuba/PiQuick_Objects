import 'package:flutter/material.dart';
import 'package:piquick_objects/viewModels/filters_view_model.dart';
import 'package:provider/provider.dart';

class FiltersView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FiltersViewModel(),
      child: Scaffold(
        appBar: AppBar(title:const Text('Filter Objects')),
        body: Consumer<FiltersViewModel>(
          builder: (context, viewModel, child) {
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: viewModel.filters.length,
                    itemBuilder: (context, index) {
                      final filter = viewModel.filters[index];
                      return ListTile(
                        title: Text(filter.type),
                        subtitle: Row(
                          children: [
                            Text('Min: '),
                            DropdownButton<int>(
                              value: filter.minValue as int?,
                              items: List.generate(10, (i) => i).map((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(value.toString()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                viewModel.updateFilter(filter.type, value!, filter.maxValue as int? ?? 0);
                              },
                            ),
                            Text(' Max: '),
                            DropdownButton<int>(
                              value: filter.maxValue as int?,
                              items: List.generate(10, (i) => i).map((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(value.toString()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                viewModel.updateFilter(filter.type, filter.minValue as int? ?? 0, value!);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    viewModel.applyFilters(); //probably await -> async fn
                    // Handle the fetched IDs
                  },
                  child: const Text('Apply Filters'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}