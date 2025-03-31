import 'package:flutter/material.dart';
import 'package:test_piquick/core/widgets/loader.dart';
import 'package:test_piquick/viewModel/filters_view_model.dart';
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
    final isLoading = false; //ref.watch(filtersViewModelProvider)?.isLoading == true;
    // final filters = ref.watch(filtersViewModelProvider.filters);

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
      body: isLoading ? const Loader()
    : Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Expanded(
                  // Ensure ListView.builder has a constrained height
                  child: ListView.builder(
                        itemCount: ref.filters.length,
                        itemBuilder: (context, index) {
                          final filter = viewModel.filters[index];
                          return ListTile(
                            title: Text(filter.type),
                            subtitle: Row(
                              children: [
                                Text('Min: '),
                                DropdownButton<int>(
                                  value: filter.minValue as int?,
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
                                    viewModel.updateFilter(
                                      filter.type,
                                      value!,
                                      filter.maxValue as int? ?? 0,
                                    );
                                  },
                                ),
                                Text(' Max: '),
                                DropdownButton<int>(
                                  value: filter.maxValue as int?,
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
                                    viewModel.updateFilter(
                                      filter.type,
                                      filter.minValue as int? ?? 0,
                                      value!,
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      )
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
      )
    );
  }
}