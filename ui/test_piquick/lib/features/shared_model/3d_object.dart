// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ThreeDObject {
  final String id;
  late String? path;
  late bool? isSelected;

  ThreeDObject({required this.id, this.path, this.isSelected}) {
    path = 'assets/3d_objects/$id.glb';
    isSelected = false;
  }

  @override
  String toString() =>
      'ThreeDObject(id: $id, path: $path, isSelected: $isSelected)';

  String toJson() => id;

  ThreeDObject copyWith({String? id, String? path, bool? isSelected}) {
    return ThreeDObject(
      id: id ?? this.id,
      path: path ?? this.path,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
