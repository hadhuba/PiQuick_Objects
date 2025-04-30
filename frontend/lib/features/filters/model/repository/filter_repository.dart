import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:frontend/core/constants/server_constants.dart';
import 'package:frontend/core/failure/failure.dart';
import 'package:frontend/features/filters/model/filter.dart';

part 'filter_repository.g.dart';

@riverpod
FilterRepository filterRepository(Ref ref) {
  return FilterRepository();
}

class FilterRepository {
  late http.Client client;

  FilterRepository({http.Client? client}) : client = client ?? http.Client();

    void resetClient() {
    client.close();
    client = http.Client();
  }

  Future<Either<AppFailure, List<String>>> applyFilters({
    required List<Filter> filters,
  }) async {
    try {
      if (filters.isEmpty || filters.every((filter) => filter.minValue == null && filter.maxValue == null)) {
        return await getObjectsList(); // Return an empty list if no filters are provided or all min and max values are null
      }
      final Map<String, dynamic> filtersJson = {
        "filters": filters.map((filter) => filter.toMap()).toList(),
      };

      final response = await client
          .post(
            Uri.parse('${ServerConstants.serverUrl}/filters/apply'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(filtersJson),
          )
          .timeout(const Duration(seconds: 20));

      final responseBody = jsonDecode(response.body);

      if (response.statusCode != 200) {
        return Left(
          AppFailure(responseBody['detail'] ?? 'Failed to apply filters'),
        );
      }

      final List<dynamic> idsList = responseBody['object_ids'];
      final List<String> objectsList =
          idsList.map((id) => id.toString()).toList();

      return Right(objectsList);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, List<Filter>>> getFilterOptions() async {
    try {
      final response = await client
          .get(
            Uri.parse('${ServerConstants.serverUrl}/filters/options'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

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

      return Right(filtersList);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, List<String>>> getObjectsList() async {
    try {
      final response = await client
          .get(Uri.parse('${ServerConstants.serverUrl}/filters/allobjects'), 
          )
          .timeout(const Duration(seconds: 20));

      final responseBody = jsonDecode(response.body);

      if (response.statusCode != 200) {
        return Left(
          AppFailure(responseBody['detail'] ?? 'Failed to fetch objects list'),
        );
      }

      // Assuming your API returns a list of object IDs as strings
      final List<dynamic> idsList = responseBody['object_ids'];
      final List<String> objectsList =
          idsList.map((id) => id.toString()).toList();

      return Right(objectsList);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}
