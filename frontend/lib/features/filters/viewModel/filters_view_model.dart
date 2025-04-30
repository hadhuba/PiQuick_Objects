import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:frontend/features/filters/model/filter_events.dart';
import 'package:frontend/features/filters/model/repository/filter_repository.dart';
import 'package:frontend/features/filters/viewModel/filter_event_bus.dart';
import 'package:frontend/features/filters/viewModel/states/filters_state.dart';

part 'auto_generated/filters_view_model.g.dart';

@riverpod
class FiltersViewModel extends _$FiltersViewModel {
  late FilterRepository _filterRepository;

  @override
  FiltersState build() {
    _filterRepository = ref.watch(filterRepositoryProvider);

    final initialState = FiltersState(
      filters: const AsyncValue.loading(),
      objectsList: const AsyncValue.loading(),
    );

    Future.microtask(() => initFilters());

    return initialState;
  }

  Future<void> initFilters() async {
    state = state.copyWith(filters: const AsyncValue.loading());

    final filterResponse = await _filterRepository.getFilterOptions();
    state = switch (filterResponse) {
      Right(value: final r) => state.copyWith(filters: AsyncValue.data(r)),
      Left(value: final l) => state.copyWith(
        filters: AsyncValue.error(l.message, StackTrace.current),
      ),
    };

    final objResponse = await _filterRepository.getObjectsList();

    switch (objResponse) {
      case Right(value: final r):
        {
          ref
              .read(filterEventBusProvider)
              .emit(AppliedFiltersEvent(newObjects: r));
          state = state.copyWith(objectsList: AsyncValue.data(r));
        }
      case Left(value: final l):
        {
          ref
              .read(filterEventBusProvider)
              .emit(AppliedFiltersEvent(newObjects: []));
          state = state.copyWith(
            objectsList: AsyncValue.error(l.message, StackTrace.current),
          );
        }
    }
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

  Future<void> applyFilters() async {
    state.filters.whenData((filters) async {
      state = state.copyWith(objectsList: const AsyncValue.loading());

      final response = await _filterRepository.applyFilters(
        filters: filters,
      );
      switch (response) {
        case Right(value: final r):
          {
            ref
                .read(filterEventBusProvider)
                .emit(AppliedFiltersEvent(newObjects: r));
            state = state.copyWith(objectsList: AsyncValue.data(r));
          }
        case Left(value: final l):
          {
            ref
                .read(filterEventBusProvider)
                .emit(AppliedFiltersEvent(newObjects: []));
            state = state.copyWith(
              objectsList: AsyncValue.error(l.message, StackTrace.current),
            );
          }
      }
    });
  }
}
