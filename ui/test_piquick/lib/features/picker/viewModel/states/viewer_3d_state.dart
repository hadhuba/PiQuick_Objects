class Viewer3DState {
  final String currentObj;
  final String? currentTexture;

  Viewer3DState({required this.currentObj, this.currentTexture});

  Viewer3DState copyWith({String? currentObj, String? currentTexture}) {
    return Viewer3DState(
      currentObj: currentObj ?? this.currentObj,
      currentTexture: currentTexture ?? this.currentTexture,
    );
  }
}
