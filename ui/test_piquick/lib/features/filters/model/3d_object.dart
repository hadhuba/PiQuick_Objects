class ThreeDObject {
  final String id;
  late String path;
  late bool isSelected;

  ThreeDObject({required this.id}) {
    path = 'assets/3d_objects/$id.glb';
    isSelected = false;
  }

  @override
  String toString() {
    return '3DObject(id: $id, path: $path, isSelected: $isSelected)';
  }
}
