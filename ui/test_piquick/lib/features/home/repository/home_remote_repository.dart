import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/core/constants/server_constants.dart';
import 'package:test_piquick/core/failure/failure.dart';
import 'package:test_piquick/features/home/model/object_groups_model.dart';
part 'home_remote_repository.g.dart';

@riverpod
HomeRemoteRepository homeRemoteRepository(HomeRemoteRepositoryRef ref) {
  return HomeRemoteRepository();
}

class HomeRemoteRepository {
  Either<AppFailure, String> fetchThisObject({required String newObj}) {
    try {
      // Construct the URL with the query parameter
      final url =
          Uri.parse(
            '${ServerConstants.serverUrl}/picker/updateobj',
          ).replace(queryParameters: {'newObj': newObj}).toString();

      //check if obj is available
      // Make the HTTP POST request
      // final response = await http.post(
      //   url,
      //   headers: {'Content-Type': 'application/json'}, // Content-Type updated
      // );

      // final responseBody = jsonDecode(response.body);

      // if (response.statusCode != 200) {
      //   return Left(
      //     AppFailure(responseBody['detail'] ?? 'Failed to fetch new object'),
      //   );
      // }

      return Right(url);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, AsyncValue<List<String>>>> fetchObjects() async {
    try {
      // Skeleton code for an HTTP request
      final url = Uri.parse('${ServerConstants.serverUrl}/picker/objects');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Parse the response body (assuming it's a JSON array of strings)
        final List<String> objects = List<String>.from(
          jsonDecode(response.body) as List<dynamic>,
        );
        return Right(AsyncValue.data(objects));
      } else {
        // return Left(AppFailure('Failed to fetch objects: ${response.reasonPhrase}'));
        return Right(AsyncValue.data([]));
      }
    } catch (e) {
      // return Left(AppFailure(e.toString()));
      return Right(AsyncValue.data([])); // Return an empty list on error
    }
  }

  ObjectGroup fetchGroupedObjects() {
    // Return an empty ObjectGroup initially
    final emptyGroup = ObjectGroup(groups: {});

    // Skeleton code for fetching from an in-app repository
    // This could be a local database, shared preferences, or any other storage
    // try {
    //   // Example: Fetching from a hypothetical in-app repository
    //   final storedGroups = InAppRepository.getStoredGroups();
    //   if (storedGroups != null) {
    //     return storedGroups;
    //   }
    // } catch (e) {
    //   debugPrint('Error fetching grouped objects: $e');
    // }

    return emptyGroup;
  }
}
