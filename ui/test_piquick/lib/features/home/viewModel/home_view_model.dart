import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/features/filters/viewModel/states/filters_state.dart';
import 'package:test_piquick/features/filters/viewModel/filters_view_model.dart';
import 'package:test_piquick/features/home/repository/home_remote_repository.dart';
import 'package:test_piquick/features/home/viewModel/states/home_state.dart';
import 'package:test_piquick/features/home/viewModel/states/viewer_3d_state.dart';
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
      viewer3DState: AsyncValue.data(
        Viewer3DState(
          currentObj: 'assets/Astronaut.glb',
          // 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
          currentAnimation: null,
          currentTexture: null,
        ),
      ),
    );
  }

  Future<void> updateObj(String newObj) async {
    // Set the state to loading while the object is being fetched
    state = state.copyWith(viewer3DState: const AsyncValue.loading());

    // Fetch the object from the remote repository
    final response = await _homeRemoteRepository.fetchThisObject(
      newObj: newObj,
    );

    // Handle the response using a switch expression
    state = switch (response) {
      Right(value: final r) => state.copyWith(
        viewer3DState: AsyncValue.data(
          Viewer3DState(
            currentObj: newObj, //TODO currentObj to be a http link
            currentAnimation: null,
            currentTexture: null,
          ),
        ),
      ),
      Left(value: final l) => state.copyWith(
        viewer3DState: AsyncValue.error(l.message, StackTrace.current),
      ),
    };
  }

  //state update

  void updateAnimation(String? newAnimation) {
    state.viewer3DState.whenData(
      (data) =>
          (state = state.copyWith(
            viewer3DState: AsyncValue.data(
              data.copyWith(
                currentObj: state.viewer3DState.value?.currentObj,
                currentAnimation: newAnimation,
                currentTexture: state.viewer3DState.value?.currentTexture,
              ),
            ),
          )),
    );
    //state update
  }

  void updateTexture(String? newTexture) {
    state.viewer3DState.whenData(
      (data) =>
          (state = state.copyWith(
            viewer3DState: AsyncValue.data(
              data.copyWith(
                currentObj: state.viewer3DState.value?.currentObj,
                currentAnimation: state.viewer3DState.value?.currentAnimation,
                currentTexture: newTexture,
              ),
            ),
          )),
    );
  }

  void addToGroup({required String groupname}) {
    state.groupedObjects.whenData(
      (groups) =>
          (state = state.copyWith(
            groupedObjects: AsyncValue.data(
              groups.modifyOrAddGroup(groupName: groupname),
            ),
          )),
    );
  }

  void newGroup({required String groupname}) {
    state.groupedObjects.whenData(
      (groups) =>
          (state = state.copyWith(
            groupedObjects: AsyncValue.data(
              groups.modifyOrAddGroup(groupName: groupname),
            ),
          )),
    );
  }

  void removeFromGroup({required String groupname, required String objectId}) {
    state.groupedObjects.whenData(
      (groups) =>
          (state = state.copyWith(
            groupedObjects: AsyncValue.data(
              groups.removeFromGroup(groupName: groupname, objectId: objectId),
            ),
          )),
    );
  }

  void updateObjectsList({required List<String> objectsList}) {
    state = state.copyWith(
      objects: AsyncValue.data(
        objectsList.map((obj) => ThreeDObject(id: obj)).toList(),
      ),
    );
    print(
      'Objects updated Im at home view model bottom: ${state.objects.value}',
    );
  }
}
