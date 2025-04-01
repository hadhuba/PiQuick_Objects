// import 'dart:convert';
// import 'package:fpdart/fpdart.dart';
// import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
// import 'package:test_piquick/core/constants/server_constants.dart';
// import 'package:test_piquick/core/failure/failure.dart';
// import 'package:test_piquick/features/filters/model/3d_object.dart';
// import 'package:test_piquick/features/filters/model/filter.dart';
// import 'package:test_piquick/features/filters/model/filters_model.dart';

part 'home_remote_repository.g.dart';

@riverpod
HomeRemoteRepository homeRemoteRepository(HomeRemoteRepositoryRef ref) {
  return HomeRemoteRepository();
}

class HomeRemoteRepository {
  void fetchThisObject(String newObj) {}

}