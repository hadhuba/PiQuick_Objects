import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_piquick/base_page.dart';

void main() {
  group('BasePage Navigation Tests', () {
    testWidgets('should display PickerPage as default page', (
      WidgetTester tester,
    ) async {
      // Arrange - Build the BasePage widget inside a ProviderScope for Riverpod
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: BasePage())),
      );

      // Act - No action needed as we're testing initial state
      await tester.pump();

      // Assert
      // Verify that the app bar title is displayed
      expect(find.text('Piquick Objects'), findsOneWidget);

      // Verify that PickerPage is active by checking for its specific elements
      // (You may need to adjust these based on your actual UI elements)
      expect(find.text('PickerPage'), findsOneWidget);
      expect(find.text('Render'), findsOneWidget);
    });

    testWidgets('should navigate to RenderPage when Render tab is tapped', (
      WidgetTester tester,
    ) async {
      // Arrange - Build the BasePage widget
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: BasePage())),
      );

      // Act - Tap the Render navigation item
      await tester.tap(find.text('Render'));
      await tester.pumpAndSettle(); // Wait for animations to complete

      // Assert - Check that we're now on the RenderPage
      // This might be different based on your RenderPage implementation
      expect(find.text('Render Settings'), findsOneWidget);
    });

    testWidgets(
      'should navigate back to PickerPage when PickerPage tab is tapped',
      (WidgetTester tester) async {
        // Arrange - Build the BasePage widget and navigate to RenderPage
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: BasePage())),
        );

        // Navigate to RenderPage first
        await tester.tap(find.text('Render'));
        await tester.pumpAndSettle();

        // Act - Navigate back to PickerPage
        await tester.tap(find.text('PickerPage'));
        await tester.pumpAndSettle();

        // Assert - Check that we're back on PickerPage
        expect(find.text('Group List'), findsOneWidget);
        expect(find.text('Listed Objects'), findsOneWidget);
      },
    );
  });
}
