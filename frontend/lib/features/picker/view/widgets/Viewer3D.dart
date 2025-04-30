import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/picker/viewModel/picker_view_model.dart';

/// Interactive 3D model viewer that displays the currently selected object.
/// Supports model loading, texture switching, and provides visual feedback during loading.
class Viewer3D extends StatefulWidget {
  final Flutter3DController controller;
  final bool isLoading;
  final String? currentObj;
  final String? currentTexture;
  final WidgetRef ref;

  const Viewer3D({
    Key? key,
    required this.controller,
    required this.isLoading,
    required this.currentObj,
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
      // Model loaded event
    });
  }

  @override
  Widget build(BuildContext context) {
    // For textures
    bool isLoadingTexture = false;

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
                          color: Pallete.greyColor,
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
        title: Text(
          widget.currentObj != null
              ? widget.currentObj!.split("=").last
              : "3D Viewer",
          style: const TextStyle(color: Pallete.whiteColor),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () async {
              // Show loading indicator while fetching textures
              setState(() {
                isLoadingTexture = true;
              });

              try {
                List<String> availableTextures =
                    await controller.getAvailableTextures();

                // Loading complete
                setState(() {
                  isLoadingTexture = false;
                });

                String? selectedTexture = await showPickerDialog(
                  'Textures',
                  availableTextures,
                  widget.currentTexture,
                );

                if (selectedTexture != null) {
                  widget.ref
                      .read(pickerViewModelProvider.notifier)
                      .updateTexture(selectedTexture);

                  // Use the selected texture directly to avoid delay
                  controller.setTexture(textureName: selectedTexture);
                }
              } catch (e) {
                // Handle error and reset loading state
                setState(() {
                  isLoadingTexture = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error loading textures: ${e.toString()}'),
                  ),
                );
              }
            },
            icon:
                isLoadingTexture
                    // ignore: dead_code
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.list_alt_rounded),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Pallete.whiteColor, Pallete.greyColor],
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
              progressBarColor: Pallete.errorColor,
              enableTouch: true,
              onProgress: (double progressValue) {
                // Model loading progress
              },
              onLoad: (String modelAddress) {
                // Model loaded
              },
              onError: (String error) {
                // Model failed to load
              },
              controller: controller,
              src: widget.currentObj ?? 'frontend/assets/Astronaut.glb',
            ),
          );
        },
      ),
    );
  }
}
