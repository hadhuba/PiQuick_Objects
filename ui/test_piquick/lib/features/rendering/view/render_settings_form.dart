import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:test_piquick/core/utils.dart';
import 'package:test_piquick/core/widgets/loader.dart';
import 'package:test_piquick/features/rendering/controller/render_settings_form_controller.dart';
import 'package:test_piquick/features/rendering/model/render_settings.dart';
import 'package:test_piquick/features/rendering/model/render_settings_form_model.dart';
import 'package:test_piquick/features/rendering/viewModel/render_view_model.dart';

/// A form for configuring render settings for a group of objects
class RenderSettingsForm extends ConsumerStatefulWidget {
  const RenderSettingsForm({super.key, required this.groupName});
  final String groupName;

  @override
  ConsumerState<RenderSettingsForm> createState() => _RenderSettingsFormState();
}

class _RenderSettingsFormState extends ConsumerState<RenderSettingsForm> {
  late RenderSettingsFormController controller;

  @override
  void initState() {
    super.initState();
    controller = RenderSettingsFormController(
      viewModel: ref.read(renderViewModelProvider.notifier),
      groupName: widget.groupName,
    );
  }

  @override
  void didUpdateWidget(RenderSettingsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupName != widget.groupName) {
      controller.dispose();
      controller = RenderSettingsFormController(
        viewModel: ref.read(renderViewModelProvider.notifier),
        groupName: widget.groupName,
      );
      setState(() {});
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // Helper method to create hover-based tooltip widgets
  Widget _createSettingField({required String fieldId, required Widget child}) {
    return MouseRegion(
      child: Tooltip(
        message: RenderSettings.getDescription(fieldId),
        waitDuration: const Duration(milliseconds: 500),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Force rebuild when download status changes
    final downloadStatus = ref.watch(
      renderViewModelProvider.select((state) => state.downloadStatus),
    );
    final downloadedFile = ref.watch(
      renderViewModelProvider.select((state) => state.downloadedFile),
    );

    return ref
        .watch(renderViewModelProvider)
        .renderModel
        .when(
          data: (_) {
            return Column(
              children: [
                Expanded(
                  child: Form(
                    key: controller.formModel.formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        _createSettingField(
                          fieldId: 'numImages',
                          child: TextFormField(
                            controller:
                                controller.formModel.numImagesController,
                            decoration: InputDecoration(
                              labelText: RenderSettings.getLabel('numImages'),
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
                        ),
                        _createSettingField(
                          fieldId: 'azimuthAug',
                          child: SwitchListTile(
                            title: Text(RenderSettings.getLabel('azimuthAug')),
                            value: controller.formModel.azimuthAug,
                            onChanged: (value) {
                              setState(() {
                                controller.formModel.azimuthAug = value;
                              });
                            },
                          ),
                        ),
                        _createSettingField(
                          fieldId: 'elevationAug',
                          child: SwitchListTile(
                            title: Text(
                              RenderSettings.getLabel('elevationAug'),
                            ),
                            value: controller.formModel.elevationAug,
                            onChanged: (value) {
                              setState(() {
                                controller.formModel.elevationAug = value;
                              });
                            },
                          ),
                        ),
                        _createSettingField(
                          fieldId: 'resolution',
                          child: DropdownButtonFormField<int>(
                            value: int.tryParse(
                              controller.formModel.resolutionController.text,
                            ),
                            decoration: InputDecoration(
                              labelText: RenderSettings.getLabel('resolution'),
                            ),
                            items:
                                RenderSettingsFormModel.commonResolutions.map((
                                  resolution,
                                ) {
                                  return DropdownMenuItem<int>(
                                    value: resolution,
                                    child: Text(resolution.toString()),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                controller.formModel.resolutionController.text =
                                    value?.toString() ?? "256";
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a resolution';
                              }
                              return null;
                            },
                          ),
                        ),
                        _createSettingField(
                          fieldId: 'modeMulti',
                          child: SwitchListTile(
                            title: Text(RenderSettings.getLabel('modeMulti')),
                            value: controller.formModel.modeMulti,
                            onChanged: (value) {
                              setState(() {
                                controller.formModel.modeMulti = value;
                              });
                            },
                          ),
                        ),
                        _createSettingField(
                          fieldId: 'modeStatic',
                          child: SwitchListTile(
                            title: Text(RenderSettings.getLabel('modeStatic')),
                            value: controller.formModel.modeStatic,
                            onChanged: (value) {
                              setState(() {
                                controller.formModel.modeStatic = value;
                              });
                            },
                          ),
                        ),
                        _createSettingField(
                          fieldId: 'modeFrontView',
                          child: SwitchListTile(
                            title: Text(
                              RenderSettings.getLabel('modeFrontView'),
                            ),
                            value: controller.formModel.modeFrontView,
                            onChanged: (value) {
                              setState(() {
                                controller.formModel.modeFrontView = value;
                                controller.formModel.updateImagesForViewMode();
                              });
                            },
                          ),
                        ),
                        _createSettingField(
                          fieldId: 'modeFourView',
                          child: SwitchListTile(
                            title: Text(
                              RenderSettings.getLabel('modeFourView'),
                            ),
                            value: controller.formModel.modeFourView,
                            onChanged: (value) {
                              setState(() {
                                controller.formModel.modeFourView = value;
                                controller.formModel.updateImagesForViewMode();
                              });
                            },
                          ),
                        ),
                        _createSettingField(
                          fieldId: 'engine',
                          child: DropdownButtonFormField<String>(
                            value: controller.formModel.engineValue,
                            decoration: InputDecoration(
                              labelText: RenderSettings.getLabel('engine'),
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
                                controller.formModel.engineValue =
                                    value ?? 'CYCLES';
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select an engine';
                              }
                              return null;
                            },
                          ),
                        ),
                        _createSettingField(
                          fieldId: 'onlyNorthernHemisphere',
                          child: SwitchListTile(
                            title: Text(
                              RenderSettings.getLabel('onlyNorthernHemisphere'),
                            ),
                            value: controller.formModel.onlyNorthernHemisphere,
                            onChanged: (value) {
                              setState(() {
                                controller.formModel.onlyNorthernHemisphere =
                                    value;
                              });
                            },
                          ),
                        ),
                        _createSettingField(
                          fieldId: 'separately',
                          child: SwitchListTile(
                            title: Text(RenderSettings.getLabel('separately')),
                            value: controller.formModel.separately,
                            onChanged: (value) {
                              setState(() {
                                controller.formModel.separately = value;
                              });
                            },
                          ),
                        ),

                        // File Download Status & Controls
                        if (downloadStatus != null || downloadedFile.isLoading)
                          _buildDownloadStatusCard(),
                      ],
                    ),
                  ),
                ),
                _buildActionButtons(),
              ],
            );
          },
          loading: () => const Loader(),
          error:
              (error, stack) =>
                  const Center(child: Text('Error loading settings')),
        );
  }

  Widget _buildDownloadStatusCard() {
    final downloadedFile = ref.watch(renderViewModelProvider).downloadedFile;
    final downloadStatus = controller.getDownloadStatus();
    final isDownloading = controller.isDownloading();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rendering Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // Download Status Text
            if (downloadStatus != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(downloadStatus),
              ),

            // Loading Indicator
            if (isDownloading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(),
              ),

            // Download Complete - Show Open File Button or Web Message
            downloadedFile.when(
              data: (file) {
                if (kIsWeb) {
                  // On web, we show a success message - download is handled by the browser
                  if (downloadStatus?.contains("Download initiated") == true) {
                    return Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Your download has started. If it doesn\'t appear, check your browser\'s download folder.',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => controller.resetDownload(),
                          tooltip: 'Dismiss',
                        ),
                      ],
                    );
                  }

                  // Handle non-201 status code errors
                  if (downloadStatus?.contains("Error") == true) {
                    return Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'An error occurred during the download. Please try again.',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => controller.resetDownload(),
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
                            icon: const Icon(Icons.file_open),
                            label: const Text('Open Rendered Files'),
                            onPressed: () => _openFile(file),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => controller.resetDownload(),
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
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Error: ${controller.getDownloadError()}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        ElevatedButton(
                          onPressed: () => controller.resetDownload(),
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
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () {
              controller.resetForm();
              setState(() {});
            },
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.saveSettings()) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Settings saved')));
              }
            },
            child: const Text('Save Settings'),
          ),
          ElevatedButton(
            onPressed:
                controller.isDownloading()
                    ? null // Disable button while downloading
                    : () => controller.saveAndSendSettings(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply & Send to Server'),
          ),
        ],
      ),
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
