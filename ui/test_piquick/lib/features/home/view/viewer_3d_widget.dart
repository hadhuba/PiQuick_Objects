import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Viewer3DWidget extends ConsumerWidget {
  final Flutter3DController controller;
  final String objectSrc;
  final Function(double) onProgress;
  final Function(String) onLoad;
  final Function(String) onError;

  const Viewer3DWidget({
    Key? key,
    required this.controller,
    required this.objectSrc,
    required this.onProgress,
    required this.onLoad,
    required this.onError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
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
            key: ValueKey(objectSrc),
            activeGestureInterceptor: true,
            progressBarColor: Colors.red,
            enableTouch: true,
            onProgress: onProgress,
            onLoad: onLoad,
            onError: onError,
            controller: controller,
            src: objectSrc,
          ),
        );
      },
    );
  }
}