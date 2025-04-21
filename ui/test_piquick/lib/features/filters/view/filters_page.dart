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
    final isLoading = ref.watch(filtersViewModelProvider).filters.isLoading;

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
                                title: Tooltip(
                                  message: filter.description ?? '',
                                  child: Text(filter.type),
                                ),
                                subtitle: Row(
                                  children: [
                                    const Text('Min: '),
                                    SizedBox(
                                      width: 60,
                                      child: TextFormField(
                                        initialValue:
                                            filter.minValue?.toString(),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 4,
                                          ),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          final num? newMin =
                                              value.isEmpty
                                                  ? null
                                                  : num.tryParse(value);
                                          ref
                                              .read(
                                                filtersViewModelProvider
                                                    .notifier,
                                              )
                                              .updateFilter(
                                                type: filter.type,
                                                minValue: newMin,
                                                maxValue: filter.maxValue,
                                              );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Max: '),
                                    SizedBox(
                                      width: 60,
                                      child: TextFormField(
                                        initialValue:
                                            filter.maxValue?.toString(),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 4,
                                          ),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          final num? newMax =
                                              value.isEmpty
                                                  ? null
                                                  : num.tryParse(value);
                                          ref
                                              .read(
                                                filtersViewModelProvider
                                                    .notifier,
                                              )
                                              .updateFilter(
                                                type: filter.type,
                                                minValue: filter.minValue,
                                                maxValue: newMax,
                                              );
                                        },
                                      ),
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
                            Navigator.of(context).pop();
                            // Handle the fetched IDs
                          },
                          child: const Text('Apply Filters'),
                        ),
                        // ElevatedButton(
                        //   onPressed: () =>                           child: const Text('Close'),
                        // ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
