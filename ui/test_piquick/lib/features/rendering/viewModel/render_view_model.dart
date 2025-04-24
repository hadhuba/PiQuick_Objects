import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/features/picker/model/object_groups_model.dart';
import 'package:test_piquick/features/picker/viewModel/states/picker_state.dart';
import 'package:test_piquick/features/picker/viewModel/picker_view_model.dart';
import 'package:test_piquick/features/rendering/model/group.dart';
import 'package:test_piquick/features/rendering/model/render_events.dart';
import 'package:test_piquick/features/rendering/model/render_model.dart';
import 'package:test_piquick/features/rendering/model/render_settings.dart';
import 'package:test_piquick/features/rendering/repository/render_remote_repository.dart';
import 'package:test_piquick/features/rendering/viewModel/render_event_bus.dart';
import 'package:test_piquick/features/rendering/viewModel/settings_form_view_model.dart';
import 'package:test_piquick/features/rendering/viewModel/states/render_state.dart';
import 'dart:async';
import 'dart:io';

part 'render_view_model.g.dart';

@riverpod
class RenderViewModel extends _$RenderViewModel {
  late RenderRemoteRepository _renderRemoteRepository;
  StreamSubscription? _eventSubscription;
  SettingsFormViewModel? _settingsFormViewModel;

  @override
  RenderState build() {
    _renderRemoteRepository = ref.watch(renderRemoteRepositoryProvider);

    // Figyeljük a Picker állapotváltozásait
    ref.listen<PickerState>(pickerViewModelProvider, (_, next) {
      next.groupedObjects.whenData((objects) {
        updateRender(groupedObjects: objects);
      });
    });

    // Figyeljük az EventBus eseményeit
    _setupEventListeners();
    ref.onDispose(() {
      _eventSubscription?.cancel();
    });

    return RenderState(renderModel: AsyncValue.loading());
  }

  void _setupEventListeners() {
    final bus = ref.read(renderEventBusProvider);

    _eventSubscription = bus.events.listen((event) {
      if (event is SaveSettingsEvent) {
        _handleSaveSettingsEvent(event);
      } else if (event is SendSettingsEvent) {
        sendSettings();
      } else if (event is ResetFormEvent) {
        // Form reset esemény kezelése szükség szerint
        print("Form reset for group: ${event.groupName}");
      }
    });
  }

  void _handleSaveSettingsEvent(SaveSettingsEvent event) {
    // Itt frissítjük a beállításokat a formból kapott adatok alapján
    if (_settingsFormViewModel != null) {
      final newSettings = _settingsFormViewModel!.formModel.toRenderSettings();
      updateGroupSettings(event.groupName, newSettings);

      // Ha a send to server jelző be van állítva, küldjük el a beállításokat
      if (event.shouldSendToServer) {
        sendSettings();
      }
    }
  }

  // SettingsFormViewModel létrehozás vagy frissítése
  SettingsFormViewModel createOrUpdateSettingsForm(String groupName) {
    final settings = getSettingsForGroup(groupName);
    _settingsFormViewModel = SettingsFormViewModel(
      groupName: groupName,
      settings: settings
    );
    return _settingsFormViewModel!;
  }

  void updateRender({required ObjectGroups groupedObjects}) {
    // Get current render model if available to preserve existing settings
    final currentRenderModel = state.renderModel.valueOrNull;

    // Create a new model that will contain groups with preserved settings where possible
    final List<Group> newGroups = [];

    // Process each group in the new object list
    final Set<String> groupNames = groupedObjects.groups.keys.toSet();
    for (final groupName in groupNames) {
      final objectIds = groupedObjects.groups[groupName] ?? [];

      // Try to find existing settings for this group name
      RenderSettings settings;
      if (currentRenderModel != null) {
        // If a group with the same name exists, use its settings
        final existingGroup = currentRenderModel.get(groupName);
        settings = existingGroup?.settings ?? RenderSettings();
      } else {
        // No existing model, use default settings
        settings = RenderSettings();
      }

      newGroups.add(
        Group(name: groupName, object_ids: objectIds, settings: settings),
      );
    }

    final newRenderModel = RenderModel(groups: newGroups);
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
            downloadStatus: "Error: ${l.message}",
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
