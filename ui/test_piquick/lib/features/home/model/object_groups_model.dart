import 'package:test_piquick/features/shared_model/3d_object.dart';

class ObjectGroup {
  final Map<String, List<String>> groups;

  ObjectGroup({required this.groups});

  // Getter to access the entries of the groups map
  Iterable<MapEntry<String, List<String>>> get entries => groups.entries;

  // Method to convert GroupsOfObjects to JSON
  Map<String, dynamic> toJson() {
    return groups;
  }

  // Method to modify or add a group
  ObjectGroup modifyOrAddGroup({
    required String groupName,
    List<ThreeDObject>? objects,
  }) {
    final objectIds = objects?.map((object) => object.id).toList() ?? [];

    final updatedGroups = Map<String, List<String>>.from(groups);
    updatedGroups[groupName] = objectIds; // Add or overwrite the group

    return ObjectGroup(groups: updatedGroups);
  }

  // Method to remove an element from a group
  ObjectGroup removeFromGroup({
    required String groupName,
    required String objectId,
  }) {
    final updatedGroups = Map<String, List<String>>.from(groups);

    if (updatedGroups.containsKey(groupName)) {
      updatedGroups[groupName]!.remove(objectId);
      // Remove the group if it becomes empty
      // if (updatedGroups[groupName]!.isEmpty) {
      //   updatedGroups.remove(groupName);
      // }
    }

    return ObjectGroup(groups: updatedGroups);
  }

  // Method to remove an entire group
  ObjectGroup removeGroup(String groupName) {
    final updatedGroups = Map<String, List<String>>.from(groups);
    updatedGroups.remove(groupName);

    return ObjectGroup(groups: updatedGroups);
  }
}
