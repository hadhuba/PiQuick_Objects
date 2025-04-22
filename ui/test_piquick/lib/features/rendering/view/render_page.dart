import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:test_piquick/core/utils.dart';
import 'package:test_piquick/core/widgets/loader.dart';
import 'package:test_piquick/features/rendering/model/render_settings.dart';
import 'package:test_piquick/features/rendering/viewModel/render_view_model.dart';

class RenderPage extends ConsumerStatefulWidget {
  const RenderPage({super.key});

  @override
  ConsumerState<RenderPage> createState() => _RenderPageState();
}

class _RenderPageState extends ConsumerState<RenderPage> {
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

class RenderSettingsForm extends ConsumerStatefulWidget {
  const RenderSettingsForm({super.key, required this.selectedGroup});
  final String selectedGroup;

  @override
  ConsumerState<RenderSettingsForm> createState() => _RenderSettingsFormState();
}

class _RenderSettingsFormState extends ConsumerState<RenderSettingsForm> {
  final formKey = GlobalKey<FormState>();

  // Controllers for form fields
  late TextEditingController numImagesController;
  late TextEditingController resolutionController;

  // Local state for boolean values
  late bool azimuthAug;
  late bool elevationAug;
  late bool modeMulti;
  late bool modeStatic;
  late bool modeFrontView;
  late bool modeFourView;
  late bool onlyNorthernHemisphere;
  late bool separately;
  late String engineValue;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(RenderSettingsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the selected group changes, reinitialize controllers
    if (oldWidget.selectedGroup != widget.selectedGroup) {
      _disposeControllers();
      _initControllers();
    }
  }

  void _initControllers() {
    final settings =
        ref
            .read(renderViewModelProvider)
            .renderModel
            .value
            ?.get(widget.selectedGroup)
            ?.settings;

    if (settings != null) {
      numImagesController = TextEditingController(
        text: settings.numImages.toString(),
      );
      resolutionController = TextEditingController(
        text: settings.resolution.toString(),
      );
      engineValue = settings.engine;

      azimuthAug = settings.azimuthAug;
      elevationAug = settings.elevationAug;
      modeMulti = settings.modeMulti;
      modeStatic = settings.modeStatic;
      modeFrontView = settings.modeFrontView;
      modeFourView = settings.modeFourView;
      onlyNorthernHemisphere = settings.onlyNorthernHemisphere;
      separately = settings.separately;
    } else {
      // Fallback to defaults
      numImagesController = TextEditingController(text: "12");
      resolutionController = TextEditingController(text: "256");
      engineValue = "CYCLES";

      azimuthAug = true;
      elevationAug = false;
      modeMulti = true;
      modeStatic = false;
      modeFrontView = false;
      modeFourView = false;
      onlyNorthernHemisphere = true;
      separately = true;
    }
  }

