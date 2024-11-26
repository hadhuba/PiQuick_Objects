import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
 
class Viewer3D extends StatefulWidget {
  final Flutter3DController controller; // 3D model vezérlő
  final Future<String?> Function(String title, List<String> inputList, [String? chosenItem]) showPickerDialog;
  String? chosenAnimation;
  String? chosenTexture;
  String obj;
  // Konstruktor, amely átadja a widget-nek az alapadatokat
  Viewer3D({
    Key? key,
    required this.controller,
    required this.showPickerDialog,
    required this.obj,
    required this.chosenAnimation,
    required this.chosenTexture
  }) : super(key: key);

  @override
  State<Viewer3D> createState() => _Viewer3DState();
}

class _Viewer3DState extends State<Viewer3D> {
  String? chosenAnimation;
  String? chosenTexture;
  String obj = 'assets/Astronaut.glb';

  @override
  void initState() {
    super.initState();
    // Kezdeti értékek beállítása, ha szükséges
    obj = 'assets/Astronaut.glb'; // Kezdeti modell elérési útja
    chosenAnimation = null; // Kezdeti animáció
    chosenTexture = null; // Kezdeti textúra
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff0d2039),
        title: const Text(
          "3D Viewer",
          style: TextStyle(color: Colors.white),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              widget.controller.playAnimation();
            },
            icon: const Icon(Icons.play_arrow),
          ),
          const SizedBox(height: 4),
          IconButton(
            onPressed: () {
              widget.controller.pauseAnimation();
            },
            icon: const Icon(Icons.pause),
          ),
          const SizedBox(height: 4),
          IconButton(
            onPressed: () {
              widget.controller.resetAnimation();
            },
            icon: const Icon(Icons.replay_circle_filled),
          ),
          const SizedBox(height: 4),
          IconButton(
            onPressed: () async {
              List<String> availableAnimations = await widget.controller.getAvailableAnimations();
              chosenAnimation = await widget.showPickerDialog(
                  'Animations', availableAnimations, chosenAnimation);
              widget.controller.playAnimation(animationName: chosenAnimation);
            },
            icon: const Icon(Icons.format_list_bulleted_outlined),
          ),
          const SizedBox(height: 4),
          IconButton(
            onPressed: () async {
              List<String> availableTextures = await widget.controller.getAvailableTextures();
              chosenTexture = await widget.showPickerDialog(
                  'Textures', availableTextures, chosenTexture);
              widget.controller.setTexture(textureName: chosenTexture ?? '');
              },
            icon: const Icon(Icons.list_alt_rounded),
          ),
          const SizedBox(height: 4),
          IconButton(
            onPressed: () {
              widget.controller.setCameraOrbit(20, 20, 5);
            },
            icon: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 4),
          IconButton(
            onPressed: () {
              widget.controller.resetCameraOrbit();
            },
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
        ],
      ),
      body: LayoutBuilder(
      builder: (context, constraints) {
        return Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color(0xffffffff),
              Colors.grey,
            ],
            stops: [0.1, 1.0],
            radius: 0.7,
            center: Alignment.center,
          ),
        ),
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        child: Flutter3DViewer(
          //If you pass 'true' the flutter_3d_controller will add gesture interceptor layer
          //to prevent gesture recognizers from malfunctioning on iOS and some Android devices.
          // the default value is true
          activeGestureInterceptor: true,
          //If you don't pass progressBarColor, the color of defaultLoadingProgressBar will be grey.
          //You can set your custom color or use [Colors.transparent] for hiding loadingProgressBar.
          progressBarColor: Colors.orange,
          //You can disable viewer touch response by setting 'enableTouch' to 'false'
          enableTouch: true,
          //This callBack will return the loading progress value between 0 and 1.0
          onProgress: (double progressValue) {
            debugPrint('model loading progress : $progressValue');
          },
          //This callBack will call after model loaded successfully and will return model address
          onLoad: (String modelAddress) {
            debugPrint('model loaded : $modelAddress');
          },
          //this callBack will call when model failed to load and will return failure error
          onError: (String error) {
            debugPrint('model failed to load : $error');
          },
          //You can have full control of 3d model animations, textures and camera
          controller: widget.controller,
          src:
              obj, //3D model with different animations
          //src: 'assets/sheen_chair.glb', //3D model with different textures
          //src: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb', // 3D model from URL
        ),
      );}
      )
    );
  }
}