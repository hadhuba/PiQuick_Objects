import 'package:flutter/material.dart';
import 'package:piquick_objects/model/piquick_model.dart';

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