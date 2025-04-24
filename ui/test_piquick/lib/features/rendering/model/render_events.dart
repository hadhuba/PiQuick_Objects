// A rendering modul különböző eseményeinek definíciói
abstract class RenderEvent {
  const RenderEvent();
}

// A beállítások mentésének eseménye
class SaveSettingsEvent extends RenderEvent {
  final String groupName;
  final bool shouldSendToServer;

  const SaveSettingsEvent({
    required this.groupName,
    this.shouldSendToServer = false,
  });
}

// Egyéb események itt definiálhatók
class ResetFormEvent extends RenderEvent {
  final String groupName;

  const ResetFormEvent({required this.groupName});
}

class SendSettingsEvent extends RenderEvent {
  const SendSettingsEvent();
}
