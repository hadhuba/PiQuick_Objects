import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/core/constants/server_constants.dart';
import 'package:test_piquick/core/failure/failure.dart';
import 'package:test_piquick/features/rendering/model/render_model.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:test_piquick/core/web_download_helper.dart';

part 'render_remote_repository.g.dart';

@riverpod
RenderRemoteRepository renderRemoteRepository(Ref ref) {
  return RenderRemoteRepository();
}

class RenderRemoteRepository {
  Future<Either<AppFailure, File?>> sendSettings(RenderModel renderModel) async {
    try {
      final jsonBody = jsonEncode(renderModel.toJson());
      print(jsonBody);

      final response = await http.post(
        Uri.parse('${ServerConstants.serverUrl}/render/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonBody,
      );

      if (response.statusCode == 201) {
        if (kIsWeb) {
          downloadFileWeb(response.bodyBytes, 'rendered_output.zip');
          return Right(null);
        } else {
          final directory = await getApplicationDocumentsDirectory();
          final outputDir = Directory('${directory.path}/rendered_outputs');

          if (!outputDir.existsSync()) {
            outputDir.createSync(recursive: true);
          }

          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final zipFilePath = '${outputDir.path}/rendered_output_$timestamp.zip';

          final zipFile = File(zipFilePath);
          await zipFile.writeAsBytes(response.bodyBytes);

          return Right(zipFile);
        }
      } else {
        return Left(AppFailure( 
          'Failed to send settings: ${response.statusCode} - ${response.body}',
        ));
      }
    } catch (e) {
      print('Error sending settings: $e');
      return Left(AppFailure(e.toString()));
    }
  }
}


//class RenderRemoteRepository {
//   Future<File?> sendSettings(RenderModel renderModel) async {
//     try {
//       // Convert RenderModel to JSON
//       final jsonBody = jsonEncode(renderModel.toJson());
//       print(jsonBody);
//       // Send POST request
//       final response = await http.post(
//         Uri.parse('${ServerConstants.serverUrl}/render/'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonBody,
//       );

//       // Check if the response is successful
//       if (response.statusCode == 201) {
//         // Get application documents directory
//         final directory = await getApplicationDocumentsDirectory();
//         final outputDir = Directory('${directory.path}/rendered_outputs');

//         // Ensure the directory exists
//         if (!outputDir.existsSync()) {
//           outputDir.createSync(recursive: true);
//         }

//         // Create a unique filename with timestamp
//         final timestamp = DateTime.now().millisecondsSinceEpoch;
//         final zipFilePath = '${outputDir.path}/rendered_output_$timestamp.zip';

//         // Write the ZIP file to the specified directory
//         final zipFile = File(zipFilePath);
//         await zipFile.writeAsBytes(response.bodyBytes);

//         return zipFile;
//       } else {
//         // Handle error response
//         print(
//           'Failed to send settings: ${response.statusCode} - ${response.body}',
//         );
//         return null;
//       }
//     } catch (e) {
//       // Handle exceptions
//       print('Error sending settings: $e');
//       return null;
//     }
//   }
// }
