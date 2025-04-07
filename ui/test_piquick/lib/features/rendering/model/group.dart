// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:test_piquick/features/rendering/model/render_settings.dart';

class Group {
  final String name;
  final List<String> object_ids;
  final RenderSettings settings;

  Group({
    required this.name,
    required this.object_ids,
    required this.settings,
  });


  Group copyWith({
    String? name,
    List<String>? object_ids,
    RenderSettings? settings,
  }) {
    return Group(
      name: name ?? this.name,
      object_ids: object_ids ?? this.object_ids,
      settings: settings ?? this.settings,
    );
  }
}
