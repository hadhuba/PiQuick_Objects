// A filters modul különböző eseményeinek definíciói
import 'package:frontend/features/picker/model/object_groups_model.dart';

abstract class PickerEvent {
  const PickerEvent();
}

// A beállítások mentésének eseménye
class GroupAlteredEvent extends PickerEvent {
  final ObjectGroups newObjectGroups; // A beállítások objektum

  const GroupAlteredEvent({required this.newObjectGroups});
}
