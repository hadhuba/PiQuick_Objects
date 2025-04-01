import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_piquick/features/rendering/viewModel/render_view_model.dart';
import 'package:test_piquick/features/rendering/model/render_model.dart';

class RenderPage extends StatelessWidget {
  const RenderPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RenderViewModel(RenderModel(
        numImages: 12,
        azimuthAug: true,
        elevationAug: false,
        resolution: 256,
        modeMulti: true,
        modeStatic: false,
        modeFrontView: false,
        modeFourView: false,
        engine: "CYCLES",
        onlyNorthernHemisphere: true,
      )),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Render Settings'),
        ),
        body: const RenderSettingsForm(),
      ),
    );
  }
}

class RenderSettingsForm extends StatelessWidget {
  const RenderSettingsForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<RenderViewModel>(context);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        TextFormField(
          initialValue: viewModel.numImages.toString(),
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
          value: viewModel.azimuthAug,
          onChanged: viewModel.setAzimuthAug,
        ),
        SwitchListTile(
          title: const Text('Elevation Augmentation'),
          value: viewModel.elevationAug,
          onChanged: viewModel.setElevationAug,
        ),
        TextFormField(
          initialValue: viewModel.resolution.toString(),
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
          value: viewModel.modeMulti,
          onChanged: viewModel.setModeMulti,
        ),
        SwitchListTile(
          title: const Text('Mode Static'),
          value: viewModel.modeStatic,
          onChanged: viewModel.setModeStatic,
        ),
        SwitchListTile(
          title: const Text('Mode Front View'),
          value: viewModel.modeFrontView,
          onChanged: viewModel.setModeFrontView,
        ),
        SwitchListTile(
          title: const Text('Mode Four View'),
          value: viewModel.modeFourView,
          onChanged: viewModel.setModeFourView,
        ),
        TextFormField(
          initialValue: viewModel.engine,
          decoration: const InputDecoration(labelText: 'Engine'),
          onChanged: viewModel.setEngine,
        ),
        SwitchListTile(
          title: const Text('Only Northern Hemisphere'),
          value: viewModel.onlyNorthernHemisphere,
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