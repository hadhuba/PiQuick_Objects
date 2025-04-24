import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/features/rendering/model/render_events.dart';
import 'package:test_piquick/features/rendering/model/render_settings.dart';
import 'package:test_piquick/features/rendering/model/settings_form_model.dart';
import 'package:test_piquick/features/rendering/viewModel/render_event_bus.dart';
import 'package:test_piquick/features/rendering/viewModel/states/settings_form_state.dart';

part 'settings_form_view_model.g.dart';

@riverpod
class SettingsFormViewModel extends _$SettingsFormViewModel {
  StreamSubscription? _eventSubscription;

  @override
  SettingsFormState build() {
    _setupEventListeners();
    ref.onDispose(() {
      _eventSubscription?.cancel();
    });
    // _initializeFormViewModel();

    return SettingsFormState(
      groupName: AsyncValue.loading(),
      formModel: AsyncValue.loading(),
    );
  }

  // SettingsFormViewModel({
  //   required String groupName,
  //   required RenderSettings? settings,
  // }) {}

  /// Initialize the form viewmodel with settings from the view model
  void _initializeFormViewModel(RenderSettings? settings) {
    // if (settings != null) {
    //   formModel = SettingsFormModel.fromSettings(settings);
    // } else {
    //   formModel = SettingsFormModel.defaults();
    // }
  }

  void _setupEventListeners() {
    // final bus = ref.read(renderEventBusProvider);

    // _eventSubscription = bus.events.listen((event) {
    //   if (event is SaveSettingsEvent) {
    //     _handleSaveSettingsEvent(event);
    //   } else if (event is SendSettingsEvent) {
    //     sendSettings();
    //   } else if (event is ResetFormEvent) {
    //     // Form reset esemény kezelése szükség szerint
    //     print("Form reset for group: ${event.groupName}");
    //   }
    // });
  }

  /// Reset the form to its initial values from the view model
  void resetForm() {
    // formModel.dispose();
    // _initializeFormViewModel(null);
    // Értesítjük az event bus-on keresztül, hogy a form reset történt
    ref.read(renderEventBusProvider).emit(ResetFormEvent(groupName: groupName));
  }

  /// Save the current form values to the view model
  bool saveSettings({bool sendToServer = false}) {
    if (formModel.validate()) {
      // Kiváltunk egy eseményt az event bus-on keresztül
      final newSettings = formModel.toRenderSettings();
      ref
          .read(renderEventBusProvider)
          .emit(
            SaveSettingsEvent(
              groupName: groupName,
              shouldSendToServer: sendToServer,
            ),
          );
      return true;
    }
    return false;
  }

  /// Save settings and send to server
  void saveAndSendSettings() {
    if (saveSettings()) {
      // Kiváltunk egy eseményt a beállítások elküldésére
      ref.read(renderEventBusProvider).emit(const SendSettingsEvent());
    }
  }

  /// Dispose of resources
  void dispose() {
    formModel.dispose();
  }
}
