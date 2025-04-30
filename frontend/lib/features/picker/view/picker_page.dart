import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils.dart';
import 'package:frontend/core/widgets/loader.dart';
import 'package:frontend/features/picker/view/widgets/Viewer3D.dart';
import 'package:frontend/features/picker/view/widgets/custom_expansion_tile.dart';
import 'package:frontend/features/picker/view/widgets/custom_list_tile.dart';
import 'package:frontend/features/picker/viewModel/picker_view_model.dart';

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
        ref.watch(pickerViewModelProvider).viewer3DState.value?.currentObj;
    final currentTexture =
        ref.watch(pickerViewModelProvider).viewer3DState.value?.currentTexture;
    final isLoading =
        ref.watch(pickerViewModelProvider).viewer3DState.isLoading;

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
                  currentTexture: currentTexture,
                  ref: ref, // Pass ref to Viewer3D
                ),
              ),
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
                      .watch(pickerViewModelProvider)
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
                                            // Add onSubmitted to handle Enter key press
                                            onSubmitted: (value) {
                                              final groupName = value.trim();

                                              final errorMessage = ref
                                                  .read(
                                                    pickerViewModelProvider
                                                        .notifier,
                                                  )
                                                  .newGroup(
                                                    groupname: groupName,
                                                  );

                                              if (errorMessage == null) {
                                                Navigator.of(context).pop();
                                              } else {
                                                // Show error as snackbar
                                                showSnackBar(
                                                  context,
                                                  errorMessage,
                                                );
                                              }
                                            },
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
                                                final errorMessage = ref
                                                    .read(
                                                      pickerViewModelProvider
                                                          .notifier,
                                                    )
                                                    .newGroup(
                                                      groupname: groupName,
                                                    );

                                                if (errorMessage == null) {
                                                  Navigator.of(context).pop();
                                                } else {
                                                  // Show error as snackbar
                                                  showSnackBar(
                                                    context,
                                                    errorMessage,
                                                  );
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
                                child:
                                    groupedObjects.entries.isEmpty
                                        ? const Center(
                                          child: Text(
                                            'No groups available. Create a new group to get started!',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        )
                                        : ListView(
                                          children:
                                              groupedObjects.entries.map((
                                                entry,
                                              ) {
                                                String groupName = entry.key;
                                                List<String> items =
                                                    entry.value;
                                                return CustomExpansionTile(
                                                  // title: Text(groupName),
                                                  groupId: groupName,
                                                  selectedGroup:
                                                      ref
                                                          .read(
                                                            pickerViewModelProvider,
                                                          )
                                                          .selectedGroup,
                                                  onGroupSelected:
                                                      ref
                                                          .read(
                                                            pickerViewModelProvider
                                                                .notifier,
                                                          )
                                                          .selectGroup,
                                                  onRemove: () {
                                                    debugPrint(
                                                      'Remove button clicked for group: $groupName',
                                                    );
                                                    // Add logic to remove the entire group
                                                    ref
                                                        .read(
                                                          pickerViewModelProvider
                                                              .notifier,
                                                        )
                                                        .removeGroup(
                                                          groupname: groupName,
                                                        );
                                                  },
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
                                                                          pickerViewModelProvider
                                                                              .notifier,
                                                                        )
                                                                        .updateObj(
                                                                          item,
                                                                        );
                                                                  },
                                                                  child: Text(
                                                                    item,
                                                                  ),
                                                                ),
                                                              ),
                                                              IconButton(
                                                                icon: const Icon(
                                                                  Icons
                                                                      .remove_circle_outline,
                                                                  color:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                                onPressed: () {
                                                                  debugPrint(
                                                                    'Remove button clicked for: $item',
                                                                  );
                                                                  ref
                                                                      .read(
                                                                        pickerViewModelProvider
                                                                            .notifier,
                                                                      )
                                                                      .removeFromGroup(
                                                                        groupname:
                                                                            groupName,
                                                                        objectId:
                                                                            item,
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
                  appBar: AppBar(
                    title:
                    // const Text("Listed Objects")
                    ref
                        .read(pickerViewModelProvider)
                        .objects
                        .when(
                          data:
                              (objectsList) => Text(
                                'Objects (${objectsList.length})',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                          loading:
                              () => const Text(
                                'Objects (loading...)',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                          error:
                              (_, __) => const Text(
                                'Objects (error)',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                        ),
                  ),
                  body: ref
                      .watch(pickerViewModelProvider)
                      .objects
                      .when(
                        data:
                            (objects) =>
                                objects.isEmpty
                                    ? const Center(
                                      child: Text(
                                        'No objects found. Try updating your filters!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                    : ListView.builder(
                                      itemCount:
                                          ref
                                              .read(pickerViewModelProvider)
                                              .objects
                                              .value
                                              ?.length ??
                                          0,
                                      itemBuilder: (context, index) {
                                        final file = objects[index];
                                        // return ListTile(
                                        //   title: Text(file),
                                        //   onTap: () {
                                        //     // saveObjToHistory(file);
                                        //     ref
                                        //         .read(pickerViewModelProvider.notifier)
                                        //         .updateObj(file);
                                        //   },
                                        // );
                                        return CustomListTile(
                                          fileName: file,
                                          onAddToGroup: () {
                                            if (ref
                                                    .read(
                                                      pickerViewModelProvider,
                                                    )
                                                    .selectedGroup ==
                                                null) {
                                              showSnackBar(
                                                context,
                                                'Please select a group first',
                                              );
                                              return;
                                            }
                                            ref
                                                .read(
                                                  pickerViewModelProvider
                                                      .notifier,
                                                )
                                                .addToGroup(
                                                  file,
                                                ); //TODO not add multiple times
                                          },
                                          onTap: () {
                                            // saveObjToHistory(file);

                                            ref
                                                .read(
                                                  pickerViewModelProvider
                                                      .notifier,
                                                )
                                                .updateObj(file);
                                          },
                                        );
                                      },
                                    ),
                        loading: () => const Center(child: Loader()),
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
