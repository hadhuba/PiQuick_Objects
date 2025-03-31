import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:piquick_objects/main.dart';
import 'objectNotifier.dart';
import 'package:provider/provider.dart';

class Viewer3D extends StatefulWidget {
  Viewer3D({Key? key}) : super(key: key); 

  @override
  State<Viewer3D> createState() => _Viewer3DState();
}

class _Viewer3DState extends State<Viewer3D> {

  Flutter3DController controller = Flutter3DController();

  @override
  void initState() {
    super.initState();
    controller.onModelLoaded.addListener(() {
      debugPrint('model is loaded : ${controller.onModelLoaded.value}');
    });
  }

  @override
  Widget build(BuildContext context) {

    final objectNotifier = context.watch<ObjectNotifier>();
    debugPrint('Viewer3D build called');

      Future<String?> showPickerDialog(String title, List<String> inputList, [String? chosenItem]) async {
        return await showModalBottomSheet<String>(
          context: context,
          builder: (ctx) {
            return SizedBox(
              height: 250,
              child: inputList.isEmpty
                  ? Center(
                      child: Text('$title list is empty'),
                    )
                  : ListView.separated(
                      itemCount: inputList.length,
                      padding: const EdgeInsets.only(top: 16),
                      itemBuilder: (ctx, index) {
                        return InkWell(
                          onTap: () {
                            Navigator.pop(context, inputList[index]);
                          },
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${index + 1}'),
                                Text(inputList[index]),
                                Icon(
                                  chosenItem == inputList[index]
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                )
                              ],
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (ctx, index) {
                        return const Divider(
                          color: Colors.grey,
                          thickness: 0.6,
                          indent: 10,
                          endIndent: 10,
                        );
                      },
                    ),
            );
          },
        );
      }
    
    return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 44, 20, 99),
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
                  controller.playAnimation();
                },
                icon: const Icon(Icons.play_arrow),
              ),
              const SizedBox(height: 4),
              IconButton(
                onPressed: () {
                  controller.pauseAnimation();
                },
                icon: const Icon(Icons.pause),
              ),
              const SizedBox(height: 4),
              IconButton(
                onPressed: () {
                  controller.resetAnimation();
                },
                icon: const Icon(Icons.replay_circle_filled),
              ),
              const SizedBox(height: 4),
              IconButton(
                onPressed: () async {
                  List<String> availableAnimations = await controller.getAvailableAnimations();
                  objectNotifier.updateAnimation( await showPickerDialog(
                      'Animations', availableAnimations, objectNotifier.currentAnimation));
                  controller.playAnimation(animationName: objectNotifier.currentAnimation);
                },
                icon: const Icon(Icons.format_list_bulleted_outlined),
              ),
              const SizedBox(height: 4),
              IconButton(
                onPressed: () async {
                  List<String> availableTextures = await controller.getAvailableTextures();
                  objectNotifier.updateTexture( await showPickerDialog(
                      'Textures', availableTextures, objectNotifier.currentTexture));
                  controller.setTexture(textureName: objectNotifier.currentTexture ?? '');
                  },
                icon: const Icon(Icons.list_alt_rounded),
              ),
              const SizedBox(height: 4),
              IconButton(
                onPressed: () {
                  controller.setCameraOrbit(20, 20, 5);
                },
                icon: const Icon(Icons.camera_alt),
              ),
              const SizedBox(height: 4),
              IconButton(
                onPressed: () {
                  controller.resetCameraOrbit();
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
              key: ValueKey(objectNotifier.currentObj),
              activeGestureInterceptor: true,
              progressBarColor: Colors.red,
              enableTouch: true,
              onProgress: (double progressValue) {
                debugPrint('model loading progress : $progressValue');
              },
              onLoad: (String modelAddress) {
                debugPrint('model loaded : $modelAddress');
              },
              onError: (String error) {
                debugPrint('model failed to load : $error');
              },
              controller: controller,
              src:
                  objectNotifier.currentObj,
            ),
          );}
          )
        );
    }
  }