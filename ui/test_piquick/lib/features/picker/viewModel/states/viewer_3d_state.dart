class Viewer3DState {
  final String currentObj;
  final String? currentAnimation;
  final String? currentTexture;

  Viewer3DState({
    required this.currentObj,
    this.currentAnimation,
    this.currentTexture,
  });

  Viewer3DState copyWith({
    String? currentObj,
    String? currentAnimation,
    String? currentTexture,
  }) {
    return Viewer3DState(
      currentObj: currentObj ?? this.currentObj,
      currentAnimation: currentAnimation ?? this.currentAnimation,
      currentTexture: currentTexture ?? this.currentTexture,
    );
  }
}
