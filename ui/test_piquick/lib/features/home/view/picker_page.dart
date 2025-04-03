import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_piquick/core/theme/app_pallete.dart';
import 'package:test_piquick/core/widgets/loader.dart';
import 'package:test_piquick/features/filters/view/filters_page.dart';
import 'package:test_piquick/features/home/view/widgets/Viewer3D.dart';
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

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Viewer3D(
                  controller: controller,
                  isLoading: isLoading,
                  currentObj: currentObj,
                  currentAnimation: currentAnimation,
                  currentTexture: currentTexture,
                  ref: ref, // Pass ref to Viewer3D
                ),
              ),
              const SizedBox(height: 4),

              ElevatedButton(
                onPressed: () {
                  // Navigate to FiltersPage as a popup.
                  showDialog(
                    context: context,
                    builder: (context) => const FiltersPage(),
                  );
                },
                child: const Text('Go to Filters'),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
        Flexible(
          child: Column(
            children: [
              Flexible(
                child: Scaffold(
                  appBar: AppBar(title: const Text("Group List")),
                  body: ref
                      .watch(homeViewModelProvider)
                      .groupedObjects
                      .when(
                        data: (groupedObjects) {
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Logic to create a new group
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        TextEditingController
                                        groupNameController =
                                            TextEditingController();
                                        return AlertDialog(
                                          title: const Text('Create New Group'),
                                          content: TextField(
                                            controller: groupNameController,
                                            decoration: const InputDecoration(
                                              hintText: 'Enter group name',
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                final groupName =
                                                    groupNameController.text
                                                        .trim();
                                                if (groupName.isNotEmpty) {
                                                  ref
                                                      .read(
                                                        homeViewModelProvider
                                                            .notifier,
                                                      )
                                                      .newGroup(
                                                        groupname: groupName,
                                                      );
                                                  Navigator.of(context).pop();
                                                }
                                              },
                                              child: const Text('Create'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: const Text('Make New Group'),
                                ),
                              ),
                              Expanded(
                                child: ListView(
                                  children:
                                      groupedObjects.entries.map((entry) {
                                        String groupName = entry.key;
                                        List<String> items = entry.value;
                                        return ExpansionTile(
                                          title: Text(groupName),
                                          children:
                                              items.map((item) {
                                                return ListTile(
                                                  title: Row(
                                                    children: [
                                                      Expanded(
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            // saveObjToHistory(item);
                                                            ref
                                                                .read(
                                                                  homeViewModelProvider
                                                                      .notifier,
                                                                )
                                                                .updateObj(
                                                                  item,
                                                                );
                                                          },
                                                          child: Text(item),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons
                                                              .remove_circle_outline,
                                                          color: Colors.red,
                                                        ),
                                                        onPressed: () {
                                                          debugPrint(
                                                            'Remove button clicked for: $item',
                                                          );
                                                          ref
                                                              .read(
                                                                homeViewModelProvider
                                                                    .notifier,
                                                              )
                                                              .removeFromGroup(
                                                                groupname:
                                                                    groupName,
                                                                objectId: item,
                                                              );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                        );
                                      }).toList(),
                                ),
                              ),
                            ],
                          );
                        },
                        error: (error, stackTrace) {
                          return Center(child: Text('Error: $error'));
                        },
                        loading: () {
                          return const Center(child: Loader());
                        },
                      ),
                ),
              ),
              Flexible(
                child: Scaffold(
                  appBar: AppBar(title: const Text("Listed Objects")),
                  body: ref
                      .watch(homeViewModelProvider)
                      .objects
                      .when(
                        data:
                            (objects) => ListView.builder(
                              itemCount:
                                  ref
                                      .read(homeViewModelProvider)
                                      .objects
                                      .value
                                      ?.length ??
                                  0,
                              itemBuilder: (context, index) {
                                final file = objects[index];
                                return ListTile(
                                  title: Text(file),
                                  onTap: () {
                                    // saveObjToHistory(file);
                                    ref
                                        .read(homeViewModelProvider.notifier)
                                        .updateObj(file);
                                  },
                                );
                              },
                            ),
                        loading: () => Loader(),
                        error:
                            (error, stackTrace) =>
                                Center(child: Text('Error: $error')),
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
