import 'dart:convert';

class RenderSettings {
  // Internal properties that match the Python Pydantic model
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

  // Human-readable descriptions for UI display
  static const Map<String, String> labels = {
    'numImages': 'Number of Frames',
    'azimuthAug': 'Azimuth Augmentation',
    'elevationAug': 'Elevation Augmentation',
    'resolution': 'Image Resolution',
    'modeMulti': 'Multi-View Mode',
    'modeStatic': 'Static Multi-View Mode',
    'modeFrontView': 'Front View Mode',
    'modeFourView': 'Four View Mode',
    'engine': 'Rendering Engine',
    'onlyNorthernHemisphere': 'Only Northern Hemisphere',
    'separately': 'Render Separately',
  };

  // Detailed descriptions for tooltips or help text
  static const Map<String, String> descriptions = {
    'numImages':
        'Number of frames to render. The motion stops at a certain timestep, which differs with each case. Note that Mode Four View will only render 4 frames, and Mode Front will only render 1 single frame. This setting will only be used for the rest of the view modes.',
    'azimuthAug':
        'If enabled, images will be rendered from a random azimuth angle.',
    'elevationAug':
        'If enabled, images will be rendered from a random elevation angle.',
    'resolution':
        'Image resolution in pixels (e.g. 256 means 256×256). Higher values produce better quality but take longer to render.',
    'modeMulti':
        'If enabled, images will be rendered from "time 0, view 0" to "time T, view T".',
    'modeStatic':
        'If enabled, images will be rendered from "time 0, view 0" to "time 0, view T".',
    'modeFrontView':
        'If enabled, images will be rendered from "time 0, view front" to "time T, view front". The front view changes with azimuth augmentation.',
    'modeFourView':
        'If enabled, images will be rendered from "time 0, view front/left/right/back" to "time T, view front/left/right/back".',
    'engine':
        'The rendering engine to use (CYCLES for photorealistic or BLENDER_EEVEE for faster rendering).',
    'onlyNorthernHemisphere':
        'If enabled, only renders from the top hemisphere of viewing angles. This is useful for objects acquired via photogrammetry, as the southern hemisphere may have holes',
    'separately':
        'If enabled, each object in the group is rendered separately. Otherwise, the objects in the group are placed in a common scene.',
  };

  // Get display label for a property
  static String getLabel(String property) {
    return labels[property] ?? property;
  }

  // Get description for a property
  static String getDescription(String property) {
    return descriptions[property] ?? 'No description available';
  }

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

  // This method returns names that match the Python Pydantic model
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'num_images': numImages,
      'azimuth_aug': azimuthAug,
      'elevation_aug': elevationAug,
      'resolution': resolution,
      'mode_multi': modeMulti,
      'mode_static': modeStatic,
      'mode_front_view': modeFrontView,
      'mode_four_view': modeFourView,
      'engine': engine,
      'only_northern_hemisphere': onlyNorthernHemisphere,
      'separately': separately,
    };
  }

  factory RenderSettings.fromMap(Map<String, dynamic> map) {
    // Handle both snake_case (from Python) and camelCase (from Dart)
    return RenderSettings(
      numImages: map['num_images'] ?? map['numImages'] as int,
      azimuthAug: map['azimuth_aug'] ?? map['azimuthAug'] as bool,
      elevationAug: map['elevation_aug'] ?? map['elevationAug'] as bool,
      resolution: map['resolution'] as int,
      modeMulti: map['mode_multi'] ?? map['modeMulti'] as bool,
      modeStatic: map['mode_static'] ?? map['modeStatic'] as bool,
      modeFrontView: map['mode_front_view'] ?? map['modeFrontView'] as bool,
      modeFourView: map['mode_four_view'] ?? map['modeFourView'] as bool,
      engine: map['engine'] as String,
      onlyNorthernHemisphere:
          map['only_northern_hemisphere'] ??
          map['onlyNorthernHemisphere'] as bool,
      separately: map['separately'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory RenderSettings.fromJson(String source) =>
      RenderSettings.fromMap(json.decode(source) as Map<String, dynamic>);
}
