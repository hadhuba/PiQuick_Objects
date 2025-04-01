import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/features/shared_model/3d_object.dart';
import 'package:test_piquick/features/home/model/groups_of_objects.dart';

class HomeState {
  final AsyncValue<List<ThreeDObject>> objects;
  final AsyncValue<GroupsOfObjects>? groupedObjects; // Optional filtered objects

  

  HomeState({required this.objects, required this.groupedObjects});

  HomeState copyWith({AsyncValue<List<ThreeDObject>>? objects}) {
    return HomeState(
      objects: objects ?? this.objects,
      groupedObjects: groupedObjects,
    );
  }
}
