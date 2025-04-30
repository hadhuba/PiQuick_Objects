// FiltersPage: A Flutter widget that provides an interface for applying filters
// to a list of 3D objects. Features dynamic min/max value inputs for each filter type
// and real-time object list updates.

import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/loader.dart';
import 'package:frontend/features/filters/viewModel/filters_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/filters/view/widgets/object_list.dart';
import 'package:frontend/features/filters/view/widgets/filter_list.dart';

class FiltersPage extends ConsumerStatefulWidget {
  const FiltersPage({super.key});

  @override
  ConsumerState<FiltersPage> createState() => _FiltersPageState();
}

class _FiltersPageState extends ConsumerState<FiltersPage> {
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(filtersViewModelProvider).filters.isLoading;

    final filtersList = ref.watch(filtersViewModelProvider).filtersList;
    final objects = ref.watch(filtersViewModelProvider).objectsList;

    return Scaffold(
      appBar: AppBar(title: const Text('Filters'), centerTitle: true),
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
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Filters',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const Divider(),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child:
                                              filtersList == null ||
                                                      filtersList.isEmpty
                                                  ? const Center(
                                                    child: Text(
                                                      'No filters available',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  )
                                                  : FilterList(
                                                    filtersList: filtersList,
                                                    ref: ref,
                                                  ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 16),

                              Expanded(
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        objects.when(
                                          data:
                                              (objectsList) => Text(
                                                'Objects (${objectsList.length})',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                          loading:
                                              () => const Text(
                                                'Objects (loading...)',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                          error:
                                              (_, __) => const Text(
                                                'Objects (error)',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                ),
                                              ),
                                        ),
                                        const Divider(),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: objects.when(
                                            data:
                                                (objectsList) => ObjectList(
                                                  objects: objects,
                                                ),
                                            loading:
                                                () => const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                            error:
                                                (error, stackTrace) => Center(
                                                  child: Text(
                                                    '$error',
                                                    style: const TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                ref
                                    .read(filtersViewModelProvider.notifier)
                                    .applyFilters();
                              },
                              icon: const Icon(Icons.filter_alt),
                              label: const Text('Apply Filters'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.close),
                              label: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
