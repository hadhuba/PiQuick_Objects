import 'dart:convert';

class RenderSettings {
  // Internal properties that match the Python Pydantic model
  int numImages;
  bool azimuthAug;
  bool elevationAug;
  int resolution;
  bool modeMulti;
  bool modeFrontView;
  bool modeFourView;
  bool onlyNorthernHemisphere;
  bool separately;

  // Human-readable descriptions for UI display
  static const Map<String, String> labels = {
    'numImages': 'Number of Frames',
    'azimuthAug': 'Azimuth Augmentation',
    'elevationAug': 'Elevation Augmentation',
    'resolution': 'Image Resolution',
    'modeMulti': 'Multi-View Mode',
    'modeFrontView': 'Front View Mode',
    'modeFourView': 'Four View Mode',
    'onlyNorthernHemisphere': 'Only Northern Hemisphere',
    'separately': 'Render Separately',
  };

  // Detailed descriptions for tooltips or help text
  static const Map<String, String> descriptions = {
    'numImages':
        'Number of frames to render. The motion stops at a certain timestep, which differs with each case. Note that Mode Four View will only render 4 frames, and Mode Front will only render 1 single frame. This setting will only be used for the Multi View Mode.',
    'azimuthAug':
        'If enabled, images will be rendered from a random azimuth angle.',
    'elevationAug':
        'If enabled, images will be rendered from a random elevation angle.',
    'resolution':
        'Image resolution in pixels (e.g. 256 means 256×256). Higher values produce better quality but take longer to render.',
    'modeMulti':
        'If enabled, images will be rendered by continously rotating the object. At least one view mode must be enabled.',
    'modeFrontView':
        'If enabled, images will be rendered from the front. At least one view mode must be enabled.',
    'modeFourView':
        'If enabled, images will be rendered from front/left/right/back. At least one view mode must be enabled.',
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
    this.modeFrontView = false,
    this.modeFourView = false,
    this.onlyNorthernHemisphere = true,
    this.separately = true,
  });

  RenderSettings copyWith({
    int? numImages,
    bool? azimuthAug,
    bool? elevationAug,
    int? resolution,
    bool? modeMulti,
    bool? modeFrontView,
    bool? modeFourView,
    bool? onlyNorthernHemisphere,
    bool? separately,
  }) {
    return RenderSettings(
      numImages: numImages ?? this.numImages,
      azimuthAug: azimuthAug ?? this.azimuthAug,
      elevationAug: elevationAug ?? this.elevationAug,
      resolution: resolution ?? this.resolution,
      modeMulti: modeMulti ?? this.modeMulti,
      modeFrontView: modeFrontView ?? this.modeFrontView,
      modeFourView: modeFourView ?? this.modeFourView,
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
      'mode_front_view': modeFrontView,
      'mode_four_view': modeFourView,
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
      modeFrontView: map['mode_front_view'] ?? map['modeFrontView'] as bool,
      modeFourView: map['mode_four_view'] ?? map['modeFourView'] as bool,
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
