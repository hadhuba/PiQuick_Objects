import 'package:frontend/features/rendering/model/render_settings.dart';

/// Base class for all rendering-related events in the application.
abstract class RenderEvent {
  const RenderEvent();
}

/// Event triggered when rendering settings are saved for a specific group.
class SaveSettingsEvent extends RenderEvent {
  final String groupName;
  final RenderSettings settings;

  const SaveSettingsEvent({required this.groupName, required this.settings});
}

/// Event to reset the rendering form to default values for a specific group.
class ResetFormEvent extends RenderEvent {
  final String groupName;

  const ResetFormEvent({required this.groupName});
}

/// Event to send current rendering settings to the server.
class SendSettingsEvent extends RenderEvent {
  const SendSettingsEvent();
}
