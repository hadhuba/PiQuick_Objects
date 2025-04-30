import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:frontend/features/filters/model/filter_events.dart';

part 'auto_generated/filter_event_bus.g.dart';

/// Event bus class that centrally manages rendering events.
/// Ensures that components can communicate without direct dependencies.
class FilterEventBus {
  final _controller = StreamController<FilterEvent>.broadcast();

  /// Stream that other components can listen to for handling events
  Stream<FilterEvent> get events => _controller.stream;

  /// Emit an event to the bus
  void emit(FilterEvent event) {
    _controller.add(event);
  }

  /// Listen for events of a specific type
  Stream<T> on<T extends FilterEvent>() {
    return events.where((event) => event is T).cast<T>();
  }

  /// Release resources
  void dispose() {
    _controller.close();
  }
}

/// Riverpod provider for the event bus
@Riverpod(keepAlive: true)
FilterEventBus filterEventBus(Ref ref) {
  final bus = FilterEventBus();
  ref.onDispose(bus.dispose);
  return bus;
}
