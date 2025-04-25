import 'package:flutter/src/widgets/framework.dart';
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

part 'auto_generated/render_view_model.g.dart';

@riverpod
class RenderViewModel extends _$RenderViewModel {
  late RenderRemoteRepository _renderRemoteRepository;
  late SettingsFormViewModel settingsFormViewModel;
  StreamSubscription? _eventSubscription;

  @override
  RenderState build() {
    _renderRemoteRepository = ref.watch(renderRemoteRepositoryProvider);
    settingsFormViewModel = ref.watch(settingsFormViewModelProvider.notifier);

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

    return RenderState(renderModel: AsyncValue.loading(), groupNames: []);
  }

  void _setupEventListeners() {
    final bus = ref.read(renderEventBusProvider);

    _eventSubscription = bus.events.listen((event) {
      if (event is SaveSettingsEvent) {
        _handleSaveSettingsEvent(event);
      } else if (event is SendSettingsEvent) {
        _handleSendSettingsEvent(event);
      } else if (event is ResetFormEvent) {
        createOrUpdateSettingsForm(event.groupName);
      }
    });
  }

  void _handleSaveSettingsEvent(SaveSettingsEvent event) {
    final newSettings =
        settingsFormViewModel.state.formModel.toRenderSettings();
    updateGroupSettings(event.groupName, newSettings);
  }

  void _handleSendSettingsEvent(SendSettingsEvent event) {
    sendSettings();
  }

  // SettingsFormViewModel létrehozás vagy frissítése
  SettingsFormViewModel createOrUpdateSettingsForm(String groupName) {
    final settings = getSettingsForGroup(groupName);
    settingsFormViewModel.initialize(groupName: groupName, settings: settings);
    return settingsFormViewModel;
  }

  SettingsFormViewModel emptySettingsForm() {
    settingsFormViewModel.initialize(groupName: null, settings: null);
    return settingsFormViewModel;
  }

  void updateRender({required ObjectGroups groupedObjects}) {
    // Get current render model if available to preserve existing settings
    final currentRenderModel = state.renderModel.valueOrNull;

    // Create a new model that will contain groups with preserved settings where possible
    final List<Group> newGroups = [];

    // Process each group in the new object list
    final Set<String> groupNames = groupedObjects.groups.keys.toSet();

    if (groupNames.isEmpty) {
      // If no groups exist, reset the model and selected group
      state = state.copyWith(
        renderModel: AsyncValue.data(RenderModel(groups: [])),
        selectedGroup: null,
        groupNames: [],
      );
      return;
    }

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

    // Handle selected group logic - ensure it's valid after group updates
    String? updatedSelectedGroup = state.selectedGroup;

    // If currently selected group no longer exists, select a new one or null
    if (updatedSelectedGroup != null &&
        !groupNames.contains(updatedSelectedGroup)) {
      updatedSelectedGroup = groupNames.isNotEmpty ? groupNames.first : null;
    }
    // If no group is selected but groups are available, select the first one
    else if (updatedSelectedGroup == null && groupNames.isNotEmpty) {
      updatedSelectedGroup = groupNames.first;
    }

    final newRenderModel = RenderModel(groups: newGroups);

    // Update state with new model AND potentially new selection
    state = state.copyWith(
      renderModel: AsyncValue.data(newRenderModel),
      selectedGroup: updatedSelectedGroup,
      groupNames: groupNames.toList(),
    );

    // Update the form if there's a selected group
    if (updatedSelectedGroup != null) {
      createOrUpdateSettingsForm(updatedSelectedGroup);
    } else {
      emptySettingsForm();
    }
  }


  RenderSettings? getSettingsForGroup(String groupName) {
    return state.renderModel
        .whenData((renderModel) => renderModel.get(groupName)?.settings)
        .valueOrNull;
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


  // Action methods
  void selectGroup(String? value) {
    state = state.copyWith(selectedGroup: value);
    if (value != null) {
      createOrUpdateSettingsForm(value);
    }
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

  void sendSettings() async {
    final newSettings =
      settingsFormViewModel.state.formModel.toRenderSettings();
      updateGroupSettings(settingsFormViewModel.state.groupName, newSettings);
    
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
            downloadedFile: AsyncValue.error(
              l.message,
              StackTrace.empty,
            ),
            downloadStatus: "Rendering unsuccessful!",
          ),
        };
        // in web mode The actual download is handled by the browser through web_download_helper.dart
      } catch (e, stack) {
        state = state.copyWith(
          downloadedFile: AsyncValue.error(e, stack),
          downloadStatus: "Unexpeceted error occurred...",
        );
      }
    });
  }

  void resetDownload() {
    sendSettings();
  }

  void dismissRender() {
    state = state.copyWith(
      downloadedFile: const AsyncValue.data(null),
      downloadStatus: null,
    );
  }
}
