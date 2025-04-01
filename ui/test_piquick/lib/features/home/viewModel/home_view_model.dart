import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/features/filters/viewModel/filters_state.dart';
import 'package:test_piquick/features/filters/viewModel/filters_view_model.dart';
import 'package:test_piquick/features/home/repository/home_remote_repository.dart';
import 'package:test_piquick/features/home/viewModel/states/home_state.dart';
import 'package:test_piquick/features/shared_model/3d_object.dart';

part 'home_view_model.g.dart';

@riverpod
class HomeViewModel extends _$HomeViewModel {
  late HomeRemoteRepository _homeRemoteRepository;

  @override
  HomeState build() {
    _homeRemoteRepository =
        HomeRemoteRepository(); // we cant continously track the changes in authremoterepo
    _homeRemoteRepository = ref.watch(
      homeRemoteRepositoryProvider,
    ); // if it changes the latest comes, build runs again

    ref.listen<FiltersState>(filtersViewModelProvider, (_, next) {
      next.objectsList.whenData((objects) {
        // TODO tényleg csak akkkor hívódik meg mikor rendes adat van?
        // Frissítjük a HomeViewModel állapotát a FiltersViewModel adataival
        updateObjectsList(objectsList: objects);
      });
    });

    return HomeState(
      objects: AsyncValue.loading(), // Initialize the state with loading
      groupedObjects: AsyncValue.loading(),
    );
  }

  void updateObjectsList({required List<String> objectsList}) {
    state = state.copyWith(
      objects: AsyncValue.data(
        objectsList.map((obj) => ThreeDObject(id: obj)).toList(),
      ),
    );
  }
}
