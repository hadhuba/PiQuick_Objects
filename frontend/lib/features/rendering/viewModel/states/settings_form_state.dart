import 'package:frontend/features/rendering/model/settings_form_model.dart';

class SettingsFormState {
  final String groupName;
  final SettingsFormModel formModel;

  SettingsFormState({
    required this.groupName,
    required this.formModel,
  });

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
