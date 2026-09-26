import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor_example/main.dart';

void main() {
  testWidgets('example app boots', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('storypad_editor example'), findsOneWidget);
  });
}
