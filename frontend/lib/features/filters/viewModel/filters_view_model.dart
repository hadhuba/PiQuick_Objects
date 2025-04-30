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
      serverConnection: const AsyncValue.loading(),
      filters: const AsyncValue.loading(),
      objectsList: const AsyncValue.loading(),
    );

    Future.microtask(() => initFilters());

    return initialState;
  }

  Future<void> initFilters() async {
    _filterRepository.resetClient(); // Reset the client to avoid conflicts
    print('initFilters called');

    // Cancel any pending requests or reset state to avoid conflicts
    state = state.copyWith(
      filters: const AsyncValue.loading(),
      serverConnection: const AsyncValue.loading(),
      objectsList: const AsyncValue.loading(),
    );

    try {
      final filterResponse = await _filterRepository.getFilterOptions();
      switch (filterResponse) {
        case Right(value: final r):
          state = state.copyWith(
            filters: AsyncValue.data(r),
            serverConnection: const AsyncValue.data('Connected'),
          );
        case Left(value: final l):
          state = state.copyWith(
            filters: AsyncValue.error(l.message, StackTrace.current),
            serverConnection: AsyncValue.error(
              'Error connecting to server',
              StackTrace.current,
            ),
          );
          return;
      }
      ;

      final objResponse = await _filterRepository.getObjectsList();
      switch (objResponse) {
        case Right(value: final r):
          ref
              .read(filterEventBusProvider)
              .emit(AppliedFiltersEvent(newObjects: r));
          state = state.copyWith(objectsList: AsyncValue.data(r));
          break;
        case Left(value: final l):
          ref
              .read(filterEventBusProvider)
              .emit(AppliedFiltersEvent(newObjects: []));
          if (l.message.contains("TimeoutException")) {
            state = state.copyWith(
              objectsList: AsyncValue.error(
                'Error: Server took too long to respond',
                StackTrace.current,
              ),
              serverConnection: AsyncValue.error(
                'Error: Server took too long to respond',
                StackTrace.current,
              ),
            );
          } else {
            state = state.copyWith(
              objectsList: AsyncValue.error(l.message, StackTrace.current),
            );
          }
      }
    } catch (e, stackTrace) {
      // Handle unexpected errors
      state = state.copyWith(
        serverConnection: AsyncValue.error('Unexpected error: $e', stackTrace),
        filters: AsyncValue.error('Unexpected error: $e', stackTrace),
        objectsList: AsyncValue.error('Unexpected error: $e', stackTrace),
      );
    }
  }

  String? updateFilter({
    required String type,
    String? minValue,
    String? maxValue,
  }) {
    // Validate that minValue and maxValue are numeric or null
    final num? parsedMinValue =
        minValue == null || minValue.isEmpty ? null : num.tryParse(minValue);
    final num? parsedMaxValue =
        maxValue == null || maxValue.isEmpty ? null : num.tryParse(maxValue);

    if (minValue != null && parsedMinValue == null) {
      return 'Minimum value must be a valid number';
    }
    if (maxValue != null && parsedMaxValue == null) {
      return 'Maximum value must be a valid number';
    }

    // Validate that minValue is not greater than maxValue
    if (parsedMinValue != null &&
        parsedMaxValue != null &&
        parsedMinValue > parsedMaxValue) {
      return 'Minimum value cannot be greater than maximum value';
    }

    // Update the filter in the state
    state.filters.whenData((filters) {
      final index = filters.indexWhere((filter) => filter.type == type);
      if (index != -1) {
        // Update the filter values
        filters[index].minValue = parsedMinValue;
        filters[index].maxValue = parsedMaxValue;

        // Update the state with the modified filters
        state = state.copyWith(filters: AsyncValue.data(filters));
      }
    });

    return null; // Return null if no validation errors
  }

  Future<void> applyFilters() async {
    state.filters.whenData((filters) async {
      state = state.copyWith(objectsList: const AsyncValue.loading());

      final response = await _filterRepository.applyFilters(filters: filters);
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
            if (l.message.contains("TimeoutException")) {
              print('TimeoutException occurred');
              state = state.copyWith(
                objectsList: AsyncValue.error(
                  'Error: Server took too long to respond',
                  StackTrace.current,
                ),
                serverConnection: AsyncValue.error(
                  'Error: Server took too long to respond',
                  StackTrace.current,
                ),
              );
            } else {
              state = state.copyWith(
                objectsList: AsyncValue.error(l.message, StackTrace.current),
              );
            }
          }
      }
    });
  }
}
