import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/features/filters/repository/filter_remote_repository.dart';
import 'package:test_piquick/features/filters/viewModel/states/filters_state.dart';

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
      objectsList: const AsyncValue.loading(),
    );

    // Defer the call to fetchFilters() until after the state is initialized
    Future.microtask(() => initFilters());

    return initialState;
  }

  void updateFilter({required String type, num? minValue, num? maxValue}) {
    state.filters.whenData((filters) {
      final index = filters.indexWhere((filter) => filter.type == type);
      if (index != -1) {
        // Update the filter values
        filters[index].minValue = minValue;
        filters[index].maxValue = maxValue;

        // Update the state with the modified filters
        state = state.copyWith(filters: AsyncValue.data(filters));
      }
    });
  }

  Future<void> initFilters() async {
    state = state.copyWith(filters: const AsyncValue.loading());

    final response = await _filterRemoteRepository.getFilterOptions();
    state = switch (response) {
      Right(value: final r) => state.copyWith(filters: AsyncValue.data(r)),
      Left(value: final l) => state.copyWith(
        filters: AsyncValue.error(l.message, StackTrace.current),
      ),
    };
  }

  Future<void> applyFilters() async {
    state.filters.whenData((filters) async {
      state = state.copyWith(objectsList: const AsyncValue.loading());

      final response = await _filterRemoteRepository.applyFilters(
        filters: filters,
      );
      state = switch (response) {
        Right(value: final r) => state.copyWith(
          objectsList: AsyncValue.data(r),
        ),
        Left(value: final l) => state.copyWith(
          objectsList: AsyncValue.error(l.message, StackTrace.current),
        ),
      };
    });
  }
}
