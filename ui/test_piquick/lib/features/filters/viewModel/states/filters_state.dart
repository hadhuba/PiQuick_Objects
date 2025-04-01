import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/features/filters/model/filter.dart';
// import 'package:test_piquick/features/filters/model/filters_model.dart';

class FiltersState {
  final AsyncValue<List<Filter>> filters;
  final AsyncValue<List<String>> objectsList;

  FiltersState({required this.filters, required this.objectsList});

  FiltersState copyWith({
    AsyncValue<List<Filter>>? filters,
    AsyncValue<List<String>>? objectsList,
    Future<void> Function()? applyFiltersCallback,
    void Function({required String type, num? minValue, num? maxValue})?
    updateFilterCallback,
  }) {
    return FiltersState(
      filters: filters ?? this.filters,
      objectsList: objectsList ?? this.objectsList,
    );
  }

  // Getter to extract the filters list from AsyncValue<Filters>
  List<Filter>? get filtersList {
    return filters.when(
      data:
          (filters) =>
              filters, // Return the list of filters if data is available
      loading: () => null, // Return null if loading
      error: (error, stackTrace) => null, // Return null if there's an error
    );
  }
}

// class FiltersState {
//   final AsyncValue<Filters> filters;
//   final AsyncValue<List<ThreeDObject>> objects;
//   final Future<void> Function()
//   applyFiltersCallback; // Callback to call ViewModel function
//   final void Function({required String type, num? minValue, num? maxValue})
//   updateFilterCallback; // Callback to call ViewModel function
//   FiltersState({
//     required this.filters,
//     required this.objects,
//     required this.applyFiltersCallback,
//     required this.updateFilterCallback,
//   });

//   FiltersState copyWith({
//     AsyncValue<Filters>? filters,
//     AsyncValue<List<ThreeDObject>>? objects,
//     Future<void> Function()? applyFiltersCallback,
//     void Function({required String type, num? minValue, num? maxValue})?
//     updateFilterCallback,
//   }) {
//     return FiltersState(
//       filters: filters ?? this.filters,
//       objects: objects ?? this.objects,
//       applyFiltersCallback: applyFiltersCallback ?? this.applyFiltersCallback,
//       updateFilterCallback: updateFilterCallback ?? this.updateFilterCallback,
//     );
//   }

//   // Getter to extract the filters list from AsyncValue<Filters>
//   List<Filter>? get filtersList {
//     return filters.when(
//       data:
//           (filters) =>
//               filters
//                   .filters, // Return the list of filters if data is available
//       loading: () => null, // Return null if loading
//       error: (error, stackTrace) => null, // Return null if there's an error
//     );
//   }
// }
