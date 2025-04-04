import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/features/filters/viewModel/states/filters_state.dart';
import 'package:test_piquick/features/filters/viewModel/filters_view_model.dart';
import 'package:test_piquick/features/picker/repository/picker_remote_repository.dart';
import 'package:test_piquick/features/picker/viewModel/states/picker_state.dart';
import 'package:test_piquick/features/picker/viewModel/states/viewer_3d_state.dart';

part 'picker_view_model.g.dart';

@riverpod
class PickerViewModel extends _$PickerViewModel {
  late PickerRemoteRepository _pickerRemoteRepository;

  @override
  PickerState build() {
    _pickerRemoteRepository =
        PickerRemoteRepository(); // we cant continously track the changes in authremoterepo
    _pickerRemoteRepository = ref.watch(
      pickerRemoteRepositoryProvider,
    ); // if it changes the latest comes, build runs again

    ref.listen<FiltersState>(filtersViewModelProvider, (_, next) {
      next.objectsList.whenData((objects) {
        // TODO tényleg csak akkkor hívódik meg mikor rendes adat van?
        // Frissítjük a HomeViewModel állapotát a FiltersViewModel adataival
        updateObjectsList(objectsList: objects);
      });
    });

    final initialState = PickerState(
      objects: AsyncValue.loading(), // Initialize the state with loading
      groupedObjects: AsyncValue.loading(),
      viewer3DState: AsyncValue.data(
        Viewer3DState(
          currentObj: 'assets/Astronaut.glb',
          currentAnimation: null,
          currentTexture: null,
        ),
      ),
    );

    Future.microtask(() => initHome());

    return initialState;
  }

  Future<void> initHome() async {
    // Fetch the initial list of objects from the remote repository
    final objectsResponse = await _pickerRemoteRepository.fetchObjects();
    final groupResponse = _pickerRemoteRepository.fetchGroupedObjects();

    // Handle the response using a switch expression
    state = switch (objectsResponse) {
      Right(value: final objectsList) => state.copyWith(
        objects: objectsList,
        groupedObjects: AsyncValue.data(groupResponse),
      ),
      Left(value: final l) => state.copyWith(
        objects: AsyncValue.error(l.message, StackTrace.current),
        groupedObjects: AsyncValue.data(groupResponse),
      ),
    };
  }

  void updateObj(String newObj) {
    print('pressed id: ${newObj}');

    // Set the state to loading while the object is being fetched
    state = state.copyWith(viewer3DState: const AsyncValue.loading());

    // Fetch the object from the remote repository
    final response = _pickerRemoteRepository.hostThisObject(newObj: newObj);

    // Handle the response using a switch expression
    state = switch (response) {
      Right(value: final newObjUrl) => state.copyWith(
        viewer3DState: AsyncValue.data(
          Viewer3DState(
            currentObj: newObjUrl,
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

  void selectGroup(String groupName) {
    state.groupedObjects.whenData(
      (groups) => (state = state.copyWith(selectedGroup: groupName)),
    );
  }

  void addToGroup(String objectId) {
    if (state.selectedGroup == null) {
      // setNotification('Please select a group first');
      return; // No group selected, do nothing
    }

    state.groupedObjects.whenData(
      (groups) =>
          (state = state.copyWith(
            groupedObjects: AsyncValue.data(
              groups.addToGroup(
                groupName: state.selectedGroup!,
                objectId: objectId,
              ),
            ),
          )),
    );
  }

  void newGroup({required String groupname}) {
    state.groupedObjects.whenData(
      (groups) =>
          (state = state.copyWith(
            groupedObjects: AsyncValue.data(
              groups.createGroup(groupName: groupname),
            ),
          )),
    );
  }

  void removeGroup({required String groupname}) {
    state.groupedObjects.whenData(
      (groups) =>
          (state = state.copyWith(
            groupedObjects: AsyncValue.data(groups.removeGroup(groupname)),
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
    state = state.copyWith(objects: AsyncValue.data(objectsList));
    print(
      'Objects updated Im at home view model bottom: ${state.objects.value}',
    );
  }

  // void setNotification(String message) {
  //   state = state.copyWith(notification: message);
  // }

  // void clearNotification() {
  //   state = state.copyWith(notification: null);
  // }
}
