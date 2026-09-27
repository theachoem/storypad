import 'package:flutter_test/flutter_test.dart';
import 'package:storypad_editor_example/main.dart';

void main() {
  testWidgets('example app boots to the page list', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('storypad_editor'), findsOneWidget);
    expect(find.text('Raw editor'), findsOneWidget);
  });
}
