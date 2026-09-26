import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:storypad_editor/src/widgets/mobile_reorderable_document_overlay.dart';

void main() {
  testWidgets("Long-pressing a block while unfocused reorders it via MoveNodeRequest", (tester) async {
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
    final editorOps = CommonEditorOperations(
      document: document,
      editor: editor,
      composer: composer,
      documentLayoutResolver: () => throw UnimplementedError(),
    );
    final documentLayoutKey = GlobalKey();
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MobileReorderableDocumentOverlay(
            document: document,
            editor: editor,
            editorOps: editorOps,
            focusNode: focusNode,
            documentLayoutResolver: () => documentLayoutKey.currentState as DocumentLayout,
            enabled: !focusNode.hasFocus,
            child: SuperEditor(editor: editor, focusNode: focusNode, documentLayoutKey: documentLayoutKey),
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

    final p1Center = globalRectForNode('p1').center;
    final gesture = await tester.startGesture(p1Center, kind: PointerDeviceKind.touch);
    addTearDown(() => gesture.removePointer());

    // Let the long-press recognizer's timer fire before moving — a drag that
    // starts moving before the long-press threshold would be seen as a
    // scroll/pan instead.
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 1));

    // Drag past the bottom of the second paragraph, so paragraph one should
    // land between paragraph two and paragraph three.
    final dropTarget = Offset(p1Center.dx, globalRectForNode('p2').bottom + 4);
    await gesture.moveTo(dropTarget);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(document.getNodeAt(0)!.id, 'p2');
    expect(document.getNodeAt(1)!.id, 'p1');
    expect(document.getNodeAt(2)!.id, 'p3');
    // The drag never crossed the long-press threshold into a plain tap, so
    // focus should still be untouched.
    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('A second hold started right after a reorder targets the block actually there now, not a stale one', (
    tester,
  ) async {
    // Regression test: this overlay pre-builds one gesture region per node,
    // positioned and `nodeId`-tagged from whatever the document looked like
    // the *last* time this widget happened to rebuild. Without a listener
    // on the editor, completing a drag's own `MoveNodeRequest` didn't
    // trigger that rebuild — so a second hold started quickly afterward,
    // before anything else had caused a fresh build here, could land on a
    // region still tagged with a node id from before the reorder, even
    // though the screen visually already showed the reordered content
    // (SuperEditor itself always rebuilds promptly, since it listens to
    // the same editor directly — only this overlay's own regions lagged).
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
    final editorOps = CommonEditorOperations(
      document: document,
      editor: editor,
      composer: composer,
      documentLayoutResolver: () => throw UnimplementedError(),
    );
    final documentLayoutKey = GlobalKey();
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MobileReorderableDocumentOverlay(
            document: document,
            editor: editor,
            editorOps: editorOps,
            focusNode: focusNode,
            documentLayoutResolver: () => documentLayoutKey.currentState as DocumentLayout,
            enabled: !focusNode.hasFocus,
            child: SuperEditor(editor: editor, focusNode: focusNode, documentLayoutKey: documentLayoutKey),
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

    // First drag: move p1 (top row) down past p2, so the order becomes
    // p2, p1, p3 — the top row is now occupied by p2, not p1.
    final topRowCenter = globalRectForNode('p1').center;
    final firstGesture = await tester.startGesture(topRowCenter, kind: PointerDeviceKind.touch);
    addTearDown(() => firstGesture.removePointer());
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 1));
    await firstGesture.moveTo(Offset(topRowCenter.dx, globalRectForNode('p2').bottom + 4));
    await tester.pump();
    await firstGesture.up();
    // Deliberately just two frames — not pumpAndSettle — to reproduce
    // starting the next hold "quickly": one frame for this overlay's own
    // immediate rebuild, one more for the follow-up rebuild it schedules
    // once SuperEditor's own layout has caught up (see the doc comment on
    // `_editListener` for why that second one matters).
    await tester.pump();
    await tester.pump();

    expect(document.getNodeAt(0)!.id, 'p2');
    expect(document.getNodeAt(1)!.id, 'p1');
    expect(document.getNodeAt(2)!.id, 'p3');

    // Second drag, immediately: hold at the exact same screen position as
    // before (the top row) — which is p2 now, not p1 — and move it to the
    // bottom of the list.
    final secondGesture = await tester.startGesture(topRowCenter, kind: PointerDeviceKind.touch);
    addTearDown(() => secondGesture.removePointer());
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 1));
    await secondGesture.moveTo(Offset(topRowCenter.dx, globalRectForNode('p3').bottom + 4));
    await tester.pump();
    await secondGesture.up();
    await tester.pumpAndSettle();

    // p2 (whatever was actually at the held screen position) moved to the
    // end — not p1 (whatever a stale gesture region might have still been
    // tagged with).
    expect(document.getNodeAt(0)!.id, 'p1');
    expect(document.getNodeAt(1)!.id, 'p3');
    expect(document.getNodeAt(2)!.id, 'p2');
  });

  testWidgets('losing focus mid-drag (disabling every gesture region) does not crash with "widget tree was locked"', (
    tester,
  ) async {
    // Regression test for a real crash. `LongPressGestureRecognizer` only
    // invokes `onLongPressCancel` on disposal while it's still in the
    // `possible` state (see `LongPressGestureRecognizer.resolve`'s
    // `if (_longPressAccepted) { _reset(); } else { _checkLongPressCancel(); }`
    // in the Flutter SDK) -- i.e. the finger is down but the long-press
    // timer (`kLongPressTimeout`) hasn't fired yet, before `_startDrag`
    // is even called. Production wires `enabled: !_editorFocusNode.hasFocus`
    // (RawEditor), so anything granting focus *in that window* flips
    // `enabled` to `false` on this overlay's very next rebuild -- tearing
    // down every gesture region, including the one whose recognizer is
    // still `possible`, and disposing it. `OneSequenceGestureRecognizer
    // .dispose()` calls `resolve(rejected)` synchronously as part of that
    // teardown, which -- for a still-`possible` long-press -- invokes
    // `onLongPressCancel` synchronously too, *during* the very rebuild
    // that triggered it, while the widget tree is locked. Calling
    // `setState` there used to throw "setState() or markNeedsBuild()
    // called when widget tree was locked." See `_safeSetState`'s doc
    // comment on the fix.
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
    final editorOps = CommonEditorOperations(
      document: document,
      editor: editor,
      composer: composer,
      documentLayoutResolver: () => throw UnimplementedError(),
    );
    final documentLayoutKey = GlobalKey();
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    // Directly controlled rather than driven off `focusNode.hasFocus`
    // itself -- mirrors production's `enabled: !_editorFocusNode.hasFocus`
    // reacting live to *something* flipping it mid-gesture, without this
    // test also having to pin down exactly when FocusManager delivers a
    // requestFocus() notification relative to frame timing.
    late StateSetter rebuildHost;
    var forceDisabled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuildHost = setState;
              return MobileReorderableDocumentOverlay(
                document: document,
                editor: editor,
                editorOps: editorOps,
                focusNode: focusNode,
                documentLayoutResolver: () => documentLayoutKey.currentState as DocumentLayout,
                enabled: !forceDisabled,
                child: SuperEditor(editor: editor, focusNode: focusNode, documentLayoutKey: documentLayoutKey),
              );
            },
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

    final p1Center = globalRectForNode('p1').center;
    final gesture = await tester.startGesture(p1Center, kind: PointerDeviceKind.touch);
    addTearDown(() => gesture.removePointer());

    // Something else disables this overlay *before* the long-press timer
    // has fired -- the recognizer is still `possible`, not yet
    // `_startDrag`.
    rebuildHost(() => forceDisabled = true);
    await tester.pump();

    expect(tester.takeException(), isNull);

    // Advance past the long-press threshold anyway, and release --
    // there's no drag to complete (it was cancelled), this just confirms
    // the app keeps working normally afterward.
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('A plain tap on a block while unfocused places the caret and requests focus', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final document = MutableDocument(
      nodes: [ParagraphNode(id: 'p1', text: AttributedText('Paragraph one'))],
    );
    final composer = MutableDocumentComposer();
    final editor = createDefaultDocumentEditor(document: document, composer: composer, isHistoryEnabled: true);
    final editorOps = CommonEditorOperations(
      document: document,
      editor: editor,
      composer: composer,
      documentLayoutResolver: () => throw UnimplementedError(),
    );
    final documentLayoutKey = GlobalKey();
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MobileReorderableDocumentOverlay(
            document: document,
            editor: editor,
            editorOps: editorOps,
            focusNode: focusNode,
            documentLayoutResolver: () => documentLayoutKey.currentState as DocumentLayout,
            enabled: !focusNode.hasFocus,
            child: SuperEditor(editor: editor, focusNode: focusNode, documentLayoutKey: documentLayoutKey),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final layout = documentLayoutKey.currentState as DocumentLayout;
    final component = layout.getComponentByNodeId('p1')!;
    final box = (component as State).context.findRenderObject()! as RenderBox;
    final rect = box.localToGlobal(Offset.zero) & box.size;

    await tester.tapAt(rect.center);
    await tester.pumpAndSettle();

    expect(focusNode.hasFocus, isTrue);
    expect(composer.selection, isNotNull);
  });

  testWidgets('A real snapshot preview of the held block appears at the drop slot', (tester) async {
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
    final editorOps = CommonEditorOperations(
      document: document,
      editor: editor,
      composer: composer,
      documentLayoutResolver: () => throw UnimplementedError(),
    );
    final documentLayoutKey = GlobalKey();
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MobileReorderableDocumentOverlay(
            document: document,
            editor: editor,
            editorOps: editorOps,
            focusNode: focusNode,
            documentLayoutResolver: () => documentLayoutKey.currentState as DocumentLayout,
            enabled: !focusNode.hasFocus,
            child: SuperEditor(editor: editor, focusNode: focusNode, documentLayoutKey: documentLayoutKey),
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

    Rect previewRect() => tester.getRect(
      find.byWidgetPredicate((w) => w is CustomPaint && w.painter.runtimeType.toString() == '_SnapshotRegionPainter'),
    );

    final p1Rect = globalRectForNode('p1');
    final gesture = await tester.startGesture(p1Rect.center, kind: PointerDeviceKind.touch);
    addTearDown(() => gesture.removePointer());

    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(hasSnapshotPreview(), isTrue);

    // Right when it's grabbed, before any movement, the floating preview
    // sits exactly on top of the real block.
    final initialPreviewRect = previewRect();
    expect((initialPreviewRect.topLeft - p1Rect.topLeft).distance, lessThan(2));

    // Notion-style free 2D following — see the matching desktop test for
    // why both axes, not just vertical slot-snapping.
    const dragDelta = Offset(23, 41);
    await gesture.moveTo(p1Rect.center + dragDelta);
    await tester.pump();

    final movedPreviewRect = previewRect();
    expect((movedPreviewRect.topLeft - initialPreviewRect.topLeft - dragDelta).distance, lessThan(2));

    // The drop *line* (unlike the cosmetic preview above) still only snaps
    // vertically, and should match the exact width/position of whichever
    // block it's attached to — not a generic fixed-width band.
    final lineRect = tester.getRect(find.byWidgetPredicate((w) => w is Container && w.constraints?.maxHeight == 2));
    final p2Rect = globalRectForNode('p2');
    expect(lineRect.left, closeTo(p2Rect.left, 1));
    expect(lineRect.width, closeTo(p2Rect.width, 1));

    await gesture.moveTo(Offset(p1Rect.center.dx, p2Rect.bottom + 4));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(hasSnapshotPreview(), isFalse);
  });
}
