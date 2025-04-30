import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:frontend/features/picker/model/object_groups_model.dart';
import 'package:frontend/features/picker/model/picker_events.dart';
import 'package:frontend/features/picker/model/repository/picker_repository.dart';
import 'package:frontend/features/picker/viewModel/picker_event_bus.dart';
import 'package:frontend/features/picker/viewModel/states/picker_state.dart';
import 'package:frontend/features/picker/viewModel/states/viewer_3d_state.dart';
import 'package:frontend/features/filters/model/filter_events.dart';
import 'package:frontend/features/filters/viewModel/filter_event_bus.dart';
part 'auto_generated/picker_view_model.g.dart';

/// Manages the object picker functionality including group management, 3D object viewing,
/// and handling events related to object selection and filtering.
@riverpod
class PickerViewModel extends _$PickerViewModel {
  late PickerRepository _pickerRepository;
  StreamSubscription? _eventSubscription;

  @override
  PickerState build() {
    _pickerRepository = ref.watch(pickerRepositoryProvider);

    final initialState = PickerState(
      objects: AsyncValue.loading(),
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
        handleFiltersAppliedEvent(event);
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
    state = state.copyWith(viewer3DState: const AsyncValue.loading());

    final response = _pickerRepository.hostThisObject(newObj: newObj);

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
      return;
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
    ref
        .read(pickerEventBusProvider)
        .emit(GroupAlteredEvent(newObjectGroups: state.groupedObjects.value!));
  }

  String? newGroup({required String groupname}) {
    if (groupname.trim().isEmpty) {
      return "Group name cannot be empty";
    }

    String? errorMessage;
    state.groupedObjects.whenData((groups) {
      if (groups.groups.containsKey(groupname)) {
        errorMessage = "A group with name '$groupname' already exists";
      } else {
        state = state.copyWith(
          groupedObjects: AsyncValue.data(
            groups.createGroup(groupName: groupname),
          ),
        );
        ref
            .read(pickerEventBusProvider)
            .emit(
              GroupAlteredEvent(newObjectGroups: state.groupedObjects.value!),
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
    ref
        .read(pickerEventBusProvider)
        .emit(GroupAlteredEvent(newObjectGroups: state.groupedObjects.value!));
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
    ref
        .read(pickerEventBusProvider)
        .emit(GroupAlteredEvent(newObjectGroups: state.groupedObjects.value!));
  }

  void updateObjectsList({required List<String> objectsList}) {
    state = state.copyWith(objects: AsyncValue.data(objectsList));
  }

  void handleFiltersAppliedEvent(AppliedFiltersEvent event) {
    updateObjectsList(objectsList: event.newObjects ?? []);
  }
}
