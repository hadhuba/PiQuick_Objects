import 'package:test_piquick/features/picker/model/object_groups_model.dart';
import 'package:test_piquick/features/rendering/model/group.dart';
import 'package:test_piquick/features/rendering/model/render_settings.dart';

class RenderModel {
  final List<Group> _groups;

  RenderModel({required List<Group> groups}) : _groups = groups;

  Group? get(String name) {
    try {
      return _groups.firstWhere((group) => group.name == name);
    } catch (_) {
      return null;
    }
  }

  List<String> getAllNames() {
    return _groups.map((group) => group.name).toList();
  }

  factory RenderModel.empty() {
    return RenderModel(groups: []);
  }

  factory RenderModel.fromObjectGroupsAndSettings({
    required ObjectGroups objectGroups,
    required RenderSettings renderSettings,
  }) {
    final List<Group> groups = [];

    final Set<String> groupNames = objectGroups.groups.keys.toSet();
    for (final groupName in groupNames) {
      final objectIds = objectGroups.groups[groupName] ?? [];

      groups.add(
        Group(
          name: groupName,
          object_ids: objectIds,
          settings:
              renderSettings, // Use the same renderSettings for all groups
        ),
      );
    }
    return RenderModel(groups: groups);
  }

  RenderModel setGroupSettings(String groupName, RenderSettings settings) {
    final List<Group> updatedGroups = List.from(_groups);

    // Find existing group with the given name
    final existingIndex = updatedGroups.indexWhere(
      (group) => group.name == groupName,
    );

    if (existingIndex >= 0) {
      // Update existing group
      final existingGroup = updatedGroups[existingIndex];
      updatedGroups[existingIndex] = Group(
        name: existingGroup.name,
        object_ids: existingGroup.object_ids,
        settings: settings,
      );
    } else {
      // Create a new group if one doesn't exist
      updatedGroups.add(
        Group(name: groupName, object_ids: [], settings: settings),
      );
    }
    return RenderModel(groups: updatedGroups);
  }

  /// Convert to a JSON map that can be sent to the server
  List<Map<String, dynamic>> toJson() {
    return _groups
        .map(
          (group) => {
            'name': group.name,
            'object_ids': group.object_ids,
            'settings': group.settings.toMap(),
          },
        )
        .toList();
  }
}
