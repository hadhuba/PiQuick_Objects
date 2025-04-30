import 'package:frontend/features/rendering/model/settings_form_model.dart';

/// State class for the rendering settings form.
/// Encapsulates the group name and form model for the currently active settings form.
class SettingsFormState {
  final String groupName;
  final SettingsFormModel formModel;

  SettingsFormState({required this.groupName, required this.formModel});

  SettingsFormState copyWith({
    String? groupName,
    SettingsFormModel? formModel,
  }) {
    return SettingsFormState(
      groupName: groupName ?? this.groupName,
      formModel: formModel ?? this.formModel,
    );
  }
}
