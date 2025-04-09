import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/core/constants/server_constants.dart';
import 'package:test_piquick/features/rendering/model/render_model.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

part 'render_remote_repository.g.dart';

@riverpod
RenderRemoteRepository renderRemoteRepository(RenderRemoteRepositoryRef ref) {
  return RenderRemoteRepository();
}

class RenderRemoteRepository {
  Future<File?> sendSettings(RenderModel renderModel) async {
    try {
      // Convert RenderModel to JSON
      final jsonBody = jsonEncode(renderModel.toJson());
      print(jsonBody);
      // Send POST request
      final response = await http.post(
        Uri.parse('${ServerConstants.serverUrl}/render/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonBody,
      );

      //TODO while the render gets completed we ask the user where to download

      // Check if the response is successful
      if (response.statusCode == 200) {
        // Ensure the directory exists
        final directory = Directory("test_piquick/assets/output/");
        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
        }

        // Define the path for the ZIP file
        final zipFilePath = '${directory.path}/rendered_output.zip';

        // Write the ZIP file to the specified directory
        final zipFile = File(zipFilePath);
        await zipFile.writeAsBytes(response.bodyBytes);

        return zipFile;
      } else {
        // Handle error response
        print(
          'Failed to send settings: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      // Handle exceptions
      print('Error sending settings: $e');
      return null;
    }
  }
}
