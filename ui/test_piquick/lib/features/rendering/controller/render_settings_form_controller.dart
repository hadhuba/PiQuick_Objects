import 'package:flutter/material.dart';
import 'package:test_piquick/features/rendering/model/render_settings.dart';
import 'package:test_piquick/features/rendering/model/render_settings_form_model.dart';
import 'package:test_piquick/features/rendering/viewModel/render_view_model.dart';

/// Controller for the render settings form that connects the form model to the view model
class RenderSettingsFormController {
  final RenderViewModel viewModel;
  final String groupName;
  late RenderSettingsFormModel formModel;

  RenderSettingsFormController({
    required this.viewModel,
    required this.groupName,
  }) {
    _initializeFormModel();
  }

  /// Initialize the form model with settings from the view model
  void _initializeFormModel() {
    final settings = viewModel.getSettingsForGroup(groupName);

    if (settings != null) {
      formModel = RenderSettingsFormModel.fromSettings(settings);
    } else {
      formModel = RenderSettingsFormModel.defaults();
    }
  }

  /// Reset the form to its initial values from the view model
  void resetForm() {
    formModel.dispose();
    _initializeFormModel();
  }

  /// Save the current form values to the view model
  bool saveSettings() {
    if (formModel.validate()) {
      final newSettings = formModel.toRenderSettings();
      viewModel.updateGroupSettings(groupName, newSettings);
      return true;
    }
    return false;
  }

  /// Save settings and send to server
  void saveAndSendSettings() {
    if (saveSettings()) {
      viewModel.sendSettings();
    }
  }

  /// Check if a download is in progress
  bool isDownloading() {
    return viewModel.isDownloading();
  }

  /// Get the current download status
  String? getDownloadStatus() {
    return viewModel.getDownloadStatus();
  }

  /// Get any download error
  String? getDownloadError() {
    return viewModel.getDownloadError();
  }

  /// Reset the download state
  void resetDownload() {
    viewModel.resetDownload();
  }

  /// Dispose of resources
  void dispose() {
    formModel.dispose();
  }
}
