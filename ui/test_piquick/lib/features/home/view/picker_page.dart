import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_piquick/core/widgets/loader.dart';
import 'package:test_piquick/features/home/viewModel/home_view_model.dart';

class PickerPage extends ConsumerStatefulWidget {
  const PickerPage({super.key});

  @override
  ConsumerState<PickerPage> createState() => _PickerPageState();
}

class _PickerPageState extends ConsumerState<PickerPage> {
  final Flutter3DController controller = Flutter3DController();

  @override
  void initState() {
    super.initState();
    controller.onModelLoaded.addListener(() {
      debugPrint('Model is loaded: ${controller.onModelLoaded.value}');
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final currentObj =
        ref.watch(homeViewModelProvider).viewer3DState.value?.currentObj;
    final currentAnimation =
        ref.watch(homeViewModelProvider).viewer3DState.value?.currentAnimation;
    final currentTexture =
        ref.watch(homeViewModelProvider).viewer3DState.value?.currentTexture;
    final isLoading =
        ref.watch(homeViewModelProvider).viewer3DState.isLoading == true;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 44, 20, 99),
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
                currentAnimation,
              );
              if (selectedAnimation != null) {
                ref
                    .read(homeViewModelProvider.notifier)
                    .updateAnimation(selectedAnimation);
                controller.playAnimation(animationName: currentAnimation);
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
                currentTexture,
              );
              if (selectedTexture != null) {
                ref
                    .read(homeViewModelProvider.notifier)
                    .updateTexture(selectedTexture);
                controller.setTexture(textureName: currentTexture ?? '');
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
          return isLoading
              ? const Loader()
              : Container(
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
                  key: ValueKey(currentObj),
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
                  src: currentObj!,
                ),
              );
        },
      ),
    );
  }
}
