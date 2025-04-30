import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:frontend/features/rendering/model/render_events.dart';
import 'package:frontend/features/rendering/model/render_settings.dart';
import 'package:frontend/features/rendering/model/settings_form_model.dart';
import 'package:frontend/features/rendering/viewModel/render_event_bus.dart';
import 'package:frontend/features/rendering/viewModel/states/settings_form_state.dart';

part 'auto_generated/settings_form_view_model.g.dart';

/// Manages the form for configuring rendering settings.
/// Handles form state, validation, saving settings, and communication with the event bus.
@riverpod
class SettingsFormViewModel extends _$SettingsFormViewModel {
  String? _groupName;
  RenderSettings? _settings;

  /// Initialize with group name and settings
  void initialize({String? groupName, RenderSettings? settings}) {
    _groupName = groupName;
    _settings = settings;

    // Create form model from settings or defaults
    final formModel =
        settings != null
            ? SettingsFormModel.fromSettings(settings)
            : SettingsFormModel.defaults();

    state = SettingsFormState(groupName: groupName ?? '', formModel: formModel);
  }

  @override
  SettingsFormState build({groupName, RenderSettings? settings}) {
    // Default empty state - must call initialize() before using
    return SettingsFormState(
      groupName: groupName,
      formModel:
          settings != null
              ? SettingsFormModel.fromSettings(settings)
              : SettingsFormModel.defaults(),
    );
  }

  /// Reset the form to its initial values from the view model
  void resetForm() {
    state.formModel.dispose();

    // Create a new form model from the saved settings or defaults
    final formModel =
        _settings != null
            ? SettingsFormModel.fromSettings(_settings!)
            : SettingsFormModel.defaults();

    state = SettingsFormState(
      groupName: _groupName ?? '',
      formModel: formModel,
    );

    // Notify via the event bus that a form reset occurred
    ref
        .read(renderEventBusProvider)
        .emit(ResetFormEvent(groupName: state.groupName));
  }

  /// Save the current form values to the view model
  bool saveSettings() {
    if (state.formModel.validate()) {
      // Emit an event through the event bus
      final newSettings = state.formModel.toRenderSettings();
      _settings = newSettings; // Save settings locally too

      ref
          .read(renderEventBusProvider)
          .emit(
            SaveSettingsEvent(
              groupName: state.groupName,
              settings: newSettings,
            ),
          );
      return true;
    }
    return false;
  }

  /// Save settings and send to server
  void saveAndSendSettings() {
    if (saveSettings()) {
      // Emit an event to send the settings
      ref.read(renderEventBusProvider).emit(const SendSettingsEvent());
    }
  }

  /// Get the description of a field by its ID
  String getDescription(String fieldId) {
    return RenderSettings.getDescription(fieldId);
  }

  Key get formKey => state.formModel.formKey;

  SettingsFormModel get formModel => state.formModel;

  /// Dispose of resources
  void dispose() {
    state.formModel.dispose();
  }
}
