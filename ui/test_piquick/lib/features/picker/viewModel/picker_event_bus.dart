import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/features/picker/model/picker_events.dart';

part 'auto_generated/picker_event_bus.g.dart';

/// Event bus osztály, ami központilag kezeli a rendering eseményeket.
/// Biztosítja, hogy a komponensek kommunikálhassanak egymással közvetlen függőség nélkül.
class PickerEventBus {
  final _controller = StreamController<PickerEvent>.broadcast();

  /// A stream, amit más komponensek figyelhetnek az események kezelésére
  Stream<PickerEvent> get events => _controller.stream;

  /// Esemény kiváltása a buszra
  void emit(PickerEvent event) {
    _controller.add(event);
  }

  /// Adott típusú események figyelése
  Stream<T> on<T extends PickerEvent>() {
    return events.where((event) => event is T).cast<T>();
  }

  /// Erőforrások felszabadítása
  void dispose() {
    _controller.close();
  }
}

/// Riverpod provider az event bus-hoz
@Riverpod(keepAlive: true)
PickerEventBus pickerEventBus(Ref ref) {
  final bus = PickerEventBus();
  ref.onDispose(bus.dispose);
  return bus;
}
