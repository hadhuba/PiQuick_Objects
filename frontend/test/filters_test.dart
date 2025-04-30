import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/failure/failure.dart';
import 'package:frontend/features/filters/model/filter.dart';
import 'package:frontend/features/filters/model/repository/filter_repository.dart';
import 'package:frontend/features/filters/view/filters_page.dart';
import 'package:frontend/features/filters/viewModel/filters_view_model.dart';
import 'package:frontend/features/filters/viewModel/states/filters_state.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockFiltersRepository extends Mock implements FilterRepository {}

class FakeFiltersViewModel extends FiltersViewModel {
  final FiltersState Function() buildFn;

  FakeFiltersViewModel({required this.buildFn});

  @override
  FiltersState build() => buildFn();
}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  late MockHttpClient mockHttpClient;
  late FilterRepository repository;

  setUp(() {
    mockHttpClient = MockHttpClient();
    repository = FilterRepository();
  });
  group('FilterViewModel Test', () {
    test('initFilters sets filters on success', () async {
      final mockRepo = MockFiltersRepository();

      when(() => mockRepo.getFilterOptions()).thenAnswer(
        (_) async =>
            Right([Filter(type: "testFilter0"), Filter(type: "testFilter1")]),
      );

      when(() => mockRepo.getObjectsList()).thenAnswer((_) async => Right([]));

      final container = ProviderContainer(
        overrides: [filterRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      final viewModel = container.read(filtersViewModelProvider.notifier);
      await viewModel.initFilters();

      final state = container.read(filtersViewModelProvider);
      expect(
        state.filters.asData?.value,
        equals([Filter(type: "testFilter0"), Filter(type: "testFilter1")]),
      );
      expect(state.objectsList.asData?.value, equals([]));
    });

    test('initFilters sets error state on failure', () async {
      final mockRepo = MockFiltersRepository();

      when(
        () => mockRepo.getFilterOptions(),
      ).thenAnswer((_) async => Left(AppFailure('Network error')));

      when(
        () => mockRepo.getObjectsList(),
      ).thenAnswer((_) async => Left(AppFailure('Network error')));

      final container = ProviderContainer(
        overrides: [filterRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      final viewModel = container.read(filtersViewModelProvider.notifier);
      await viewModel.initFilters();

      final state = container.read(filtersViewModelProvider);
      expect(state.filters.hasError, isTrue);
      expect(state.objectsList.hasError, isTrue);
    });
  });

  group('FilterPage Test', () {
    testWidgets('Shows loading indicator when filters are loading', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          filtersViewModelProvider.overrideWith(
            () => FakeFiltersViewModel(
              buildFn:
                  () => FiltersState(
                    serverConnection: const AsyncValue.loading(),
                    filters: const AsyncValue.loading(),
                    objectsList: const AsyncValue.loading(),
                  ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: FiltersPage()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('FiltersPage shows filter list when data is loaded', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          filtersViewModelProvider.overrideWith(
            () => FakeFiltersViewModel(
              buildFn:
                  () => FiltersState(
                    serverConnection: const AsyncValue.data('Connected'),
                    filters: AsyncValue.data([Filter(type: "testFilter")]),
                    objectsList: AsyncValue.data([]),
                  ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: FiltersPage()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that the filter type is displayed
      expect(find.text('testFilter'), findsOneWidget);
    });

    testWidgets('FiltersPage shows error widget when loading fails', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          filtersViewModelProvider.overrideWith(
            () => FakeFiltersViewModel(
              buildFn:
                  () => FiltersState(
                    serverConnection: AsyncValue.error("error", StackTrace.current),
                    filters: AsyncValue.error("error", StackTrace.current),
                    objectsList: AsyncValue.error("error", StackTrace.current),
                  ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: FiltersPage()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that an error message is displayed
      expect(find.textContaining('error'), findsAtLeastNWidgets(1));
    });
  });
  group('FilterRepository Test', () {
    test('getFilterOptions returns filters on success', () async {
      final mockResponseData = {
        "filters": [
          {"type": "color", "min_value": null, "max_value": null},
          {"type": "size", "min_value": null, "max_value": null},
        ],
      };

      when(
        () => mockHttpClient.get(
          any(that: isA<Uri>()),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(mockResponseData), 200),
      );

      repository = FilterRepository(client: mockHttpClient);

      final Either<AppFailure, List<Filter>> result =
          await repository.getFilterOptions();

      // Példa assert:
      if (result is Left) {
        fail('Expected Right, got Left: ${(result as Left).value}');
      } else if (result is Right) {
        expect((result as Right).value.first.type, 'color');
      }
    });

    test('getFilterOptions returns failure on network error', () async {
      when(
        () => mockHttpClient.get(
          any(that: isA<Uri>()),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(Exception('Network error'));

      repository = FilterRepository(client: mockHttpClient);

      final result = await repository.getFilterOptions();

      expect(result is Left, isTrue);
      // Átírt assert:
      if (result is Left) {
        expect((result as Left).value, isA<AppFailure>());
      } else if (result is Right) {
        fail('Expected Left, got Right');
      }
    });

    test('getFilterOptions handles malformed JSON', () async {
      when(
        () => mockHttpClient.get(
          any(that: isA<Uri>()),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response('{invalid json}', 200));

      repository = FilterRepository(client: mockHttpClient);

      final result = await repository.getFilterOptions();

      expect(result is Left, isTrue);
      // Átírt assert:
      if (result is Left) {
        expect((result as Left).value, isA<AppFailure>());
      } else if (result is Right) {
        fail('Expected Left, got Right');
      }
    });

    test('getObjectsList returns objects list on success', () async {
      final mockResponseData = {
        "object_ids": ["1", "2"],
      };

      when(() => mockHttpClient.get(any())).thenAnswer(
        (_) async => http.Response(jsonEncode(mockResponseData), 200),
      );

      repository = FilterRepository(client: mockHttpClient);

      final result = await repository.getObjectsList();

      expect(result is Right, isTrue);
      // Átírt assert:
      if (result is Left) {
        fail('Expected Right, got Left: ${(result as Left).value}');
      } else if (result is Right) {
        expect((result as Right).value.length, 2);
      }
    });

    test('getObjectsList returns failure on 400', () async {
      when(
        () => mockHttpClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('{"detail":"Bad request"}', 400));

      repository = FilterRepository(client: mockHttpClient);

      final result = await repository.getObjectsList();

      expect(result is Left, isTrue);
      if (result is Left) {
        expect((result as Left).value, isA<AppFailure>());
      } else if (result is Right) {
        fail('Expected Left, got Right');
      }
    });
  });
}
