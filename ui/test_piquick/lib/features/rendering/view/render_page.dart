import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_piquick/core/widgets/loader.dart';
import 'package:test_piquick/features/rendering/viewModel/render_view_model.dart';

class RenderPage extends ConsumerStatefulWidget {
  const RenderPage({super.key});

  @override
  ConsumerState<RenderPage> createState() => _RenderPageState();
}

class _RenderPageState extends ConsumerState<RenderPage> {
  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(renderViewModelProvider).renderModel.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Render Settings')),
      body: isLoading
          ? const Loader()
          : RenderSettingsForm(viewModel: ref.read(renderViewModelProvider.notifier)),
    );
  }
}

class RenderSettingsForm extends StatelessWidget {
  final RenderViewModel viewModel;

  const RenderSettingsForm({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final selectedGroup = viewModel.state.selectedGroup;
    if (selectedGroup == null) {
      return const Center(child: Text('No group selected.'));
    }

    final settings = viewModel.state.renderModel.whenData(
      (renderModel) => renderModel.renderGroups[selectedGroup],
    );

    if (settings == null) {
      return const Center(child: Text('No settings available for the selected group.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        TextFormField(
          initialValue: settings.numImages.toString(),
          decoration: const InputDecoration(labelText: 'Number of Images'),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final parsedValue = int.tryParse(value);
            if (parsedValue != null) {
              viewModel.setNumImages(parsedValue);
            }
          },
        ),
        SwitchListTile(
          title: const Text('Azimuth Augmentation'),
          value: settings.azimuthAug,
          onChanged: viewModel.setAzimuthAug,
        ),
        SwitchListTile(
          title: const Text('Elevation Augmentation'),
          value: settings.elevationAug,
          onChanged: viewModel.setElevationAug,
        ),
        TextFormField(
          initialValue: settings.resolution.toString(),
          decoration: const InputDecoration(labelText: 'Resolution'),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final parsedValue = int.tryParse(value);
            if (parsedValue != null) {
              viewModel.setResolution(parsedValue);
            }
          },
        ),
        SwitchListTile(
          title: const Text('Mode Multi'),
          value: settings.modeMulti,
          onChanged: viewModel.setModeMulti,
        ),
        SwitchListTile(
          title: const Text('Mode Static'),
          value: settings.modeStatic,
          onChanged: viewModel.setModeStatic,
        ),
        SwitchListTile(
          title: const Text('Mode Front View'),
          value: settings.modeFrontView,
          onChanged: viewModel.setModeFrontView,
        ),
        SwitchListTile(
          title: const Text('Mode Four View'),
          value: settings.modeFourView,
          onChanged: viewModel.setModeFourView,
        ),
        TextFormField(
          initialValue: settings.engine,
          decoration: const InputDecoration(labelText: 'Engine'),
          onChanged: viewModel.setEngine,
        ),
        SwitchListTile(
          title: const Text('Only Northern Hemisphere'),
          value: settings.onlyNorthernHemisphere,
          onChanged: viewModel.setOnlyNorthernHemisphere,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: viewModel.saveSettings,
          child: const Text('Save Settings'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            // Logic to send settings to server
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: const TextStyle(fontSize: 20),
          ),
          child: const Text('Send settings to server'),
        ),
      ],
    );
  }
}