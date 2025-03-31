import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/features/filters/model/filters_model.dart';
import 'package:test_piquick/features/filters/repository/filter_remote_repository.dart';
import 'package:test_piquick/features/filters/viewModel/filters_state.dart';

part 'filters_view_model.g.dart';

@riverpod
class FiltersViewModel extends _$FiltersViewModel {
  late FilterRemoteRepository _filterRemoteRepository;

  @override
  FiltersState build() {
    _filterRemoteRepository =
        FilterRemoteRepository(); // we cant continously track the changes in authremoterepo
    _filterRemoteRepository = ref.watch(
      filterRemoteRepositoryProvider,
    ); // if it changes the latest comes, build runs again

    // Initialize the state
    final initialState = FiltersState(
      filters: const AsyncValue.loading(),
      objects: const AsyncValue.loading(),
      applyFiltersCallback: applyFilters,
      updateFilterCallback: updateFilter,
    );

    // Defer the call to fetchFilters() until after the state is initialized
    Future.microtask(() => fetchFilters());

    return initialState;
  }

  void updateFilter({required String type, num? minValue, num? maxValue}) {
    state.filters.whenData((filters) {
      final index = filters.filters.indexWhere((filter) => filter.type == type);
      if (index != -1) {
        // Update the filter values
        filters.filters[index].minValue = minValue;
        filters.filters[index].maxValue = maxValue;

        // Update the state with the modified filters
        state = state.copyWith(filters: AsyncValue.data(filters));
      }
      print(state.filters);
    });
  }

  //   void updateFilter({required String type, num? minValue, num? maxValue}) {
  //   state.filters.whenData((filters) {
  //     final index = filters.filters.indexWhere((filter) => filter.type == type);
  //     if (index != -1) {
  //       filters.filters[index].minValue = minValue;
  //       filters.filters[index].maxValue = maxValue;

  //       state = state.copyWith(filters: AsyncValue.data(filters));
  //     }
  //   });
  // }

  Future<void> fetchFilters() async {
    state = state.copyWith(filters: const AsyncValue.loading());

    final response = await _filterRemoteRepository.getFilterOptions();
    final val = switch (response) {
      Right(value: final r) =>
        state = state.copyWith(filters: AsyncValue.data(r)),
      Left(value: final l) =>
        state = state.copyWith(
          filters: AsyncValue.error(l.message, StackTrace.current),
        ),
    };
    print(val.filters);
  }

  Future<void> applyFilters() async {
    state.filters.whenData((filters) async {
      state = state.copyWith(objects: const AsyncValue.loading());

      final response = await _filterRemoteRepository.applyFilters(
        filters: filters,
      );
      final val = switch (response) {
        Right(value: final r) =>
          state = state.copyWith(objects: AsyncValue.data(r)),
        Left(value: final l) =>
          state = state.copyWith(
            objects: AsyncValue.error(l.message, StackTrace.current),
          ),
      };
      print(val.objects);
    });
  }
}
