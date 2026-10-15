import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/testing.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';

/// The caret, handles and magnifier follow the nearest theme (its cursor color, else its primary color) -- never
/// super_editor's fallback, `ThemeData.primaryColor`, which a dark theme (as `ThemeData.dark().copyWith(colorScheme: …)`) keeps
/// near-black.
void main() {
  const primary = Color(0xFFE0E0E0);
  ThemeData darkTheme() => ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: primary));

  Future<void> pump(WidgetTester tester, StoryEditorController controller, {ThemeData? theme, Color? caretColor}) {
    return pumpStoryEditor(
      tester,
      controller,
      editor: Theme(
        data: theme ?? darkTheme(),
        child: RawEditor(controller: controller, caretColor: caretColor),
      ),
    );
  }

  Color? iosHandleColor(WidgetTester tester) =>
      tester.widget<SuperEditorIosControlsScope>(find.byType(SuperEditorIosControlsScope).first).controller.handleColor;

  testWidgets('iOS: the nested theme\'s primary color', (tester) async {
    expect(darkTheme().primaryColor.computeLuminance(), lessThan(0.1), reason: 'the fallback being avoided is dark');
    await pump(tester, controllerFor('Hello'));
    expect(iosHandleColor(tester), primary);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('iOS, read-only: the reader\'s handles too', (tester) async {
    await pump(tester, controllerFor('Hello', readOnly: true));
    final scope = tester.widget<SuperReaderIosControlsScope>(find.byType(SuperReaderIosControlsScope).first);
    expect(scope.controller.handleColor, primary);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('Android: the primary color', (tester) async {
    await pump(tester, controllerFor('Hello'));
    final scope = tester.widget<SuperEditorAndroidControlsScope>(find.byType(SuperEditorAndroidControlsScope).first);
    expect(scope.controller.controlsColor, primary);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('the theme\'s cursor color, then caretColor, take precedence; a change recolors', (tester) async {
    final controller = controllerFor('Hello');
    const cursor = Color(0xFF00FF00);
    await pump(
      tester,
      controller,
      theme: darkTheme().copyWith(textSelectionTheme: const TextSelectionThemeData(cursorColor: cursor)),
    );
    expect(iosHandleColor(tester), cursor);

    const custom = Color(0xFFFF0000);
    await pump(tester, controller, caretColor: custom);
    expect(iosHandleColor(tester), custom);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
