import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

import '../support/controller_helpers.dart';

/// The controller's editor leaves out super_editor reactions that fight this package's behavior.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('deleting a task does not re-clamp other tasks\' free indent', () {
    final controller = controllerFor('- [ ] parent\n\n&nbsp;\n\n        - [ ] free-floating, indent 2');

    controller.editor.execute([DeleteNodeRequest(nodeId: nodeAt(controller, 0).id)]);

    expect((controller.document.last as TaskNode).indent, 2);
  });

  test('Markdown shortcuts still work (typing "# " makes a heading)', () {
    final controller = controllerFor('');
    placeCaret(controller, 0, 0);

    controller.editor.execute([
      InsertTextRequest(
        documentPosition: DocumentPosition(
          nodeId: nodeAt(controller, 0).id,
          nodePosition: const TextNodePosition(offset: 0),
        ),
        textToInsert: '# ',
        attributions: {},
      ),
    ]);

    expect(nodeAt(controller, 0).getMetadataValue(NodeMetadata.blockType), header1Attribution);
  });
}
