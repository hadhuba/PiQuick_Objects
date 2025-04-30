/// Manages collections of object groups with operations for creating, modifying, and removing groups.
/// Each group contains a list of object IDs and can be manipulated through various methods.
class ObjectGroups {
  final Map<String, List<String>> groups;

  ObjectGroups({required this.groups});

  Iterable<MapEntry<String, List<String>>> get entries => groups.entries;

  Map<String, dynamic> toJson() {
    return groups;
  }

  ObjectGroups createGroup({required String groupName, List<String>? objects}) {
    final objectIds = objects?.map((object) => object).toList() ?? [];
    final updatedGroups = Map<String, List<String>>.from(groups);
    updatedGroups[groupName] = objectIds;

    return ObjectGroups(groups: updatedGroups);
  }

  ObjectGroups addToGroup({
    required String groupName,
    required String objectId,
  }) {
    final updatedGroups = Map<String, List<String>>.from(groups);

    if (!updatedGroups.containsKey(groupName)) {
      updatedGroups[groupName] = [];
    }

    updatedGroups[groupName]!.add(objectId);

    return ObjectGroups(groups: updatedGroups);
  }

  ObjectGroups removeFromGroup({
    required String groupName,
    required String objectId,
  }) {
    final updatedGroups = Map<String, List<String>>.from(groups);

    if (updatedGroups.containsKey(groupName)) {
      updatedGroups[groupName]!.remove(objectId);
    }

    return ObjectGroups(groups: updatedGroups);
  }

  ObjectGroups removeGroup(String groupName) {
    final updatedGroups = Map<String, List<String>>.from(groups);
    updatedGroups.remove(groupName);

    return ObjectGroups(groups: updatedGroups);
  }
}
