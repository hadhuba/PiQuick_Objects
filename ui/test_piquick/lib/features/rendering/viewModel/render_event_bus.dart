import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/features/rendering/model/render_events.dart';

part 'render_event_bus.g.dart';

/// Event bus osztály, ami központilag kezeli a rendering eseményeket.
/// Biztosítja, hogy a komponensek kommunikálhassanak egymással közvetlen függőség nélkül.
class RenderEventBus {
  final _controller = StreamController<RenderEvent>.broadcast();

  /// A stream, amit más komponensek figyelhetnek az események kezelésére
  Stream<RenderEvent> get events => _controller.stream;

  /// Esemény kiváltása a buszra
  void emit(RenderEvent event) {
    _controller.add(event);
  }

  /// Adott típusú események figyelése
  Stream<T> on<T extends RenderEvent>() {
    return events.where((event) => event is T).cast<T>();
  }

  /// Erőforrások felszabadítása
  void dispose() {
    _controller.close();
  }
}

/// Riverpod provider az event bus-hoz
@Riverpod(keepAlive: true)
RenderEventBus renderEventBus(RenderEventBusRef ref) {
  final bus = RenderEventBus();
  ref.onDispose(bus.dispose);
  return bus;
}
