import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/core/constants/server_constants.dart';
import 'package:test_piquick/core/failure/failure.dart';
part 'home_remote_repository.g.dart';

@riverpod
HomeRemoteRepository homeRemoteRepository(HomeRemoteRepositoryRef ref) {
  return HomeRemoteRepository();
}

class HomeRemoteRepository {
  Future<Either<AppFailure, bool>> fetchThisObject({
    required String newObj,
  }) async {
    try {
            // Construct the URL with the query parameter
      final url = Uri.parse('${ServerConstants.serverUrl}/picker/updateobj')
          .replace(queryParameters: {'newObj': newObj});

      // Make the HTTP POST request
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'}, // Content-Type updated
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode != 200) {
        return Left(
          AppFailure(responseBody['detail'] ?? 'Failed to fetch new object'),
        );
      }

      return Right(true);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}
