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

  // Future<void> applyFilters() async {
  //   state.objects = const AsyncValue.loading();

  //   final response = await _filterRemoteRepository.applyFilters(
  //     filters: _filters,
  //   );

  //   final val = switch (response) {
  //     Right(value: final r) => state = AsyncValue.data(r),
  //     Left(value: final l) =>
  //       state = AsyncValue.error(l.message, StackTrace.current),
  //   };
  //   print(val);
  // }
  Future<void> applyFilters() async {
  // Állapot frissítése betöltési állapotra
  state = state.copyWith(objects: const AsyncValue.loading());

  try {
    // Szerverhívás a szűrők alkalmazásához
    final response = await _filterRemoteRepository.applyFilters(
      filters: state.filters,
    );

    // Sikeres válasz esetén az állapot frissítése az adatokkal
    state = state.copyWith(objects: AsyncValue.data(response));
  } catch (error, stackTrace) {
    // Hiba esetén az állapot frissítése hibaüzenettel
    state = state.copyWith(objects: AsyncValue.error(error, stackTrace));
  }
}
}
