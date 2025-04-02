import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/features/home/model/object_groups_model.dart';
import 'package:test_piquick/features/home/viewModel/states/viewer_3d_state.dart';

class HomeState {
  final AsyncValue<List<String>> objects;
  final AsyncValue<ObjectGroup> groupedObjects; // Optional filtered objects
  final AsyncValue<Viewer3DState> viewer3DState;
  // string currentGroup


  HomeState({
    required this.objects,
    required this.groupedObjects,
    required this.viewer3DState,
  });

  HomeState copyWith({
    AsyncValue<List<String>>? objects,
    AsyncValue<ObjectGroup>? groupedObjects,
    AsyncValue<Viewer3DState>? viewer3DState,
  }) {
    return HomeState(
      objects: objects ?? this.objects,
      groupedObjects: groupedObjects ?? this.groupedObjects,
      viewer3DState: viewer3DState ?? this.viewer3DState,
    );
  }
}
