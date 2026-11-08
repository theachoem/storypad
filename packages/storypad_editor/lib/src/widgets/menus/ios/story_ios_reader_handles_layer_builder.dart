import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:super_editor/super_editor.dart';

/// The iOS read-only handles, in [handleColor], for an expanded selection only: like a read-only `UITextView`, a
/// reader shows no caret. super_editor's `SuperReaderIosHandlesDocumentLayerBuilder` falls back to
/// `ThemeData.primaryColor` (near-black in a dark theme) and draws a still caret for a collapsed selection.
class StoryIosReaderHandlesLayerBuilder implements SuperReaderDocumentLayerBuilder {
  const StoryIosReaderHandlesLayerBuilder({required this.handleColor});

  final Color handleColor;

  @override
  ContentLayerWidget build(BuildContext context, SuperReaderContext readerContext) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return const ContentLayerProxyWidget(child: SizedBox());
    }

    return IosHandlesDocumentLayer(
      document: readerContext.document,
      documentLayout: readerContext.documentLayout,
      selection: _ExpandedSelection(readerContext.composer.selectionNotifier),
      changeSelection: (newSelection, changeType, reason) {
        readerContext.editor.execute([ChangeSelectionRequest(newSelection, changeType, reason)]);
      },
      handleColor: handleColor,
      shouldCaretBlink: ValueNotifier<bool>(false),
    );
  }
}

/// [source], read as `null` while it's collapsed. Equal for the same [source], so a rebuild keeps the layer's listener.
class _ExpandedSelection implements ValueListenable<DocumentSelection?> {
  const _ExpandedSelection(this.source);

  final ValueListenable<DocumentSelection?> source;

  @override
  DocumentSelection? get value {
    final selection = source.value;
    return selection == null || selection.isCollapsed ? null : selection;
  }

  @override
  void addListener(VoidCallback listener) => source.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => source.removeListener(listener);

  @override
  bool operator ==(Object other) => other is _ExpandedSelection && identical(other.source, source);

  @override
  int get hashCode => identityHashCode(source);
}
