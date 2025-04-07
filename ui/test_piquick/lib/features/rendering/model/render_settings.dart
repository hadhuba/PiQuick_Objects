import 'dart:convert';

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
  bool separately;

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
    this.separately = true,
    // this.finish = false,
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
    bool? separately,
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
      separately: separately ?? this.separately,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'numImages': numImages,
      'azimuthAug': azimuthAug,
      'elevationAug': elevationAug,
      'resolution': resolution,
      'modeMulti': modeMulti,
      'modeStatic': modeStatic,
      'modeFrontView': modeFrontView,
      'modeFourView': modeFourView,
      'engine': engine,
      'onlyNorthernHemisphere': onlyNorthernHemisphere,
      'separately': separately,
    };
  }

  factory RenderSettings.fromMap(Map<String, dynamic> map) {
    return RenderSettings(
      numImages: map['numImages'] as int,
      azimuthAug: map['azimuthAug'] as bool,
      elevationAug: map['elevationAug'] as bool,
      resolution: map['resolution'] as int,
      modeMulti: map['modeMulti'] as bool,
      modeStatic: map['modeStatic'] as bool,
      modeFrontView: map['modeFrontView'] as bool,
      modeFourView: map['modeFourView'] as bool,
      engine: map['engine'] as String,
      onlyNorthernHemisphere: map['onlyNorthernHemisphere'] as bool,
      separately: map['separately'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory RenderSettings.fromJson(String source) => RenderSettings.fromMap(json.decode(source) as Map<String, dynamic>);
}
