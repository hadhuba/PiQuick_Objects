import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/model/3d_object.dart';
import 'package:test_piquick/model/filter.dart';
import 'package:test_piquick/model/filters_model.dart';

class FiltersState {
  final Filters filters;
  final AsyncValue<List<ThreeDObject>> objects;

  FiltersState({required this.filters, required this.objects});

  FiltersState copyWith({
    Filters? filters,
    AsyncValue<List<ThreeDObject>>? objects,
  }) {
    return FiltersState(
      filters: filters ?? this.filters,
      objects: objects ?? this.objects,
    );
  }

  List<Filter> get filtersList => filters.filters;
  bool get isLoading => objects is AsyncLoading;
}
