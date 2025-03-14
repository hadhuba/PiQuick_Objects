import 'package:flutter/material.dart';
import 'package:piquick_objects/model/render_model.dart';

class RenderViewModel with ChangeNotifier {
  final RenderModel _renderModel;

  int _numImages;
  bool _azimuthAug;
  bool _elevationAug;
  int _resolution;
  bool _modeMulti;
  bool _modeStatic;
  bool _modeFrontView;
  bool _modeFourView;
  String _engine;
  bool _onlyNorthernHemisphere;

  RenderViewModel(this._renderModel)
      : _numImages = _renderModel.numImages,
        _azimuthAug = _renderModel.azimuthAug,
        _elevationAug = _renderModel.elevationAug,
        _resolution = _renderModel.resolution,
        _modeMulti = _renderModel.modeMulti,
        _modeStatic = _renderModel.modeStatic,
        _modeFrontView = _renderModel.modeFrontView,
        _modeFourView = _renderModel.modeFourView,
        _engine = _renderModel.engine,
        _onlyNorthernHemisphere = _renderModel.onlyNorthernHemisphere;

  int get numImages => _numImages;
  bool get azimuthAug => _azimuthAug;
  bool get elevationAug => _elevationAug;
  int get resolution => _resolution;
  bool get modeMulti => _modeMulti;
  bool get modeStatic => _modeStatic;
  bool get modeFrontView => _modeFrontView;
  bool get modeFourView => _modeFourView;
  String get engine => _engine;
  bool get onlyNorthernHemisphere => _onlyNorthernHemisphere;

  void setNumImages(int value) {
    _numImages = value;
    notifyListeners();
  }

  void setAzimuthAug(bool value) {
    _azimuthAug = value;
    notifyListeners();
  }

  void setElevationAug(bool value) {
    _elevationAug = value;
    notifyListeners();
  }

  void setResolution(int value) {
    _resolution = value;
    notifyListeners();
  }

  void setModeMulti(bool value) {
    _modeMulti = value;
    notifyListeners();
  }

  void setModeStatic(bool value) {
    _modeStatic = value;
    notifyListeners();
  }

  void setModeFrontView(bool value) {
    _modeFrontView = value;
    notifyListeners();
  }

  void setModeFourView(bool value) {
    _modeFourView = value;
    notifyListeners();
  }

  void setEngine(String value) {
    _engine = value;
    notifyListeners();
  }

  void setOnlyNorthernHemisphere(bool value) {
    _onlyNorthernHemisphere = value;
    notifyListeners();
  }

  void saveSettings() {
    _renderModel.updateSettings(
      numImages: _numImages,
      azimuthAug: _azimuthAug,
      elevationAug: _elevationAug,
      resolution: _resolution,
      modeMulti: _modeMulti,
      modeStatic: _modeStatic,
      modeFrontView: _modeFrontView,
      modeFourView: _modeFourView,
      engine: _engine,
      onlyNorthernHemisphere: _onlyNorthernHemisphere,
    );
    notifyListeners();
  }
}