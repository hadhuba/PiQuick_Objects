import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_piquick/features/rendering/model/render_model.dart';
import 'dart:io';

class RenderState {
  final AsyncValue<RenderModel> renderModel;
  final String? selectedGroup;
  final AsyncValue<File?> downloadedFile;
  final String? downloadStatus;

  RenderState({
    required this.renderModel,
    this.selectedGroup,
    this.downloadedFile = const AsyncValue.data(null),
    this.downloadStatus,
  });

  RenderState copyWith({
    AsyncValue<RenderModel>? renderModel,
    String? selectedGroup,
    AsyncValue<File?>? downloadedFile,
    String? downloadStatus,
  }) {
    return RenderState(
      renderModel: renderModel ?? this.renderModel,
      selectedGroup: selectedGroup ?? this.selectedGroup,
      downloadedFile: downloadedFile ?? this.downloadedFile,
      downloadStatus: downloadStatus ?? this.downloadStatus,
    );
  }
}
