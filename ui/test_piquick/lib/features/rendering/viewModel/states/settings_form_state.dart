import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:test_piquick/features/rendering/model/render_model.dart';
// import 'dart:io';

import 'package:test_piquick/features/rendering/model/settings_form_model.dart';

class SettingsFormState {
  final AsyncValue<String> groupName;
  final AsyncValue<SettingsFormModel> formModel;

  SettingsFormState({
    required this.groupName,
    required this.formModel,
  });

  SettingsFormState copyWith({
    AsyncValue<String>? groupName,
    AsyncValue<SettingsFormModel>? formModel,
  }) {
    return SettingsFormState(
      groupName: groupName ?? this.groupName,
      formModel: formModel ?? this.formModel,
    );
  }
}
