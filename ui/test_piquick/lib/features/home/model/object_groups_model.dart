class ObjectGroup {
  final Map<String, List<String>> groups;

  ObjectGroup({required this.groups});

  // Getter to access the entries of the groups map
  Iterable<MapEntry<String, List<String>>> get entries => groups.entries;

  // Method to convert GroupsOfObjects to JSON
  Map<String, dynamic> toJson() {
    return groups;
  }

  // Method to create a new group
  ObjectGroup createGroup({required String groupName, List<String>? objects}) {
    final objectIds = objects?.map((object) => object).toList() ?? [];
    final updatedGroups = Map<String, List<String>>.from(groups);
    updatedGroups[groupName] = objectIds; // Create the group

    return ObjectGroup(groups: updatedGroups);
  }

  // Method to add an ID to a group (create the group if it doesn't exist)
  ObjectGroup addToGroup({
    required String groupName,
    required String objectId,
  }) {
    final updatedGroups = Map<String, List<String>>.from(groups);

    // If the group doesn't exist, create it
    if (!updatedGroups.containsKey(groupName)) {
      updatedGroups[groupName] = [];
    }

    // Add the ID to the group
    updatedGroups[groupName]!.add(objectId);

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
