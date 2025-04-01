import 'package:test_piquick/features/shared_model/3d_object.dart';

class GroupsOfObjects {
  final Map<String, List<String>> groups;

  GroupsOfObjects({required this.groups});

  // Method to convert GroupsOfObjects to JSON
  Map<String, dynamic> toJson() {
    return groups;
  }

  // Method to modify or add a group
  GroupsOfObjects modifyOrAddGroup({
    required String groupName,
    required List<ThreeDObject> objects,
  }) {
    final objectIds = objects.map((object) => object.id).toList();

    final updatedGroups = Map<String, List<String>>.from(groups);
    updatedGroups[groupName] = objectIds; // Add or overwrite the group

    return GroupsOfObjects(groups: updatedGroups);
  }
}
