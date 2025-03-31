import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/features/filters/model/3d_object.dart';
import 'package:test_piquick/features/filters/model/filter.dart';
import 'package:test_piquick/features/filters/model/filters_model.dart';

class FiltersState {
  final Filters filters;
  final AsyncValue<List<ThreeDObject>> objects;
  final Future<void> Function()  applyFiltersCallback; // Callback to call ViewModel function
  final void Function({required String type, num? minValue, num? maxValue})  updateFilterCallback; // Callback to call ViewModel function
  FiltersState({
    required this.filters,
    required this.objects,
    required this.applyFiltersCallback,
    required this.updateFilterCallback,
  });

  FiltersState copyWith({
    Filters? filters,
    AsyncValue<List<ThreeDObject>>? objects,
    Future<void> Function()? applyFiltersCallback,
    void Function({required String type, num? minValue, num? maxValue})?
    updateFilterCallback,
  }) {
    return FiltersState(
      filters: filters ?? this.filters,
      objects: objects ?? this.objects,
      applyFiltersCallback: applyFiltersCallback ?? this.applyFiltersCallback,
      updateFilterCallback: updateFilterCallback ?? this.updateFilterCallback,
    );
  }

  List<Filter> get filtersList => filters.filters;
  bool get isLoading => objects is AsyncLoading;
}
