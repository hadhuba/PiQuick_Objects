import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:frontend/core/constants/server_constants.dart';
import 'package:frontend/core/failure/failure.dart';
part 'picker_repository.g.dart';

@riverpod
PickerRepository pickerRepository(Ref ref) {
  return PickerRepository();
}

class PickerRepository {
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
