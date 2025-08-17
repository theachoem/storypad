import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/app.dart';

void main() {
  group('Edge-to-edge navigation bar implementation', () {
    testWidgets('app uses AnnotatedRegion for transparent navigation bar', (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      // Find the AnnotatedRegion widget that wraps the MaterialApp
      final annotatedRegionFinder = find.byWidgetPredicate(
        (widget) => widget is AnnotatedRegion<SystemUiOverlayStyle>,
      );
      
      expect(annotatedRegionFinder, findsOneWidget);
      
      final AnnotatedRegion<SystemUiOverlayStyle> annotatedRegion = 
          tester.widget(annotatedRegionFinder);
      
      // Verify navigation bar is transparent for edge-to-edge
      expect(
        annotatedRegion.value.systemNavigationBarColor,
        equals(Colors.transparent),
      );
      
      // Verify navigation bar divider is also transparent
      expect(
        annotatedRegion.value.systemNavigationBarDividerColor,
        equals(Colors.transparent),
      );
      
      // Verify status bar is transparent
      expect(
        annotatedRegion.value.statusBarColor,
        equals(Colors.transparent),
      );
    });

    testWidgets('system UI overlay style adjusts for light theme', (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      final annotatedRegionFinder = find.byWidgetPredicate(
        (widget) => widget is AnnotatedRegion<SystemUiOverlayStyle>,
      );
      
      final AnnotatedRegion<SystemUiOverlayStyle> annotatedRegion = 
          tester.widget(annotatedRegionFinder);

      // In light theme, icons should be dark
      expect(
        annotatedRegion.value.systemNavigationBarIconBrightness,
        equals(Brightness.dark),
      );
      expect(
        annotatedRegion.value.statusBarIconBrightness,
        equals(Brightness.dark),
      );
    });

    testWidgets('edge-to-edge works consistently across app states', (WidgetTester tester) async {
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      // The AnnotatedRegion should be at the app level, meaning it applies
      // to all screens including when drawers or modals are open
      final materialAppFinder = find.byType(MaterialApp);
      expect(materialAppFinder, findsOneWidget);
      
      // Verify the MaterialApp is wrapped by AnnotatedRegion
      final Widget materialApp = tester.widget(materialAppFinder);
      expect(materialApp.runtimeType, equals(MaterialApp));
      
      // The parent should be AnnotatedRegion
      final Element materialAppElement = tester.element(materialAppFinder);
      final Widget? parent = materialAppElement.widget;
      
      // Navigate through widgets to verify AnnotatedRegion is a parent
      bool foundAnnotatedRegion = false;
      materialAppElement.visitAncestorElements((Element element) {
        if (element.widget is AnnotatedRegion<SystemUiOverlayStyle>) {
          foundAnnotatedRegion = true;
          return false; // Stop searching
        }
        return true; // Continue searching
      });
      
      expect(foundAnnotatedRegion, isTrue, 
        reason: 'AnnotatedRegion should wrap MaterialApp for consistent edge-to-edge behavior');
    });
  });
}