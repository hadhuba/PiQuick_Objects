import 'package:flutter/material.dart';
import 'package:test_piquick/core/widgets/loader.dart';
import 'package:test_piquick/features/filters/viewModel/filters_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FiltersPage extends ConsumerStatefulWidget {
  const FiltersPage({super.key});

  @override
  ConsumerState<FiltersPage> createState() => _FiltersPageState();
}

class _FiltersPageState extends ConsumerState<FiltersPage> {
  final formKey = GlobalKey<FormState>(); //is it necessary?

  //TODO necessary?
  @override
  void dispose() {
    super.dispose();
    // formKey.currentState!.validate();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        ref.watch(filtersViewModelProvider).filters.isLoading;

    final filtersList = ref.watch(filtersViewModelProvider).filtersList;
    final objects = ref.watch(filtersViewModelProvider).objectsList;

    return Scaffold(
      appBar: AppBar(),
      body:
          isLoading
              ? const Loader()
              : Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.6,
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Objects',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: objects.when(
                            data:
                                (objectsList) => ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: objectsList.length,
                                  itemBuilder: (context, index) {
                                    final object = objectsList[index];
                                    return Text(
                                      object,
                                    ); // Display the ID of each object
                                  },
                                ),
                            loading:
                                () =>
                                    const CircularProgressIndicator(), // Show a loader while loading
                            error:
                                (error, stackTrace) =>
                                    Text('Error: $error'), // Show error message
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          // Ensure ListView.builder has a constrained height
                          child: ListView.builder(
                            itemCount: filtersList!.length, //TODO null check

                            itemBuilder: (context, index) {
                              final filter = filtersList[index];
                              return ListTile(
                                title: Text(filter.type),
                                subtitle: Row(
                                  children: [
                                    const Text('Min: '),
                                    DropdownButton<int>(
                                      value:
                                          filter.minValue
                                              as int?, // Show current minValue as placeholder
                                      items:
                                          List.generate(10, (i) => i).map((
                                            int value,
                                          ) {
                                            return DropdownMenuItem<int>(
                                              value: value,
                                              child: Text(value.toString()),
                                            );
                                          }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          ref
                                              .read(filtersViewModelProvider.notifier)
                                              .updateFilter(
                                                type: filter.type,
                                                minValue:
                                                    value, // Update the minValue
                                                maxValue: filter.maxValue,
                                              );
                                        }
                                      },
                                    ),
                                    const Text(' Max: '),
                                    DropdownButton<int>(
                                      value:
                                          filter.maxValue
                                              as int?, // Show current maxValue as placeholder
                                      items:
                                          List.generate(10, (i) => i).map((
                                            int value,
                                          ) {
                                            return DropdownMenuItem<int>(
                                              value: value,
                                              child: Text(value.toString()),
                                            );
                                          }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          ref
                                              .read(filtersViewModelProvider.notifier)
                                              .updateFilter(
                                                type: filter.type,
                                                maxValue:
                                                    value, // Update the maxValue
                                                minValue: filter.minValue,
                                              );
                                        }
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
                            ref
                                .read(filtersViewModelProvider.notifier)
                                .applyFilters();
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
              ),
    );
  }
}