  void _disposeControllers() {
    numImagesController.dispose();
    resolutionController.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _saveSettings() {
    if (formKey.currentState?.validate() ?? false) {
      // Create a new RenderSettings object from form values
      final newSettings = RenderSettings(
        numImages: int.tryParse(numImagesController.text) ?? 12,
        resolution: int.tryParse(resolutionController.text) ?? 256,
        engine: engineValue,
        azimuthAug: azimuthAug,
        elevationAug: elevationAug,
        modeMulti: modeMulti,
        modeStatic: modeStatic,
        modeFrontView: modeFrontView,
        modeFourView: modeFourView,
        onlyNorthernHemisphere: onlyNorthernHemisphere,
        separately: separately,
      );

      // Send all settings to the viewModel at once
      ref
          .read(renderViewModelProvider.notifier)
          .updateGroupSettings(widget.selectedGroup, newSettings);

      // Show success message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloadStatus = ref.watch(renderViewModelProvider).downloadStatus;
    final downloadedFile = ref.watch(renderViewModelProvider).downloadedFile;

    return ref
        .watch(renderViewModelProvider)
        .renderModel
        .when(
          data: (renderModel) {
            final settings = renderModel.get(widget.selectedGroup)?.settings;

            if (settings == null) {
              return const Center(
                child: Text('No settings available for the selected group.'),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: Form(
                    key: formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        TextFormField(
                          controller: numImagesController,
                          decoration: const InputDecoration(
                            labelText: 'Number of Images',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a number';
                            }
                            final number = int.tryParse(value);
                            if (number == null) {
                              return 'Please enter a valid number';
                            }
                            if (number <= 0) {
                              return 'Number must be positive';
                            }
                            return null;
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Azimuth Augmentation'),
                          value: azimuthAug,
                          onChanged: (value) {
                            setState(() {
                              azimuthAug = value;
                            });
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Elevation Augmentation'),
                          value: elevationAug,
                          onChanged: (value) {
                            setState(() {
                              elevationAug = value;
                            });
                          },
                        ),
                        TextFormField(
                          controller: resolutionController,
                          decoration: const InputDecoration(
                            labelText: 'Resolution',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a resolution';
                            }
                            final number = int.tryParse(value);
                            if (number == null) {
                              return 'Please enter a valid number';
                            }
                            if (number <= 0) {
                              return 'Resolution must be positive';
                            }
                            return null;
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Mode Multi'),
                          value: modeMulti,
                          onChanged: (value) {
                            setState(() {
                              modeMulti = value;
                            });
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Mode Static'),
                          value: modeStatic,
                          onChanged: (value) {
                            setState(() {
                              modeStatic = value;
                            });
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Mode Front View'),
                          value: modeFrontView,
                          onChanged: (value) {
                            setState(() {
                              modeFrontView = value;
                            });
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Mode Four View'),
                          value: modeFourView,
                          onChanged: (value) {
                            setState(() {
                              modeFourView = value;
                            });
                          },
                        ),
                        DropdownButtonFormField<String>(
                          value: engineValue,
                          decoration: const InputDecoration(
                            labelText: 'Engine',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'CYCLES',
                              child: Text('CYCLES'),
                            ),
                            DropdownMenuItem(
                              value: 'BLENDER_EEVEE',
                              child: Text('BLENDER_EEVEE'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              engineValue = value ?? 'CYCLES';
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select an engine';
                            }
                            return null;
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Only Northern Hemisphere'),
                          value: onlyNorthernHemisphere,
                          onChanged: (value) {
                            setState(() {
                              onlyNorthernHemisphere = value;
                            });
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Separately'),
                          value: separately,
                          onChanged: (value) {
                            setState(() {
                              separately = value;
                            });
                          },
                        ),

                        // File Download Status & Controls
                        if (downloadStatus != null || !downloadedFile.isLoading)
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 16.0),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Rendering Status',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Download Status Text
                                  if (downloadStatus != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: Text(downloadStatus),
                                    ),

                                  // Loading Indicator
                                  if (downloadedFile.isLoading)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: LinearProgressIndicator(),
                                    ),

                                  // Download Complete - Show Open File Button or Web Message
                                  downloadedFile.when(
                                    data: (file) {
                                      if (kIsWeb) {
                                        // On web, we show a success message - download is handled by the browser
                                        if (downloadStatus?.contains(
                                              "Download initiated",
                                            ) ==
                                            true) {
                                          return Row(
                                            children: [
                                              const Expanded(
                                                child: Text(
                                                  'Your download has started. If it doesn\'t appear, check your browser\'s download folder.',
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(Icons.close),
                                                onPressed: () {
                                                  ref
                                                      .read(
                                                        renderViewModelProvider
                                                            .notifier,
                                                      )
                                                      .resetDownload();
                                                },
                                                tooltip: 'Dismiss',
                                              ),
                                            ],
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      } else {
                                        // On mobile/desktop, we provide a button to open the downloaded file
                                        if (file != null) {
                                          return Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  icon: const Icon(
                                                    Icons.file_open,
                                                  ),
                                                  label: const Text(
                                                    'Open Rendered Files',
                                                  ),
                                                  onPressed:
                                                      () => _openFile(file),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.green,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(Icons.close),
                                                onPressed: () {
                                                  ref
                                                      .read(
                                                        renderViewModelProvider
                                                            .notifier,
                                                      )
                                                      .resetDownload();
                                                },
                                                tooltip: 'Dismiss',
                                              ),
                                            ],
                                          );
                                        }
                                      }
                                      return const SizedBox.shrink();
                                    },
                                    error:
                                        (error, stackTrace) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Error: $error',
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  ref
                                                      .read(
                                                        renderViewModelProvider
                                                            .notifier,
                                                      )
                                                      .resetDownload();
                                                },
                                                child: const Text('Try Again'),
                                              ),
                                            ],
                                          ),
                                        ),
                                    loading: () => const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Reset form to initial values
                          _initControllers();
                          setState(() {});
                        },
                        child: const Text('Reset'),
                      ),
                      ElevatedButton(
                        onPressed: _saveSettings,
                        child: const Text('Save Settings'),
                      ),
                      ElevatedButton(
                        onPressed:
                            downloadedFile.isLoading
                                ? null // Disable button while downloading
                                : () {
                                  _saveSettings();
                                  ref
                                      .read(renderViewModelProvider.notifier)
                                      .sendSettings();
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Apply & Send to Server'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Loader(),
          error:
              (error, stack) =>
                  const Center(child: Text('Error loading settings')),
        );
  }

  Future<void> _openFile(File file) async {
    try {
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        // Show a message if the file couldn't be opened
        if (mounted) {
          showSnackBar(context, 'Could not open the file. ${result.message}');
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Error opening file: $e');
      }
    }
  }
}
