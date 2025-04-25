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
          downloadFileWeb(response.bodyBytes, zipFileName);
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
        // JSON-ból kinyerjük a "detail" mezőt, ha van
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
