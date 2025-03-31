import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/model/filters_model.dart';
import 'package:test_piquick/repository/filter_remote_repository.dart';
import 'package:test_piquick/viewModel/filters_state.dart';

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
    return FiltersState(
      filters: Filters(filters: []),
      objects: const AsyncValue.loading(),
    );
  }

  void updateFilter(String type, num minValue, num maxValue) {
    final index = state.filtersList.indexWhere((filter) => filter.type == type);
    if (index != -1) {
      state.filtersList[index].minValue = minValue;
      state.filtersList[index].maxValue = maxValue;
    }
  }

  Future<void> applyFilters() async {
    state = state.copyWith(objects: const AsyncValue.loading());

    final response = await _filterRemoteRepository.applyFilters(
      filters: state.filters,
    );
    final val = switch (response) {
      Right(value: final r) =>
        state = state.copyWith(objects: AsyncValue.data(r)),
      Left(value: final l) =>
        state = state.copyWith(
          objects: AsyncValue.error(l.message, StackTrace.current),
        ),
    };
    print(val);
  }
}
