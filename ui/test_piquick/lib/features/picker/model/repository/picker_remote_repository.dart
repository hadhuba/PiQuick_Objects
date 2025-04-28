import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/core/constants/server_constants.dart';
import 'package:test_piquick/core/failure/failure.dart';
part 'picker_remote_repository.g.dart';

@riverpod
PickerRemoteRepository pickerRemoteRepository(Ref ref) {
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
