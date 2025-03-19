import 'package:flutter/material.dart';
import 'package:test_piquick/viewModel/filters_view_model.dart';
import 'package:provider/provider.dart';

class FiltersView extends StatelessWidget {
  const FiltersView({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(16.0),
        child: ChangeNotifierProvider(
          create: (_) => FiltersViewModel(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded( // Ensure ListView.builder has a constrained height
                child: Consumer<FiltersViewModel>(
                  builder: (context, viewModel, child) {
                    return ListView.builder(
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
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  context.read<FiltersViewModel>().applyFilters();
                  // Handle the fetched IDs
                },
                child: const Text('Apply Filters'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}