// ignore_for_file: public_member_api_docs, sort_constructors_first
class RenderSettings {
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
  bool finish;

  RenderSettings({
    this.numImages = 12,
    this.azimuthAug = true,
    this.elevationAug = false,
    this.resolution = 256,
    this.modeMulti = true,
    this.modeStatic = false,
    this.modeFrontView = false,
    this.modeFourView = false,
    this.engine = 'CYCLES',
    this.onlyNorthernHemisphere = true,
    this.finish = false,
  });

  RenderSettings copyWith({
    int? numImages,
    bool? azimuthAug,
    bool? elevationAug,
    int? resolution,
    bool? modeMulti,
    bool? modeStatic,
    bool? modeFrontView,
    bool? modeFourView,
    String? engine,
    bool? onlyNorthernHemisphere,
    bool? finish,
  }) {
    return RenderSettings(
      numImages: numImages ?? this.numImages,
      azimuthAug: azimuthAug ?? this.azimuthAug,
      elevationAug: elevationAug ?? this.elevationAug,
      resolution: resolution ?? this.resolution,
      modeMulti: modeMulti ?? this.modeMulti,
      modeStatic: modeStatic ?? this.modeStatic,
      modeFrontView: modeFrontView ?? this.modeFrontView,
      modeFourView: modeFourView ?? this.modeFourView,
      engine: engine ?? this.engine,
      onlyNorthernHemisphere:
          onlyNorthernHemisphere ?? this.onlyNorthernHemisphere,
      finish: finish ?? this.finish,
    );
  }

  bool setDone() {
    if (numImages > 0 &&
        resolution > 0 &&
        (modeMulti || modeStatic || modeFrontView || modeFourView) &&
        engine.isNotEmpty) {
      return true;
    }
    else {
      return false;
    }
  }
}
