import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:piquick_objects/viewModels/render_view_model.dart';
import 'package:piquick_objects/model/render_model.dart';

class RenderView extends StatelessWidget {
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
        appBar: AppBar(title: Text('Render Settings')),
        body: Consumer<RenderViewModel>(
          builder: (context, viewModel, child) {
            return ListView(
              padding: EdgeInsets.all(16.0),
              children: [
                TextFormField(
                  initialValue: viewModel.numImages.toString(),
                  decoration: InputDecoration(labelText: 'Number of Images'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => viewModel.setNumImages(int.parse(value)),
                ),
                SwitchListTile(
                  title: Text('Azimuth Augmentation'),
                  value: viewModel.azimuthAug,
                  onChanged: (value) => viewModel.setAzimuthAug(value),
                ),
                SwitchListTile(
                  title: Text('Elevation Augmentation'),
                  value: viewModel.elevationAug,
                  onChanged: (value) => viewModel.setElevationAug(value),
                ),
                TextFormField(
                  initialValue: viewModel.resolution.toString(),
                  decoration: InputDecoration(labelText: 'Resolution'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => viewModel.setResolution(int.parse(value)),
                ),
                SwitchListTile(
                  title: Text('Mode Multi'),
                  value: viewModel.modeMulti,
                  onChanged: (value) => viewModel.setModeMulti(value),
                ),
                SwitchListTile(
                  title: Text('Mode Static'),
                  value: viewModel.modeStatic,
                  onChanged: (value) => viewModel.setModeStatic(value),
                ),
                SwitchListTile(
                  title: Text('Mode Front View'),
                  value: viewModel.modeFrontView,
                  onChanged: (value) => viewModel.setModeFrontView(value),
                ),
                SwitchListTile(
                  title: Text('Mode Four View'),
                  value: viewModel.modeFourView,
                  onChanged: (value) => viewModel.setModeFourView(value),
                ),
                TextFormField(
                  initialValue: viewModel.engine,
                  decoration: InputDecoration(labelText: 'Engine'),
                  onChanged: (value) => viewModel.setEngine(value),
                ),
                SwitchListTile(
                  title: Text('Only Northern Hemisphere'),
                  value: viewModel.onlyNorthernHemisphere,
                  onChanged: (value) => viewModel.setOnlyNorthernHemisphere(value),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    viewModel.saveSettings();
                  },
                  child: const Text('Save Settings'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Logic to send settings to server
                  },
                  child: const Text('Send settings to server'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    textStyle: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}