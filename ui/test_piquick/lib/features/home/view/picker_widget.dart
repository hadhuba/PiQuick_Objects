import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewModel/viewer_3d_view_model.dart';
import 'viewer_3d_widget.dart';

class PickerWidget extends ConsumerWidget {
  final Flutter3DController controller;

  const PickerWidget({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final objectSrc = ref.watch(viewer3DProvider);

    return Expanded(
      child: Viewer3DWidget(
        controller: controller,
        objectSrc: objectSrc,
        onProgress: (progress) => debugPrint('Progress: $progress'),
        onLoad: (model) => debugPrint('Model loaded: $model'),
        onError: (error) => debugPrint('Error: $error'),
      ),
    );
  }
} 
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     ref
      //         .read(viewer3DProvider.notifier)
      //         .updateObject('new_object_path.obj');
      //   },
      //   child: const Icon(Icons.refresh),
      // ),