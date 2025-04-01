import 'package:flutter_riverpod/flutter_riverpod.dart';

class Viewer3DViewModel extends StateNotifier<String> {
  Viewer3DViewModel() : super('');

  void updateObject(String newObject) {
    state = newObject;
  }
}

final viewer3DProvider = StateNotifierProvider<Viewer3DViewModel, String>(
  (ref) => Viewer3DViewModel(),
);