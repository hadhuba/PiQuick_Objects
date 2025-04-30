// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:frontend/features/rendering/model/render_settings.dart';

/// Represents a group of 3D objects with specific rendering settings.
/// Contains group name, list of object IDs, and rendering configuration.
class Group {
  final String name;
  final List<String> objectIds;
  final RenderSettings settings;

  Group({required this.name, required this.objectIds, required this.settings});

  Group copyWith({
    String? name,
    List<String>? objectIds,
    RenderSettings? settings,
  }) {
    return Group(
      name: name ?? this.name,
      objectIds: objectIds ?? this.objectIds,
      settings: settings ?? this.settings,
    );
  }
}
