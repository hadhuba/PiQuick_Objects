import 'package:test_piquick/features/picker/model/object_groups_model.dart';
import 'package:test_piquick/features/rendering/model/render_settings.dart';

class RenderModel {
  final Map<String, RenderSettings> renderGroups;

  RenderModel({required this.renderGroups});

  static RenderModel fromObjects(ObjectGroups objects) {
    return RenderModel(
      renderGroups: {
        for (var group in objects.groups.entries)
          group.key: RenderSettings(
            numImages: 12,
            azimuthAug: true,
            elevationAug: false,
            resolution: 256,
            modeMulti: true,
            modeStatic: false,
            modeFrontView: false,
            modeFourView: false,
            engine: "CYCLES",
            onlyNorthernHemisphere: true,
          ),
      },
    );
  }

  RenderModel setGroupSetting(String groupName, RenderSettings settings) {
    return RenderModel(
      renderGroups: {
        ...renderGroups,
        groupName: settings,
      },
    );
  }

}
