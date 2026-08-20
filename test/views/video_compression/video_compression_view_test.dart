import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad/views/video_compression/video_compression_view.dart';

void main() {
  group('VideoCompressionRoute.run', () {
    // The screen sits on the root navigator, whose entire stack is the single
    // RootView route (see _RootContent's nested Navigator). Anything that pops
    // one route too many there empties the navigator and renders black -- which
    // is exactly what the shared loading dialog used to do, because it rebuilt
    // its pop callback on every rebuild of the dialog.
    testWidgets('removes only its own route when the app rebuilds mid-task', (tester) async {
      final nestedNavigatorKey = GlobalKey<NavigatorState>();
      final task = Completer<String>();

      Widget app(Color seed) {
        return MaterialApp(
          theme: ThemeData(colorSchemeSeed: seed),
          home: Scaffold(
            body: Navigator(
              key: nestedNavigatorKey,
              onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const Scaffold(body: Text('EDITOR'))),
            ),
          ),
        );
      }

      await tester.pumpWidget(app(Colors.blue));
      await tester.pumpAndSettle();

      final result = VideoCompressionRoute.run<String>(
        nestedNavigatorKey.currentContext!,
        totalVideos: 1,
        task: (_) => task.future,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(VideoCompressionView), findsOneWidget);

      // Rebuilding MaterialApp rebuilds every route's page. The old dialog
      // registered another pop per rebuild; this must not.
      await tester.pumpWidget(app(Colors.red));
      await tester.pump();

      task.complete('PICKED');
      await tester.pumpAndSettle();

      expect(await result, 'PICKED');
      expect(find.byType(VideoCompressionView), findsNothing);
      expect(find.text('EDITOR'), findsOneWidget, reason: 'the route underneath must survive');
      expect(tester.takeException(), isNull);
    });

    testWidgets('takes the screen down and falls back to null when the task throws', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Text('EDITOR')),
        ),
      );

      final result = await VideoCompressionRoute.run<String>(
        navigatorKey.currentContext!,
        totalVideos: 1,
        task: (_) async => throw StateError('encoder blew up'),
      );
      await tester.pumpAndSettle();

      expect(result, isNull);
      expect(find.byType(VideoCompressionView), findsNothing);
      expect(find.text('EDITOR'), findsOneWidget);
    });

    // Most picks are skipped by the within-target pre-check and return in
    // milliseconds; a full screen flashing up for those is worse than nothing.
    testWidgets('never shows at all for a task that settles quickly', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Text('EDITOR')),
        ),
      );

      final result = VideoCompressionRoute.run<String>(
        navigatorKey.currentContext!,
        totalVideos: 1,
        task: (_) async => 'SKIPPED',
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(VideoCompressionView), findsNothing);

      await tester.pumpAndSettle();
      expect(await result, 'SKIPPED');
      expect(find.byType(VideoCompressionView), findsNothing);
    });
  });
}
