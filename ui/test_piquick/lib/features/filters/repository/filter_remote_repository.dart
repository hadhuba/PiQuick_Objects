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

      // Assuming your API returns a list of object IDs as strings
      final List<dynamic> idsList = responseBody['object_ids'];
      final List<ThreeDObject> objectsList =
          idsList.map((id) => ThreeDObject(id: id.toString())).toList();

      return Right(objectsList);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  // Future<Either<AppFailure, Filters>> getFilterOptions() async {
  //   try {
  //     // Mocked example data
  //     final Map<String, dynamic> mockResponse = {
  //       "filters": [
  //         {"type": "vertex", "minValue": null, "maxValue": null},
  //         {"type": "bones", "minValue": null, "maxValue": null},
  //         {"type": "edges", "minValue": null, "maxValue": null},
  //         {"type": "poly", "minValue": null, "maxValue": null},
  //         {"type": "mesh", "minValue": null, "maxValue": null},
  //         {"type": "armature", "minValue": null, "maxValue": null},
  //       ],
  //     };

  //     // Simulate a delay to mimic network latency
  //     await Future.delayed(const Duration(milliseconds: 500));

  //     // Parse the mocked data into Filters
  //     final List<Filter> filtersList =
  //         mockResponse['filters']
  //             .map<Filter>(
  //               (filter) => Filter.fromMap(filter as Map<String, dynamic>),
  //             )
  //             .toList();

  //     final Filters filters = Filters(filters: filtersList);

  //     return Right(filters);
  //   } catch (e) {
  //     return Left(AppFailure(e.toString()));
  //   }
  // }

  // You can add more filter-related API methods here
  Future<Either<AppFailure, Filters>> getFilterOptions() async {
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

      final List<Filter> filtersList =
          responseBody['filters']
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
