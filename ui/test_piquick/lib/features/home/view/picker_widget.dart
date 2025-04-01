import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_piquick/core/widgets/loader.dart';
import 'package:test_piquick/features/home/viewModel/home_view_model.dart';
import 'viewer_3d_widget.dart';

class PickerWidget extends ConsumerWidget {
  final Flutter3DController controller;

  const PickerWidget({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading =
        ref.watch(homeViewModelProvider).viewer3DState.isLoading == true;

    return Scaffold(
      body:
          isLoading
              ? Loader()
              : Viewer3DWidget(
                controller: controller,
                objectSrc: ref.watch(
                  homeViewModelProvider.select(
                    (state) => state.viewer3DState.value?.currentObj ?? '',
                  ),
                ),
                onProgress: (progress) => debugPrint('Progress: $progress'),
                onLoad: (model) => debugPrint('Model loaded: $model'),
                onError: (error) => debugPrint('Error: $error'),
              ),
    );
  }
}
