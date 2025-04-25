import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_piquick/features/picker/view/picker_page.dart';
import 'package:test_piquick/features/picker/viewModel/picker_view_model.dart';
import 'package:mocktail/mocktail.dart';

// Mock osztály létrehozása a PickerViewModel-hez
class MockPickerViewModel extends Mock implements PickerViewModel {}

void main() {
  group('PickerPage Widget Tests', () {
    testWidgets('should render PickerPage with main components', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: PickerPage())),
      );

      // Wait for async operations
      await tester.pumpAndSettle();

      // Assert - Ellenőrizzük a főbb UI elemek megjelenését
      // A tényleges UI elemek alapján módosítsd ezeket
      expect(find.byType(Row), findsOneWidget); // A fő elrendezés Row

      // Teszteljük a "Go to Filters" gomb jelenlétét
      expect(find.text('Go to Filters'), findsOneWidget);

      // Ellenőrizzük a listanézeteket
      expect(find.text("Group List"), findsOneWidget);
      expect(find.text("Listed Objects"), findsOneWidget);
    });

    testWidgets(
      'should open group creation dialog when Make New Group button is tapped',
      (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: PickerPage())),
        );

        await tester.pumpAndSettle();

        // Act - Tap a csoport létrehozása gomb
        await tester.tap(find.text('Make New Group'));
        await tester.pumpAndSettle();

        // Assert - Ellenőrizzük a dialógus megjelenését
        expect(find.text('Create New Group'), findsOneWidget);
        expect(find.text('Enter group name'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Create'), findsOneWidget);
      },
    );

    testWidgets(
      'should open filters page dialog when Go to Filters button is tapped',
      (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: PickerPage())),
        );

        await tester.pumpAndSettle();

        // Act - Tap a szűrők gomb
        await tester.tap(find.text('Go to Filters'));
        await tester.pumpAndSettle();

        // Assert - Ellenőrizzük a szűrők oldal dialógus megjelenését
        // Módosítsd a tényleges FiltersPage UI-ja alapján
        expect(find.byType(Dialog), findsOneWidget);
      },
    );
  });
}
