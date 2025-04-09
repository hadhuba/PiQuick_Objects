import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_piquick/core/utils.dart';
import 'package:test_piquick/core/widgets/loader.dart';
import 'package:test_piquick/features/rendering/viewModel/render_view_model.dart';

class RenderPage extends ConsumerStatefulWidget {
  const RenderPage({super.key});

  @override
  ConsumerState<RenderPage> createState() => _RenderPageState();
}

class _RenderPageState extends ConsumerState<RenderPage> {
  String? selectedGroup;

  @override
  Widget build(BuildContext context) {
    final modelAsync = ref.watch(renderViewModelProvider).renderModel;
    final selectedGroup = ref.watch(renderViewModelProvider).selectedGroup;

    return modelAsync.when(
      data: (data) {
        final groupNames = data.getAllNames();
        return Scaffold(
          appBar: AppBar(title: const Text('Render Settings')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButton<String>(
                  value: selectedGroup,
                  hint: const Text('Select a Group'),
                  items:
                      groupNames.map((groupName) {
                        return DropdownMenuItem<String>(
                          value: groupName,
                          child: Text(groupName),
                        );
                      }).toList(),
                  onChanged: (value) {
                    ref
                        .read(renderViewModelProvider.notifier)
                        .selectGroup(value);
                  },
                ),
                const SizedBox(height: 20),
                if (selectedGroup != null)
                  Expanded(
                    child: RenderSettingsForm(selectedGroup: selectedGroup),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // if (ref.read(renderViewModelProvider.notifier).isDone()) {
                    ref.read(renderViewModelProvider.notifier).sendSettings();
                    // } else {
                    //   showSnackBar(
                    //     context,
                    //     "Please complete all required fields",
                    //   );
                    // }
                  },
                  child: const Text('Save Settings'),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Loader()),
      error:
          (error, stack) =>
              const Scaffold(body: Center(child: Text('Hiba történt'))),
    );
  }
}

class RenderSettingsForm extends StatelessWidget {
  const RenderSettingsForm({super.key, required this.selectedGroup});
  final String selectedGroup;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return ref
            .read(renderViewModelProvider)
            .renderModel
            .when(
              data: (renderModel) {
                final settings =
                    renderModel.get(selectedGroup)!.settings; // TODO null

                if (settings == null) {
                  return const Center(
                    child: Text(
                      'No settings available for the selected group.',
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    TextFormField(
                      key: ValueKey('numImages_$selectedGroup'),
                      initialValue: settings.numImages.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Number of Images',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final parsedValue = int.tryParse(value);
                        if (parsedValue != null) {
                          ref
                              .read(renderViewModelProvider.notifier)
                              .setNumImages(parsedValue);
                        }
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Azimuth Augmentation'),
                      value: settings.azimuthAug,
                      onChanged:
                          ref
                              .read(renderViewModelProvider.notifier)
                              .setAzimuthAug,
                    ),
                    SwitchListTile(
                      title: const Text('Elevation Augmentation'),
                      value: settings.elevationAug,
                      onChanged:
                          ref
                              .read(renderViewModelProvider.notifier)
                              .setElevationAug,
                    ),
                    TextFormField(
                      key: ValueKey('resolution_$selectedGroup'),
                      initialValue: settings.resolution.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Resolution',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final parsedValue = int.tryParse(value);
                        if (parsedValue != null) {
                          ref
                              .read(renderViewModelProvider.notifier)
                              .setResolution(parsedValue);
                        }
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Mode Multi'),
                      value: settings.modeMulti,
                      onChanged:
                          ref
                              .read(renderViewModelProvider.notifier)
                              .setModeMulti,
                    ),
                    SwitchListTile(
                      title: const Text('Mode Static'),
                      value: settings.modeStatic,
                      onChanged:
                          ref
                              .read(renderViewModelProvider.notifier)
                              .setModeStatic,
                    ),
                    SwitchListTile(
                      title: const Text('Mode Front View'),
                      value: settings.modeFrontView,
                      onChanged:
                          ref
                              .read(renderViewModelProvider.notifier)
                              .setModeFrontView,
                    ),
                    SwitchListTile(
                      title: const Text('Mode Four View'),
                      value: settings.modeFourView,
                      onChanged:
                          ref
                              .read(renderViewModelProvider.notifier)
                              .setModeFourView,
                    ),
                    TextFormField(
                      key: ValueKey('engine_$selectedGroup'),
                      initialValue: settings.engine,
                      decoration: const InputDecoration(labelText: 'Engine'),
                      onChanged:
                          ref.read(renderViewModelProvider.notifier).setEngine,
                    ),
                    SwitchListTile(
                      title: const Text('Only Northern Hemisphere'),
                      value: settings.onlyNorthernHemisphere,
                      onChanged:
                          ref
                              .read(renderViewModelProvider.notifier)
                              .setOnlyNorthernHemisphere,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // ref
                        //     .read(renderViewModelProvider.notifier)
                        //     .setDone(selectedGroup);
                      },
                      child: const Text('Save Settings for group'),
                    ),
                  ],
                );
              },
              loading: () => const Loader(),
              error: (error, stack) => const Loader(),
            );
      },
    );
  }
}
