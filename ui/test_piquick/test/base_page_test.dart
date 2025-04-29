import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_piquick/base_page.dart';
import 'package:test_piquick/features/picker/view/picker_page.dart';
import 'package:test_piquick/features/rendering/view/render_page.dart';

void main() {
  group('BasePage Tests', () {
    testWidgets('should display the app bar with correct title', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: BasePage())),
      );

      // Act & Assert
      expect(find.text('Piquick Objects'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should display PickerPage as the default page', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: BasePage())),
      );

      // Act & Assert
      // IndexedStack tartalmazza az oldalakat, ahol az első (index: 0) a PickerPage
      final indexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(
        indexedStack.index,
        0,
      ); // Ellenőrizzük, hogy az IndexedStack index 0-ra van beállítva

      // Ellenőrizzük, hogy a PickerPage megtalálható az oldalak között
      expect(find.byType(PickerPage), findsOneWidget);
    });

    testWidgets('should navigate to RenderPage when tapping on Render tab', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: BasePage())),
      );

      // Act - Kattintás a második tab-ra (Render)
      await tester.tap(find.byIcon(Icons.view_in_ar));
      await tester.pumpAndSettle();

      // Assert - Ellenőrizzük, hogy az index 1-re változott
      final indexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(indexedStack.index, 1);

      // Ellenőrizzük, hogy a RenderPage megtalálható az oldalak között
      expect(find.byType(RenderPage), findsOneWidget);
    });

    testWidgets(
      'should navigate back to PickerPage when tapping on PickerPage tab',
      (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: BasePage())),
        );

        // Act - Először navigáljunk a RenderPage-re
        await tester.tap(find.byIcon(Icons.view_in_ar));
        await tester.pumpAndSettle();

        // Majd vissza a PickerPage-re
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        // Assert - Ellenőrizzük, hogy az index visszaváltott 0-ra
        final indexedStack = tester.widget<IndexedStack>(
          find.byType(IndexedStack),
        );
        expect(indexedStack.index, 0);

        // Ellenőrizzük, hogy a PickerPage aktív
        expect(find.byType(PickerPage), findsOneWidget);
      },
    );

    testWidgets('should maintain state of pages when navigating between tabs', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: BasePage())),
      );

      // Az IndexedStack-et használjuk, ami megtartja az oldalak állapotát
      // Ez a teszt ellenőrzi, hogy az IndexedStack megfelelően van-e konfigurálva

      final indexedStackFinder = find.byType(IndexedStack);
      expect(indexedStackFinder, findsOneWidget);

      final indexedStack = tester.widget<IndexedStack>(indexedStackFinder);
      // Ellenőrizzük, hogy mindkét oldal megtalálható az IndexedStack-ben
      expect(indexedStack.children.length, 2);
      expect(indexedStack.children[0], isA<PickerPage>());
      expect(indexedStack.children[1], isA<RenderPage>());
    });

    testWidgets('should highlight the active tab in the bottom navigation bar', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: BasePage())),
      );

      // Act & Assert - Ellenőrizzük, hogy a kezdő lap (PickerPage) ki van jelölve
      final bottomNavigationBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNavigationBar.currentIndex, 0);

      // Navigáljunk a RenderPage-re
      await tester.tap(find.byIcon(Icons.view_in_ar));
      await tester.pumpAndSettle();

      // Ellenőrizzük, hogy a RenderPage tab ki van jelölve
      final updatedBottomNavigationBar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(updatedBottomNavigationBar.currentIndex, 1);
    });
  });
}
