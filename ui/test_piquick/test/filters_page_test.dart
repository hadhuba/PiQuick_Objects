import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_piquick/features/filters/model/filter.dart';
import 'package:test_piquick/features/filters/view/filters_page.dart';
import 'package:test_piquick/features/filters/viewModel/filters_view_model.dart';
import 'package:test_piquick/features/filters/viewModel/states/filters_state.dart';
import 'package:mocktail/mocktail.dart';

// Tesztelhető FiltersViewModel osztály létrehozása
class TestFiltersViewModel extends AutoDisposeNotifier<FiltersState>
    with Mock
    implements FiltersViewModel {
  @override
  FiltersState build() {
    return FiltersState(
      filters: const AsyncValue.data([]),
      objectsList: const AsyncValue.data([]),
    );
  }

  @override
  void updateFilter({required String type, num? minValue, num? maxValue}) {
    // Mock implementáció - ezt fogjuk verifikálni a tesztekben
  }

  @override
  Future<void> applyFilters() async {
    // Mock implementáció - ezt fogjuk verifikálni a tesztekben
  }
}

void main() {
  late TestFiltersViewModel testViewModel;

  setUp(() {
    testViewModel = TestFiltersViewModel();
    // Minden teszt előtt reseteljük a mock-ot
    reset(testViewModel);
  });

  group('FiltersPage Tests', () {
    testWidgets('should show loader when data is loading', (
      WidgetTester tester,
    ) async {
      // Arrange - A kezdeti állapotban betöltő indikátort mutat
      testViewModel.state = FiltersState(
        filters: const AsyncValue.loading(),
        objectsList: const AsyncValue.loading(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            filtersViewModelProvider.overrideWith(() => testViewModel),
          ],
          child: const MaterialApp(home: FiltersPage()),
        ),
      );

      // Act & Assert
      // Ellenőrizzük, hogy a betöltési indikátor megjelenik-e
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('should display filters list when data is loaded', (
      WidgetTester tester,
    ) async {
      // Arrange
      final mockFilters = [
        Filter(type: 'vertex_count', minValue: 100, maxValue: 1000),
        Filter(type: 'edge_count', minValue: 50, maxValue: 500),
      ];

      testViewModel.state = FiltersState(
        filters: AsyncValue.data(mockFilters),
        objectsList: const AsyncValue.data(['obj1.glb', 'obj2.glb']),
      );

      // Pumpolunk egy widget-et a mockolt provider-rel
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            filtersViewModelProvider.overrideWith(() => testViewModel),
          ],
          child: const MaterialApp(home: FiltersPage()),
        ),
      );

      await tester.pumpAndSettle();

      // Ellenőrizzük, hogy a szűrők megjelennek-e
      expect(find.text('vertex_count'), findsOneWidget);
      expect(find.text('edge_count'), findsOneWidget);

      // Ellenőrizzük, hogy az objektumok megjelennek-e
      expect(find.text('obj1.glb'), findsOneWidget);
      expect(find.text('obj2.glb'), findsOneWidget);
    });

    testWidgets(
      'should call applyFilters when Apply Filters button is pressed',
      (WidgetTester tester) async {
        // Arrange
        final mockFilters = [
          Filter(type: 'vertex_count', minValue: 100, maxValue: 1000),
        ];

        testViewModel.state = FiltersState(
          filters: AsyncValue.data(mockFilters),
          objectsList: const AsyncValue.data(['obj1.glb']),
        );

        // Mockoljuk az applyFilters metódus hívást
        when(() => testViewModel.applyFilters()).thenAnswer((_) async {});

        // Pumpolunk egy widget-et a mockolt provider-rel
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              filtersViewModelProvider.overrideWith(() => testViewModel),
            ],
            child: const MaterialApp(home: FiltersPage()),
          ),
        );

        await tester.pumpAndSettle();

        // Apply Filters gombra kattintás
        await tester.tap(find.text('Apply Filters'));
        await tester.pumpAndSettle();

        // Ellenőrizzük, hogy a metódus meghívódott-e
        verify(() => testViewModel.applyFilters()).called(1);
      },
    );

    testWidgets('should update filter values when text fields are changed', (
      WidgetTester tester,
    ) async {
      // Arrange
      final mockFilters = [
        Filter(type: 'vertex_count', minValue: 100, maxValue: 1000),
      ];

      testViewModel.state = FiltersState(
        filters: AsyncValue.data(mockFilters),
        objectsList: const AsyncValue.data(['obj1.glb']),
      );

      // Mockoljuk az updateFilter metódus hívást
      when(
        () => testViewModel.updateFilter(
          type: any(named: 'type'),
          minValue: any(named: 'minValue'),
          maxValue: any(named: 'maxValue'),
        ),
      ).thenAnswer((_) {});

      // Pumpolunk egy widget-et a mockolt provider-rel
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            filtersViewModelProvider.overrideWith(() => testViewModel),
          ],
          child: const MaterialApp(home: FiltersPage()),
        ),
      );

      await tester.pumpAndSettle();

      // Min érték mezőjének keresése és értékének megváltoztatása
      final minValueTextField = find.widgetWithText(TextFormField, '100');
      expect(minValueTextField, findsOneWidget);

      await tester.enterText(minValueTextField, '200');
      await tester.pumpAndSettle();

      // Ellenőrizzük, hogy az updateFilter metódus megfelelően hívódott-e meg
      verify(
        () => testViewModel.updateFilter(
          type: 'vertex_count',
          minValue: 200,
          maxValue: 1000,
        ),
      ).called(1);
    });
  });
}
