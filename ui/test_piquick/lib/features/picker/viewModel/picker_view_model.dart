import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/features/picker/model/object_groups_model.dart';
import 'package:test_piquick/features/picker/model/repository/picker_remote_repository.dart';
import 'package:test_piquick/features/picker/viewModel/states/picker_state.dart';
import 'package:test_piquick/features/picker/viewModel/states/viewer_3d_state.dart';
import 'package:test_piquick/features/filters/model/filter_events.dart';
import 'package:test_piquick/features/filters/viewModel/filter_event_bus.dart';
part 'picker_view_model.g.dart';

@riverpod
class PickerViewModel extends _$PickerViewModel {
  late PickerRemoteRepository _pickerRemoteRepository;
  StreamSubscription? _eventSubscription;

  @override
  PickerState build() {
    _pickerRemoteRepository =
        PickerRemoteRepository(); // we cant continously track the changes in authremoterepo
    _pickerRemoteRepository = ref.watch(
      pickerRemoteRepositoryProvider,
    ); // if it changes the latest comes, build runs again


    final initialState = PickerState(
      objects: AsyncValue.loading(), // Initialize the state with loading
      groupedObjects: AsyncValue.loading(),
      viewer3DState: AsyncValue.data(
        Viewer3DState(currentObj: 'assets/Astronaut.glb', currentTexture: null),
      ),
    );

    Future.microtask(() => initHome());

    _setupEventListeners();
    ref.onDispose(() {
      _eventSubscription?.cancel();
    });

    return initialState;
  }

  void _setupEventListeners() {
    final bus = ref.read(filterEventBusProvider);

    _eventSubscription = bus.events.listen((event) {
      if (event is AppliedFiltersEvent) {
        _handleFiltersAppliedEvent(event);
      }
    });
  }

  Future<void> initHome() async {
    state = state.copyWith(
      objects: AsyncValue.data([]),
      groupedObjects: AsyncValue.data(ObjectGroups(groups: {})),
    );
  }

  void updateObj(String newObj) {
    // Set the state to loading while the object is being fetched
    state = state.copyWith(viewer3DState: const AsyncValue.loading());

    // Fetch the object from the remote repository
    final response = _pickerRemoteRepository.hostThisObject(newObj: newObj);

    // Handle the response using a switch expression
    state = switch (response) {
      Right(value: final newObjUrl) => state.copyWith(
        viewer3DState: AsyncValue.data(
          Viewer3DState(currentObj: newObjUrl, currentTexture: null),
        ),
      ),
      Left(value: final l) => state.copyWith(
        viewer3DState: AsyncValue.error(l.message, StackTrace.current),
      ),
    };
  }

  void updateTexture(String? newTexture) {
    state.viewer3DState.whenData(
      (data) =>
          (state = state.copyWith(
            viewer3DState: AsyncValue.data(
              data.copyWith(
                currentObj: state.viewer3DState.value?.currentObj,
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

  String? newGroup({required String groupname}) {
    if (groupname.trim().isEmpty) {
      return "Group name cannot be empty";
    }

    // Check if the group already exists
    String? errorMessage;
    state.groupedObjects.whenData((groups) {
      if (groups.groups.containsKey(groupname)) {
        errorMessage = "A group with name '$groupname' already exists";
      } else {
        // Group doesn't exist, create it
        state = state.copyWith(
          groupedObjects: AsyncValue.data(
            groups.createGroup(groupName: groupname),
          ),
        );
      }
    });

    return errorMessage;
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
  }

  void _handleFiltersAppliedEvent(AppliedFiltersEvent event) {
    updateObjectsList(objectsList: event.newObjects ?? []);
  }
}
