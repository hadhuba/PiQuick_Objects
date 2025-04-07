import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_piquick/features/rendering/model/render_model.dart';

class RenderState {
  final AsyncValue<RenderModel> renderModel;
  final String? selectedGroup;

  RenderState({required this.renderModel, this.selectedGroup});

  RenderState copyWith({
    AsyncValue<RenderModel>? renderModel,
    String? selectedGroup,
  }) {
    return RenderState(
      renderModel: renderModel ?? this.renderModel,
      selectedGroup: selectedGroup ?? this.selectedGroup,
    );
  }
}
