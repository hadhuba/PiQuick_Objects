import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/core/constants/server_constants.dart';
import 'package:test_piquick/core/failure/failure.dart';
import 'package:test_piquick/features/filters/model/3d_object.dart';
import 'package:test_piquick/features/filters/model/filter.dart';
import 'package:test_piquick/features/filters/model/filters_model.dart';

// Using a simple Either class since you seem to be using fpdart

part 'filter_remote_repository.g.dart';

@riverpod
FilterRemoteRepository filterRemoteRepository(FilterRemoteRepositoryRef ref) {
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

      // // Assuming your API returns a list of object IDs as strings
      // final List<dynamic> idsList = responseBody['object_ids'];
      // final List<ThreeDObject> objectsList =
      //     idsList.map((id) => ThreeDObject(id: id.toString())).toList();

      // Assuming your API returns a list of objects with "id" keys
      final List<dynamic> objectsDynamicList = responseBody['objects'];
      final List<ThreeDObject> objectsList =
          objectsDynamicList
              .map(
                (object) =>
                    ThreeDObject(id: (object as Map<String, dynamic>)['id']),
              )
              .toList();

      return Right(objectsList);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // You can add more filter-related API methods here
  Future<Either<AppFailure, Filters>> getFilterOptions() async {
    try {
      final response = await http.get(
        Uri.parse('${ServerConstants.serverUrl}/filters/options'),
        headers: {'Content-Type': 'application/json'},
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      final responseBody = jsonDecode(response.body);

      if (response.statusCode != 200) {
        return Left(
          AppFailure(responseBody['detail'] ?? 'Failed to get filter options'),
        );
      }

      final List<dynamic> filtersDynamicList = responseBody['filters'];
      final List<Filter> filtersList =
          filtersDynamicList
              .map((filter) => Filter.fromMap(filter as Map<String, dynamic>))
              .toList();

      // Wrap the filters list in a Filters object
      final Filters filters = Filters(filters: filtersList);

      return Right(filters);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}
