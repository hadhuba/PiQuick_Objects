import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:frontend/core/constants/server_constants.dart';
import 'package:frontend/core/failure/failure.dart';
import 'package:frontend/features/rendering/model/render_model.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/core/web_download_helper.dart';

part 'render_repository.g.dart';

/// Provider for the RenderRepository
@riverpod
RenderRepository renderRepository(Ref ref) {
  return RenderRepository();
}

/// Repository responsible for handling server communication related to rendering operations.
/// Manages sending render settings to the server and processing the resulting files.
class RenderRepository {
  /// Sends rendering settings to the server and processes the returned ZIP file.
  /// Returns either a File object pointing to the downloaded ZIP file or an AppFailure.
  Future<Either<AppFailure, File?>> sendSettings(
    RenderModel renderModel,
  ) async {
    try {
      final jsonBody = jsonEncode(renderModel.toJson());

      final response = await http.post(
        Uri.parse('${ServerConstants.serverUrl}/render/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonBody,
      );

      if (response.statusCode == 201) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final zipFileName = 'rendered_output_$timestamp.zip';

        if (kIsWeb) {
          downloadFile(response.bodyBytes, zipFileName);
          return Right(null);
        } else {
          // android, ios
          final directory = await getApplicationDocumentsDirectory();
          final outputDir = Directory('${directory.path}/rendered_outputs');

          if (!outputDir.existsSync()) {
            outputDir.createSync(recursive: true);
          }

          final zipFilePath = '${outputDir.path}/$zipFileName';
          final zipFile = File(zipFilePath);
          await zipFile.writeAsBytes(response.bodyBytes);

          return Right(zipFile);
        }
      } else {
        // Extract the "detail" field from the JSON response if available
        String errorMessage;
        try {
          final Map<String, dynamic> json = jsonDecode(response.body);
          errorMessage = json['detail'] as String? ?? response.body;
        } catch (_) {
          errorMessage = response.body;
        }
        return Left(AppFailure(errorMessage, response.statusCode));
      }
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}
