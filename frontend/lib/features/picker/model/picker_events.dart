import 'package:frontend/features/picker/model/object_groups_model.dart';

/// Base class for all picker-related events in the application.
abstract class PickerEvent {
  const PickerEvent();
}

/// Event triggered when an object group is modified, containing the updated object groups.
class GroupAlteredEvent extends PickerEvent {
  final ObjectGroups newObjectGroups;

  const GroupAlteredEvent({required this.newObjectGroups});
}
