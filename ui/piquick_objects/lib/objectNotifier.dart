import 'package:flutter/material.dart';

class ObjectNotifier extends ChangeNotifier {
  String _currentObj;
  String? _currentAnimation;
  String? _currentTexture;

  String get currentObj => _currentObj;  
  String? get currentAnimation => _currentAnimation;
  String? get currentTexture => _currentTexture;

  ObjectNotifier(this._currentObj, this._currentAnimation, this._currentTexture);

  void updateObj(String newObj) {
      _currentObj = newObj;
      notifyListeners();
    }
  
  void updateAnimation(String? newAnimation) {
      _currentAnimation = newAnimation;
      notifyListeners();
    }
  
  void updateTexture(String? newTexture) {
      _currentTexture = newTexture;
      notifyListeners();
    }
  
}