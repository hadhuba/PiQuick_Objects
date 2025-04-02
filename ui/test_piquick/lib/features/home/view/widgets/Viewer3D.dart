import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_piquick/core/theme/app_pallete.dart';
import 'package:test_piquick/features/home/viewModel/home_view_model.dart';

class Viewer3D extends StatefulWidget {
  final Flutter3DController controller;
  final bool isLoading;
  final String? currentObj;
  final String? currentAnimation;
  final String? currentTexture;
  final WidgetRef ref; // Add ref to access Riverpod providers

  const Viewer3D({
    Key? key,
    required this.controller,
    required this.isLoading,
    required this.currentObj,
    required this.currentAnimation,
    required this.currentTexture,
    required this.ref,
  }) : super(key: key);

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
    debugPrint(widget.currentObj);

    Future<String?> showPickerDialog(
      String title,
      List<String> inputList, [
      String? chosenItem,
    ]) async {
      return await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) {
          return SizedBox(
            height: 250,
            child:
                inputList.isEmpty
                    ? Center(child: Text('$title list is empty'))
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
                                ),
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
        backgroundColor: Pallete.objectBackgroundColor,
        title: const Text("3D Viewer", style: TextStyle(color: Colors.white)),
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
              List<String> availableAnimations =
                  await controller.getAvailableAnimations();
              String? selectedAnimation = await showPickerDialog(
                'Animations',
                availableAnimations,
                widget.currentAnimation,
              );
              if (selectedAnimation != null) {
                widget.ref
                    .read(homeViewModelProvider.notifier)
                    .updateAnimation(selectedAnimation);
                controller.playAnimation(
                  animationName: widget.currentAnimation,
                );
              }
            },
            icon: const Icon(Icons.format_list_bulleted_outlined),
          ),
          const SizedBox(height: 4),
          IconButton(
            onPressed: () async {
              List<String> availableTextures =
                  await controller.getAvailableTextures();
              String? selectedTexture = await showPickerDialog(
                'Textures',
                availableTextures,
                widget.currentTexture,
              );
              if (selectedTexture != null) {
                widget.ref
                    .read(homeViewModelProvider.notifier)
                    .updateTexture(selectedTexture);
                controller.setTexture(textureName: widget.currentTexture ?? '');
              }
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
          return
          // isLoading
          //     ? const Loader():
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Color(0xffffffff), Colors.grey],
                stops: [0.1, 1.0],
                radius: 0.7,
                center: Alignment.center,
              ),
            ),
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Flutter3DViewer(
              key: ValueKey(widget.currentObj),
              activeGestureInterceptor: true,
              progressBarColor: Colors.red,
              enableTouch: true,
              onProgress: (double progressValue) {
                debugPrint('Model loading progress: $progressValue');
              },
              onLoad: (String modelAddress) {
                debugPrint('Model loaded: $modelAddress');
              },
              onError: (String error) {
                debugPrint('Model failed to load: $error');
              },
              controller: controller,
              src: widget.currentObj ?? 'ui/test_piquick/assets/Astronaut.glb',
            ),
          );
        },
      ),
    );
  }
}
