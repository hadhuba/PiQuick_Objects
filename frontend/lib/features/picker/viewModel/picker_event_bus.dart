import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:frontend/features/picker/model/picker_events.dart';

part 'auto_generated/picker_event_bus.g.dart';

/// Event bus class that centrally manages rendering events.
/// Ensures that components can communicate without direct dependencies.
class PickerEventBus {
  final _controller = StreamController<PickerEvent>.broadcast();

  /// Stream that other components can listen to for handling events
  Stream<PickerEvent> get events => _controller.stream;

  /// Emit an event to the bus
  void emit(PickerEvent event) {
    _controller.add(event);
  }

  /// Listen for events of a specific type
  Stream<T> on<T extends PickerEvent>() {
    return events.where((event) => event is T).cast<T>();
  }

  /// Release resources
  void dispose() {
    _controller.close();
  }
}

/// Riverpod provider for the event bus
@Riverpod(keepAlive: true)
PickerEventBus pickerEventBus(Ref ref) {
  final bus = PickerEventBus();
  ref.onDispose(bus.dispose);
  return bus;
}
