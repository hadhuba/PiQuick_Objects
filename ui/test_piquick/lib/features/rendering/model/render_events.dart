// A rendering modul különböző eseményeinek definíciói
import 'package:test_piquick/features/rendering/model/render_settings.dart';

abstract class RenderEvent {
  const RenderEvent();
}

// A beállítások mentésének eseménye
class SaveSettingsEvent extends RenderEvent {
  final String groupName;
  final RenderSettings settings; // A beállítások objektum

  const SaveSettingsEvent({
    required this.groupName,
    required this.settings,
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
