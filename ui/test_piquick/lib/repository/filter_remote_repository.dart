import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/core/constants/server_constants.dart';
import 'package:test_piquick/core/failure/failure.dart';
import 'package:test_piquick/model/3d_object.dart';
import 'package:test_piquick/model/filters_model.dart';

// Using a simple Either class since you seem to be using fpdart

part 'filter_remote_repository.g.dart';

@riverpod
FilterRemoteRepository filterRemoteRepository(
  FilterRemoteRepositoryRef ref,
) {
  return FilterRemoteRepository();
} 

class FilterRemoteRepository {
  Future<Either<AppFailure, List<ThreeDObject>>> applyFilters({
    required Filters filters,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ServerConstants.serverUrl}/filters/apply'),
        headers: {'Content-Type': 'application/json'},
        body: filters.toJson(),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode != 200) {
        return Left(
          AppFailure(responseBody['detail'] ?? 'Failed to apply filters'),
        );
      }

      // Assuming your API returns a list of object IDs as strings
      final List<dynamic> idsList = responseBody['object_ids'];
      final List<ThreeDObject> objectsList =
          idsList.map((id) => ThreeDObject(id: id.toString())).toList();

      return Right(objectsList);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // You can add more filter-related API methods here
  Future<Either<AppFailure, Map<String, dynamic>>> getFilterOptions() async {
    try {
      final response = await http.get(
        Uri.parse('${ServerConstants.serverUrl}/filters/options'),
        headers: {'Content-Type': 'application/json'},
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode != 200) {
        return Left(
          AppFailure(responseBody['detail'] ?? 'Failed to get filter options'),
        );
      }

      return Right(responseBody);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}
