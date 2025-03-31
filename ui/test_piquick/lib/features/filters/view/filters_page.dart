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
  final typeController = TextEditingController();
  final maxValController = TextEditingController();
  final minValController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    typeController.dispose();
    maxValController.dispose();
    minValController.dispose();
    super.dispose();
    formKey.currentState!.validate();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        ref.watch(filtersViewModelProvider).filters.isLoading == true;

    final filtersList = ref.watch(filtersViewModelProvider).filtersList;

    // ref.listen(filtersViewModelProvider, (previous, next){
    //   //(prev, next) {
    //   next?.when(
    //     data: (data) {
    //       //TODO make homepage
    //       // Navigator.push(
    //       //   context,
    //       //   MaterialPageRoute(builder: (context) => const LoginPage()),
    //       // );
    //     },
    //     error: (error, st) {
    //       showSnackBar(context, error.toString());
    //     },
    //     loading:
    //         () {}, //why do i use watch, why i dont instead here? cant return a widget. ref is of type void.
    //   );
    // })
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
                                              .read(filtersViewModelProvider)
                                              .updateFilterCallback(
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
                                              .read(filtersViewModelProvider)
                                              .updateFilterCallback(
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
                                .read(filtersViewModelProvider)
                                .applyFiltersCallback();
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
