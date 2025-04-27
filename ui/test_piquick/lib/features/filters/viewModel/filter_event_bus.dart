import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/features/filters/model/filter_events.dart';

part 'auto_generated/filter_event_bus.g.dart';

/// Event bus osztály, ami központilag kezeli a rendering eseményeket.
/// Biztosítja, hogy a komponensek kommunikálhassanak egymással közvetlen függőség nélkül.
class FilterEventBus {
  final _controller = StreamController<FilterEvent>.broadcast();

  /// A stream, amit más komponensek figyelhetnek az események kezelésére
  Stream<FilterEvent> get events => _controller.stream;

  /// Esemény kiváltása a buszra
  void emit(FilterEvent event) {
    _controller.add(event);
  }

  /// Adott típusú események figyelése
  Stream<T> on<T extends FilterEvent>() {
    return events.where((event) => event is T).cast<T>();
  }

  /// Erőforrások felszabadítása
  void dispose() {
    _controller.close();
  }
}

/// Riverpod provider az event bus-hoz
@Riverpod(keepAlive: true)
FilterEventBus filterEventBus(Ref ref) {
  final bus = FilterEventBus();
  ref.onDispose(bus.dispose);
  return bus;
}
