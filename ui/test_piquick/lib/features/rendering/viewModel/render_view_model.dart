import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/features/picker/model/object_groups_model.dart';
import 'package:test_piquick/features/picker/viewModel/states/picker_state.dart';
import 'package:test_piquick/features/picker/viewModel/picker_view_model.dart';
import 'package:test_piquick/features/rendering/model/render_model.dart';
import 'package:test_piquick/features/rendering/model/render_settings.dart';
import 'package:test_piquick/features/rendering/repository/render_remote_repository.dart';
import 'package:test_piquick/features/rendering/viewModel/states/render_state.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

part 'render_view_model.g.dart';

@riverpod
class RenderViewModel extends _$RenderViewModel {
  late RenderRemoteRepository _renderRemoteRepository;

  @override
  RenderState build() {
    _renderRemoteRepository = ref.watch(renderRemoteRepositoryProvider);

    ref.listen<PickerState>(pickerViewModelProvider, (_, next) {
      next.groupedObjects.whenData((objects) {
        updateRender(groupedObjects: objects);
      });
    });

    return RenderState(renderModel: AsyncValue.loading());
  }

  void updateRender({required ObjectGroups groupedObjects}) {
    final newRenderModel = RenderModel.fromObjectGroupsAndSettings(
      objectGroups: groupedObjects,
      renderSettings: RenderSettings(), // Default settings
    );

    state = state.copyWith(renderModel: AsyncValue.data(newRenderModel));
  }

  // Query methods
  List<String> getGroupNames() {
    return state.renderModel
            .whenData((renderModel) => renderModel.getAllNames())
            .valueOrNull ??
        [];
  }

  String? getSelectedGroup() {
    return state.selectedGroup;
  }

  RenderSettings? getSettingsForGroup(String groupName) {
    return state.renderModel
        .whenData((renderModel) => renderModel.get(groupName)?.settings)
        .valueOrNull;
  }

  RenderSettings? getSelectedGroupSettings() {
    if (state.selectedGroup == null) return null;
    return getSettingsForGroup(state.selectedGroup!);
  }

  bool isDownloading() {
    return state.downloadedFile.isLoading;
  }

  String? getDownloadStatus() {
    return state.downloadStatus;
  }

  File? getDownloadedFile() {
    return state.downloadedFile.valueOrNull;
  }

  bool hasDownloadError() {
    return state.downloadedFile.hasError;
  }

  String? getDownloadError() {
    if (!state.downloadedFile.hasError) return null;
    return state.downloadedFile.error.toString();
  }

  // Action methods
  void selectGroup(String? value) {
    state = state.copyWith(selectedGroup: value);
  }

  void updateGroupSettings(String groupName, RenderSettings newSettings) {
    if (state.renderModel.isLoading) {
      return;
    }

    state = state.copyWith(
      renderModel: state.renderModel.whenData(
        (renderModel) => renderModel.setGroupSettings(groupName, newSettings),
      ),
    );
  }

  // Individual setter methods (still useful for UI components that modify a single property)
  void setNumImages(String groupName, int value) {
    if (state.renderModel.isLoading) return;

    final settings = getSettingsForGroup(groupName);
    if (settings == null) return;

    final newSettings = settings.copyWith(numImages: value);
    updateGroupSettings(groupName, newSettings);
  }

  void setAzimuthAug(String groupName, bool value) {
    if (state.renderModel.isLoading) return;

    final settings = getSettingsForGroup(groupName);
    if (settings == null) return;

    final newSettings = settings.copyWith(azimuthAug: value);
    updateGroupSettings(groupName, newSettings);
  }

  void setElevationAug(String groupName, bool value) {
    if (state.renderModel.isLoading) return;

    final settings = getSettingsForGroup(groupName);
    if (settings == null) return;

    final newSettings = settings.copyWith(elevationAug: value);
    updateGroupSettings(groupName, newSettings);
  }

  void setResolution(String groupName, int value) {
    if (state.renderModel.isLoading) return;

    final settings = getSettingsForGroup(groupName);
    if (settings == null) return;

    final newSettings = settings.copyWith(resolution: value);
    updateGroupSettings(groupName, newSettings);
  }

  void setModeMulti(String groupName, bool value) {
    if (state.renderModel.isLoading) return;

    final settings = getSettingsForGroup(groupName);
    if (settings == null) return;

    final newSettings = settings.copyWith(modeMulti: value);
    updateGroupSettings(groupName, newSettings);
  }

  void setModeStatic(String groupName, bool value) {
    if (state.renderModel.isLoading) return;

    final settings = getSettingsForGroup(groupName);
    if (settings == null) return;

    final newSettings = settings.copyWith(modeStatic: value);
    updateGroupSettings(groupName, newSettings);
  }

  void setModeFrontView(String groupName, bool value) {
    if (state.renderModel.isLoading) return;

    final settings = getSettingsForGroup(groupName);
    if (settings == null) return;

    final newSettings = settings.copyWith(modeFrontView: value);
    updateGroupSettings(groupName, newSettings);
  }

  void setModeFourView(String groupName, bool value) {
    if (state.renderModel.isLoading) return;

    final settings = getSettingsForGroup(groupName);
    if (settings == null) return;

    final newSettings = settings.copyWith(modeFourView: value);
    updateGroupSettings(groupName, newSettings);
  }

  void setEngine(String groupName, String value) {
    if (state.renderModel.isLoading) return;

    final settings = getSettingsForGroup(groupName);
    if (settings == null) return;

    final newSettings = settings.copyWith(engine: value);
    updateGroupSettings(groupName, newSettings);
  }

  void setOnlyNorthernHemisphere(String groupName, bool value) {
    if (state.renderModel.isLoading) return;

    final settings = getSettingsForGroup(groupName);
    if (settings == null) return;

    final newSettings = settings.copyWith(onlyNorthernHemisphere: value);
    updateGroupSettings(groupName, newSettings);
  }

  void setSeparately(String groupName, bool value) {
    if (state.renderModel.isLoading) return;

    final settings = getSettingsForGroup(groupName);
    if (settings == null) return;

    final newSettings = settings.copyWith(separately: value);
    updateGroupSettings(groupName, newSettings);
  }

  void sendSettings() async {
    state = state.copyWith(
      downloadStatus: "Sending rendering request...",
      downloadedFile: const AsyncValue.loading(),
    );

    state.renderModel.whenData((renderModel) async {
      try {
        state = state.copyWith(downloadStatus: "Processing render request...");

        final response = await _renderRemoteRepository.sendSettings(
          renderModel,
        );

        state = switch (response) {
          Right(value: final r) => state.copyWith(
            downloadedFile: AsyncValue.data(r),
            downloadStatus: "Rendering successful! Download initiated.",
          ),
          Left(value: final l) => state.copyWith(
            downloadedFile: const AsyncValue.error(
              "Failed to send settings",
              StackTrace.empty,
            ),
            downloadStatus: "Rendering failed. Please try again.",
          ),
        };
        // in web mode The actual download is handled by the browser through web_download_helper.dart
      } catch (e, stack) {
        state = state.copyWith(
          downloadedFile: AsyncValue.error(e, stack),
          downloadStatus: "Error: ${e.toString()}",
        );
      }
    });
  }

  void resetDownload() {
    state = state.copyWith(
      downloadedFile: const AsyncValue.data(null),
      downloadStatus: null,
    );
  }
}
