import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_piquick/features/picker/model/object_groups_model.dart';
import 'package:test_piquick/features/rendering/model/render_model.dart';

class RenderState {
  final AsyncValue<RenderModel> renderModel;
  final AsyncValue<ObjectGroups> groupedObjects;
  final String? selectedGroup;

  RenderState({
    required this.renderModel,
    required this.groupedObjects,
    this.selectedGroup,
  });

  RenderState copyWith({
    AsyncValue<RenderModel>? renderModel,
    AsyncValue<ObjectGroups>? groupedObjects,
    String? selectedGroup,
  }) {
    return RenderState(
      renderModel: renderModel ?? this.renderModel,
      groupedObjects: groupedObjects ?? this.groupedObjects,
      selectedGroup: selectedGroup ?? this.selectedGroup,
    );
  }
}
