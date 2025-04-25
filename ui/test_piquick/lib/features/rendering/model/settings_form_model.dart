import 'package:flutter/material.dart';
import 'package:test_piquick/features/rendering/model/render_settings.dart';

/// Form model that encapsulates the state and logic for the render settings form
class SettingsFormModel {
  TextEditingController numImagesController;
  TextEditingController resolutionController;

  // Boolean form values
  bool azimuthAug;
  bool elevationAug;
  bool modeMulti;
  bool modeStatic;
  bool modeFrontView;
  bool modeFourView;
  bool onlyNorthernHemisphere;
  bool separately;

  // Common resolution options
  static const List<int> commonResolutions = [256, 512, 1024, 2048, 4096];

  // Key for form validation
  final formKey = GlobalKey<FormState>();

  SettingsFormModel({
    required this.numImagesController,
    required this.resolutionController,
    required this.azimuthAug,
    required this.elevationAug,
    required this.modeMulti,
    required this.modeStatic,
    required this.modeFrontView,
    required this.modeFourView,
    required this.onlyNorthernHemisphere,
    required this.separately,
  });

  /// Create a form model from render settings
  factory SettingsFormModel.fromSettings(RenderSettings settings) {
    return SettingsFormModel(
      numImagesController: TextEditingController(
        text: settings.numImages.toString(),
      ),
      resolutionController: TextEditingController(
        text: settings.resolution.toString(),
      ),
      azimuthAug: settings.azimuthAug,
      elevationAug: settings.elevationAug,
      modeMulti: settings.modeMulti,
      modeStatic: settings.modeStatic,
      modeFrontView: settings.modeFrontView,
      modeFourView: settings.modeFourView,
      onlyNorthernHemisphere: settings.onlyNorthernHemisphere,
      separately: settings.separately,
    );
  }

  /// Create a form model with default values
  factory SettingsFormModel.defaults() {
    return SettingsFormModel(
      numImagesController: TextEditingController(text: "12"),
      resolutionController: TextEditingController(text: "256"),
      azimuthAug: true,
      elevationAug: false,
      modeMulti: true,
      modeStatic: false,
      modeFrontView: false,
      modeFourView: false,
      onlyNorthernHemisphere: true,
      separately: true,
    );
  }

  /// Updates image count based on selected view modes
  void updateImagesForViewMode() {
    if (modeFrontView) {
      // Server will use 1 image for front view mode
      numImagesController.text = numImagesController.text;
    } else if (modeFourView) {
      // Server will use 4 images for four view mode
      numImagesController.text = numImagesController.text;
    }
  }

  /// Convert form values to RenderSettings object
  RenderSettings toRenderSettings() {
    return RenderSettings(
      numImages: int.tryParse(numImagesController.text) ?? 12,
      resolution: int.tryParse(resolutionController.text) ?? 256,
      azimuthAug: azimuthAug,
      elevationAug: elevationAug,
      modeMulti: modeMulti,
      modeStatic: modeStatic,
      modeFrontView: modeFrontView,
      modeFourView: modeFourView,
      onlyNorthernHemisphere: onlyNorthernHemisphere,
      separately: separately,
    );
  }

  /// Validate the form
  bool validate() {
    return formKey.currentState?.validate() ?? false;
  }

  /// Dispose of controllers
  void dispose() {
    numImagesController.dispose();
    resolutionController.dispose();
  }
}
