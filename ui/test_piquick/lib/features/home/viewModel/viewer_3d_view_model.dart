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


import 'package:flutter/material.dart';
import 'package:test_piquick/features/home/model/piquick_model.dart';

class PiquickViewModel with ChangeNotifier {
  final PiquickModel _piquickModel;

  PiquickViewModel(this._piquickModel);

  String get currentObj => _piquickModel.currentObj;
  String? get currentAnimation => _piquickModel.currentAnimation;
  String? get currentTexture => _piquickModel.currentTexture;

  void updateObj(String newObj) {
    _piquickModel.currentObj = newObj;
    notifyListeners();
  }

  void updateAnimation(String? newAnimation) {
    _piquickModel.currentAnimation = newAnimation;
    notifyListeners();
  }

  void updateTexture(String? newTexture) {
    _piquickModel.currentTexture = newTexture;
    notifyListeners();
  }
}