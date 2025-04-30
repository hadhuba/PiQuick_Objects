import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils.dart';
import 'package:frontend/features/rendering/model/render_settings.dart';
import 'package:frontend/features/rendering/model/settings_form_model.dart';
import 'package:frontend/features/rendering/viewModel/settings_form_view_model.dart';

/// A form for configuring render settings for a group of objects
class RenderSettingsForm extends ConsumerStatefulWidget {
  const RenderSettingsForm({super.key, required this.viewModel});
  final SettingsFormViewModel viewModel;

  @override
  ConsumerState<RenderSettingsForm> createState() => _RenderSettingsFormState();
}

class _RenderSettingsFormState extends ConsumerState<RenderSettingsForm> {
  // @override
  // void didUpdateWidget(RenderSettingsForm oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   if (oldWidget.groupName != widget.groupName) {
  //     viewModel.dispose();
  //     viewModel = RenderSettingsFormController(
  //       viewModel: ref.read(renderViewModelProvider.notifier),
  //       groupName: widget.groupName,
  //     );
  //     setState(() {});
  //   }
  // }

  // Helper method to create hover-based tooltip widgets
  Widget _createSettingField({
    required String fieldId,
    required Widget child,
    required SettingsFormViewModel viewModel,
  }) {
    return MouseRegion(
      child: Tooltip(
        message: viewModel.getDescription(fieldId),
        waitDuration: const Duration(milliseconds: 500),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final viewModel = widget.viewModel;
    final viewModel = ref.watch(settingsFormViewModelProvider.notifier);
    // Force rebuild when download status changes
    return Column(
      children: [
        Expanded(
          child: Form(
            key: viewModel.formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _createSettingField(
                  fieldId: 'numImages',
                  child: TextFormField(
                    controller: viewModel.formModel.numImagesController,
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
                  viewModel: viewModel,
                ),
                _createSettingField(
                  fieldId: 'azimuthAug',
                  child: SwitchListTile(
                    title: Text(RenderSettings.getLabel('azimuthAug')),
                    value: viewModel.formModel.azimuthAug,
                    onChanged: (value) {
                      setState(() {
                        viewModel.formModel.azimuthAug = value;
                      });
                    },
                  ),
                  viewModel: viewModel,
                ),
                _createSettingField(
                  fieldId: 'elevationAug',
                  child: SwitchListTile(
                    title: Text(RenderSettings.getLabel('elevationAug')),
                    value: viewModel.formModel.elevationAug,
                    onChanged: (value) {
                      setState(() {
                        viewModel.formModel.elevationAug = value;
                      });
                    },
                  ),
                  viewModel: viewModel,
                ),
                _createSettingField(
                  fieldId: 'resolution',
                  child: DropdownButtonFormField<int>(
                    value: int.tryParse(
                      viewModel.formModel.resolutionController.text,
                    ),
                    decoration: InputDecoration(
                      labelText: RenderSettings.getLabel('resolution'),
                    ),
                    items:
                        SettingsFormModel.commonResolutions.map((resolution) {
                          return DropdownMenuItem<int>(
                            value: resolution,
                            child: Text(resolution.toString()),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        viewModel.formModel.resolutionController.text =
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
                  viewModel: viewModel,
                ),
                _createSettingField(
                  fieldId: 'modeMulti',
                  child: SwitchListTile(
                    title: Text(RenderSettings.getLabel('modeMulti')),
                    value: viewModel.formModel.modeMulti,
                    onChanged: (value) {
                      setState(() {
                        viewModel.formModel.modeMulti = value;
                      });
                    },
                  ),
                  viewModel: viewModel,
                ),
                _createSettingField(
                  fieldId: 'modeFrontView',
                  child: SwitchListTile(
                    title: Text(RenderSettings.getLabel('modeFrontView')),
                    value: viewModel.formModel.modeFrontView,
                    onChanged: (value) {
                      setState(() {
                        viewModel.formModel.modeFrontView = value;
                      });
                    },
                  ),
                  viewModel: viewModel,
                ),
                _createSettingField(
                  fieldId: 'modeFourView',
                  child: SwitchListTile(
                    title: Text(RenderSettings.getLabel('modeFourView')),
                    value: viewModel.formModel.modeFourView,
                    onChanged: (value) {
                      setState(() {
                        viewModel.formModel.modeFourView = value;
                      });
                    },
                  ),
                  viewModel: viewModel,
                ),
                _createSettingField(
                  fieldId: 'onlyNorthernHemisphere',
                  child: SwitchListTile(
                    title: Text(
                      RenderSettings.getLabel('onlyNorthernHemisphere'),
                    ),
                    value: viewModel.formModel.onlyNorthernHemisphere,
                    onChanged: (value) {
                      setState(() {
                        viewModel.formModel.onlyNorthernHemisphere = value;
                      });
                    },
                  ),
                  viewModel: viewModel,
                ),
                _createSettingField(
                  fieldId: 'separately',
                  child: SwitchListTile(
                    title: Text(RenderSettings.getLabel('separately')),
                    value: viewModel.formModel.separately,
                    onChanged: (value) {
                      setState(() {
                        viewModel.formModel.separately = value;
                      });
                    },
                  ),
                  viewModel: viewModel,
                ),
              ],
            ),
          ),
        ),
        _buildActionButtons(viewModel, context),
      ],
    );
  }

  Widget _buildActionButtons(
    SettingsFormViewModel viewModel,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () {
              viewModel.resetForm();
              setState(() {});
            },
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () {
              if (viewModel.saveSettings()) {
                showSnackBar(context, "Settings saved");
              }
            },
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}
