import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:storypad_editor/src/widgets/drag_snapshot_preview.dart';
import 'package:storypad_editor/src/widgets/reorderable_document_overlay.dart';

void main() {
  testWidgets("Dragging a block's handle reorders it via MoveNodeRequest", (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final document = MutableDocument(
      nodes: [
        ParagraphNode(id: 'p1', text: AttributedText('Paragraph one')),
        ParagraphNode(id: 'p2', text: AttributedText('Paragraph two')),
        ParagraphNode(id: 'p3', text: AttributedText('Paragraph three')),
      ],
    );
    final composer = MutableDocumentComposer();
    final editor = createDefaultDocumentEditor(document: document, composer: composer, isHistoryEnabled: true);
    final documentLayoutKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReorderableDocumentOverlay(
            document: document,
            composer: composer,
            editor: editor,
            documentLayoutResolver: () => documentLayoutKey.currentState as DocumentLayout,
            child: SuperEditor(editor: editor, documentLayoutKey: documentLayoutKey),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // SuperEditor doesn't render paragraph content as plain `Text` widgets, so
    // rather than finding it via `find.text`, ask the document layout itself
    // (the same lookup ReorderableDocumentOverlay uses internally) where each
    // node's component sits on screen.
    Rect globalRectForNode(String nodeId) {
      final layout = documentLayoutKey.currentState as DocumentLayout;
      final component = layout.getComponentByNodeId(nodeId)!;
      final box = (component as State).context.findRenderObject()! as RenderBox;
      return box.localToGlobal(Offset.zero) & box.size;
    }

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(() => gesture.removePointer());
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();

    // Hover over the first paragraph to reveal its drag handle.
    await gesture.moveTo(globalRectForNode('p1').center);
    await tester.pump();

    final handleCenter = tester.getCenter(find.byIcon(Icons.drag_indicator));

    await gesture.moveTo(handleCenter);
    await tester.pump();
    await gesture.down(handleCenter);
    await tester.pump();

    // Drag past the bottom of the second paragraph, so paragraph one should
    // land between paragraph two and paragraph three.
    final dropTarget = Offset(handleCenter.dx, globalRectForNode('p2').bottom + 4);
    await gesture.moveTo(dropTarget);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(document.getNodeAt(0)!.id, 'p2');
    expect(document.getNodeAt(1)!.id, 'p1');
    expect(document.getNodeAt(2)!.id, 'p3');
  });

  testWidgets('A real snapshot preview of the dragged block appears at the drop slot', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final document = MutableDocument(
      nodes: [
        ParagraphNode(id: 'p1', text: AttributedText('Paragraph one')),
        ParagraphNode(id: 'p2', text: AttributedText('Paragraph two')),
      ],
    );
    final composer = MutableDocumentComposer();
    final editor = createDefaultDocumentEditor(document: document, composer: composer, isHistoryEnabled: true);
    final documentLayoutKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReorderableDocumentOverlay(
            document: document,
            composer: composer,
            editor: editor,
            documentLayoutResolver: () => documentLayoutKey.currentState as DocumentLayout,
            child: SuperEditor(editor: editor, documentLayoutKey: documentLayoutKey),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Rect globalRectForNode(String nodeId) {
      final layout = documentLayoutKey.currentState as DocumentLayout;
      final component = layout.getComponentByNodeId(nodeId)!;
      final box = (component as State).context.findRenderObject()! as RenderBox;
      return box.localToGlobal(Offset.zero) & box.size;
    }

    bool hasSnapshotPreview() => find
        .byWidgetPredicate((w) => w is CustomPaint && w.painter.runtimeType.toString() == '_SnapshotRegionPainter')
        .evaluate()
        .isNotEmpty;

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(() => gesture.removePointer());
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();
    await gesture.moveTo(globalRectForNode('p1').center);
    await tester.pump();

    final handleCenter = tester.getCenter(find.byIcon(Icons.drag_indicator));
    await gesture.moveTo(handleCenter);
    await tester.pump();
    await gesture.down(handleCenter);
    await tester.pump();

    Rect previewRect() => tester.getRect(
      find.byWidgetPredicate((w) => w is CustomPaint && w.painter.runtimeType.toString() == '_SnapshotRegionPainter'),
    );

    // The snapshot is captured asynchronously (RenderRepaintBoundary.toImage)
    // — pumpAndSettle to let it resolve.
    await tester.pumpAndSettle();
    expect(hasSnapshotPreview(), isTrue);

    // Only the dragged block's region is captured, not the whole document: a long story's full height can exceed what
    // a GPU texture may be (Metal: 16384 px), which Impeller fails on.
    final painter = tester
        .widget<CustomPaint>(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter.runtimeType.toString() == '_SnapshotRegionPainter',
          ),
        )
        .painter;
    final snapshotHeight = ((painter as dynamic).image as dynamic).height as int;
    expect(snapshotHeight, globalRectForNode('p1').height.round());

    // At the exact moment of grabbing, before any movement, the floating
    // preview sits right on top of the real block it was grabbed from —
    // it hasn't moved anywhere yet.
    final p1Rect = globalRectForNode('p1');
    final initialPreviewRect = previewRect();
    expect((initialPreviewRect.topLeft - p1Rect.topLeft).distance, lessThan(2));

    // Notion-style free 2D following: dragging by some (dx, dy) moves the
    // floating preview by that same (dx, dy) — in both axes, not just
    // snapping vertically between fixed slots the way the drop *line*
    // still does (that's covered by the reorder-still-works test above;
    // this test only exercises the cosmetic ghost).
    const dragDelta = Offset(37, 52);
    await gesture.moveTo(handleCenter + dragDelta);
    await tester.pump();

    final movedPreviewRect = previewRect();
    expect((movedPreviewRect.topLeft - initialPreviewRect.topLeft - dragDelta).distance, lessThan(2));

    await gesture.up();
    await tester.pumpAndSettle();

    // Gone again once the drag ends.
    expect(hasSnapshotPreview(), isFalse);
  });

  testWidgets('Handle hugs the text even when the document column sits far from the overlay edge', (tester) async {
    // A wide window with the document column centered well away from this
    // overlay's own left edge — the bug this guards against positioned the
    // handle from a fixed offset off *this overlay's* edge, which drifted
    // arbitrarily far from the text as the window (and thus the gap between
    // the overlay's edge and the centered column) grew.
    tester.view.physicalSize = const Size(2000, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final document = MutableDocument(
      nodes: [ParagraphNode(id: 'p1', text: AttributedText('Paragraph one'))],
    );
    final composer = MutableDocumentComposer();
    final editor = createDefaultDocumentEditor(document: document, composer: composer, isHistoryEnabled: true);
    final documentLayoutKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReorderableDocumentOverlay(
            document: document,
            composer: composer,
            editor: editor,
            documentLayoutResolver: () => documentLayoutKey.currentState as DocumentLayout,
            child: Center(
              child: SizedBox(
                width: 400,
                child: SuperEditor(editor: editor, documentLayoutKey: documentLayoutKey),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final layout = documentLayoutKey.currentState as DocumentLayout;
    final component = layout.getComponentByNodeId('p1')!;
    final box = (component as State).context.findRenderObject()! as RenderBox;
    final textRect = box.localToGlobal(Offset.zero) & box.size;

    // Well clear of x=0 — proves the column really is inset from this
    // overlay's own edge, not just from the window's.
    expect(textRect.left, greaterThan(700));

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(() => gesture.removePointer());
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();
    await gesture.moveTo(textRect.center);
    await tester.pump();

    final handleRect = tester.getRect(find.byIcon(Icons.drag_indicator));

    final gap = textRect.left - handleRect.right;
    expect(gap, greaterThanOrEqualTo(0));
    expect(gap, lessThan(10));

    // The handle should also be vertically centered on the text's own line,
    // not pinned to the top of the block.
    expect((handleRect.center.dy - textRect.center.dy).abs(), lessThan(2));
  });

  testWidgets('Dragging the handle of a selected block moves every selected block together', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final document = MutableDocument(
      nodes: [
        for (final id in ['p1', 'p2', 'p3', 'p4']) ParagraphNode(id: id, text: AttributedText('Paragraph $id')),
      ],
    );
    final composer = MutableDocumentComposer();
    final editor = createDefaultDocumentEditor(document: document, composer: composer, isHistoryEnabled: true);
    final documentLayoutKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReorderableDocumentOverlay(
            document: document,
            composer: composer,
            editor: editor,
            documentLayoutResolver: () => documentLayoutKey.currentState as DocumentLayout,
            child: SuperEditor(editor: editor, documentLayoutKey: documentLayoutKey),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Select from inside p1 to inside p2.
    composer.setSelectionWithReason(
      const DocumentSelection(
        base: DocumentPosition(nodeId: 'p1', nodePosition: TextNodePosition(offset: 2)),
        extent: DocumentPosition(nodeId: 'p2', nodePosition: TextNodePosition(offset: 3)),
      ),
    );
    await tester.pump();

    Rect globalRectForNode(String nodeId) {
      final layout = documentLayoutKey.currentState as DocumentLayout;
      final component = layout.getComponentByNodeId(nodeId)!;
      final box = (component as State).context.findRenderObject()! as RenderBox;
      return box.localToGlobal(Offset.zero) & box.size;
    }

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(() => gesture.removePointer());
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();

    // Hover the second selected block, and drag its handle below p3.
    await gesture.moveTo(globalRectForNode('p2').center);
    await tester.pump();
    final handleCenter = tester.getCenter(find.byIcon(Icons.drag_indicator));
    await gesture.moveTo(handleCenter);
    await tester.pump();
    await gesture.down(handleCenter);
    await tester.pump();
    await gesture.moveTo(Offset(handleCenter.dx, globalRectForNode('p3').bottom + 4));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect([for (final node in document) node.id], ['p3', 'p1', 'p2', 'p4']);

    // One undo step.
    editor.undo();
    expect([for (final node in document) node.id], ['p1', 'p2', 'p3', 'p4']);
  });

  group('dragSnapshotPixelRatio', () {
    test('keeps the device pixel ratio while the region fits', () {
      expect(dragSnapshotPixelRatio(const Size(800, 300), 2), 2);
      expect(dragSnapshotPixelRatio(const Size(800, 2048), 2), 2);
    });

    test('lowers it so the longest side stays within the limit', () {
      final ratio = dragSnapshotPixelRatio(const Size(800, 20000), 2)!;
      expect(20000 * ratio, closeTo(maxDragSnapshotExtent, 0.001));
      expect(800 * ratio, lessThan(maxDragSnapshotExtent));
    });

    test('nothing to capture for an empty region', () {
      expect(dragSnapshotPixelRatio(Size.zero, 2), isNull);
      expect(dragSnapshotPixelRatio(const Size(800, 0), 2), isNull);
    });
  });

  group('dragHandleSizeFor', () {
    test('full size with room to spare', () {
      expect(dragHandleSizeFor(18), (icon: 14.0, gap: 4.0));
      expect(dragHandleSizeFor(40), (icon: 14.0, gap: 4.0));
    });

    test('the gap shrinks first, then the icon, down to 10', () {
      expect(dragHandleSizeFor(16), (icon: 14.0, gap: 2.0));
      expect(dragHandleSizeFor(12), (icon: 11.0, gap: 1.0));
      expect(dragHandleSizeFor(4), (icon: 10.0, gap: 1.0));
    });
  });
}
