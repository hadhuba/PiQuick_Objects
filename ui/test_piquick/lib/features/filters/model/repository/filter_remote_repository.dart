import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:test_piquick/core/constants/server_constants.dart';
import 'package:test_piquick/core/failure/failure.dart';
import 'package:test_piquick/features/filters/model/filter.dart';

// Using a simple Either class since you seem to be using fpdart

part 'filter_remote_repository.g.dart';

@riverpod
FilterRemoteRepository filterRemoteRepository(Ref ref) {
  return FilterRemoteRepository();
}

class FilterRemoteRepository {
  Future<Either<AppFailure, List<String>>> applyFilters({
    required List<Filter> filters,
  }) async {
    try {
      final Map<String, dynamic> filtersJson = {
        "filters": filters.map((filter) => filter.toMap()).toList(),
      };

      final response = await http.post(
        Uri.parse('${ServerConstants.serverUrl}/filters/apply'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(filtersJson),
      );

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

  // You can add more filter-related API methods here
  Future<Either<AppFailure, List<Filter>>> getFilterOptions() async {
    try {
      final response = await http.get(
        Uri.parse('${ServerConstants.serverUrl}/filters/options'),
        headers: {'Content-Type': 'application/json'},
      );
      print('Response status: ${response.statusCode}');
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
      // final Filters filters = Filters(filters: filtersList);

      return Right(filtersList);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, List<String>>> getObjectsList() async {
    try {
      final response = await http.get(
        Uri.parse('${ServerConstants.serverUrl}/filters/allobjects'),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode != 200) {
        print(responseBody['detail'] ?? 'Failed to get objects list');
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
