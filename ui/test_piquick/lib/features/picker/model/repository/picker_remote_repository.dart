import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/core/constants/server_constants.dart';
import 'package:test_piquick/core/failure/failure.dart';
import 'package:test_piquick/features/picker/model/object_groups_model.dart';
part 'picker_remote_repository.g.dart';

@riverpod
PickerRemoteRepository pickerRemoteRepository(PickerRemoteRepositoryRef ref) {
  return PickerRemoteRepository();
}

class PickerRemoteRepository {
  Either<AppFailure, String> hostThisObject({required String newObj}) {
    try {
      // Construct the URL with the query parameter
      final url =
          Uri.parse(
            '${ServerConstants.serverUrl}/picker/updateobj',
          ).replace(queryParameters: {'newObj': newObj}).toString();
      return Right(url);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}
