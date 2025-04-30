import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:frontend/features/rendering/model/render_events.dart';

part 'auto_generated/render_event_bus.g.dart';

/// Event bus class that centrally manages rendering events.
/// Enables components to communicate without direct dependencies.
class RenderEventBus {
  final _controller = StreamController<RenderEvent>.broadcast();

  /// Stream that other components can listen to for handling events
  Stream<RenderEvent> get events => _controller.stream;

  /// Emit an event to the bus
  void emit(RenderEvent event) {
    _controller.add(event);
  }

  /// Listen for events of a specific type
  Stream<T> on<T extends RenderEvent>() {
    return events.where((event) => event is T).cast<T>();
  }

  /// Release resources
  void dispose() {
    _controller.close();
  }
}

/// Riverpod provider for the event bus
@Riverpod(keepAlive: true)
RenderEventBus renderEventBus(Ref ref) {
  final bus = RenderEventBus();
  ref.onDispose(bus.dispose);
  return bus;
}
