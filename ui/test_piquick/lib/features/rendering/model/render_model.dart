class RenderModel {
  int numImages;
  bool azimuthAug;
  bool elevationAug;
  int resolution;
  bool modeMulti;
  bool modeStatic;
  bool modeFrontView;
  bool modeFourView;
  String engine;
  bool onlyNorthernHemisphere;

  RenderModel({
    required this.numImages,
    required this.azimuthAug,
    required this.elevationAug,
    required this.resolution,
    required this.modeMulti,
    required this.modeStatic,
    required this.modeFrontView,
    required this.modeFourView,
    required this.engine,
    required this.onlyNorthernHemisphere,
  });

  void updateSettings({
    required int numImages,
    required bool azimuthAug,
    required bool elevationAug,
    required int resolution,
    required bool modeMulti,
    required bool modeStatic,
    required bool modeFrontView,
    required bool modeFourView,
    required String engine,
    required bool onlyNorthernHemisphere,
  }) {
    this.numImages = numImages;
    this.azimuthAug = azimuthAug;
    this.elevationAug = elevationAug;
    this.resolution = resolution;
    this.modeMulti = modeMulti;
    this.modeStatic = modeStatic;
    this.modeFrontView = modeFrontView;
    this.modeFourView = modeFourView;
    this.engine = engine;
    this.onlyNorthernHemisphere = onlyNorthernHemisphere;
  }
}