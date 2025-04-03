import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/features/picker/model/object_groups_model.dart';
import 'package:test_piquick/features/picker/viewModel/states/viewer_3d_state.dart';

class PickerState {
  final AsyncValue<List<String>> objects;
  final AsyncValue<ObjectGroups> groupedObjects; // Optional filtered objects
  final AsyncValue<Viewer3DState> viewer3DState;
  final String? selectedGroup;
  // string currentGroup

  PickerState({
    required this.objects,
    required this.groupedObjects,
    required this.viewer3DState,
    this.selectedGroup,
  });

  PickerState copyWith({
    AsyncValue<List<String>>? objects,
    AsyncValue<ObjectGroups>? groupedObjects,
    AsyncValue<Viewer3DState>? viewer3DState,
    String? selectedGroup,
    String? notification,
  }) {
    return PickerState(
      objects: objects ?? this.objects,
      groupedObjects: groupedObjects ?? this.groupedObjects,
      viewer3DState: viewer3DState ?? this.viewer3DState,
      selectedGroup: selectedGroup ?? this.selectedGroup,
    );
  }
}
