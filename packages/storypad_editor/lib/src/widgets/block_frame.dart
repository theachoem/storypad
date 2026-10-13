import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

/// How a block type is framed: a box [decoration] (background, border, corners) and the [padding] between the frame
/// and the block's content -- e.g. a quote's tinted box with its text inset from the edges.
///
/// Space *between* blocks is `RawEditor.spacing` (see `StoryEditorSpacing`), outside the frame.
@immutable
final class StoryBlockStyle {
  const StoryBlockStyle({this.decoration, this.padding = EdgeInsets.zero});

  final BoxDecoration? decoration;
  final EdgeInsets padding;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is StoryBlockStyle && decoration == other.decoration && padding == other.padding;

  @override
  int get hashCode => Object.hash(decoration, padding);
}

/// The block type a [StoryBlockStyle] is looked up by: the node's block type, e.g. `paragraph`, `header1`,
/// `blockquote`, `code`, `listItem`, `task`, `horizontalRule`, or an embed's type.
String? blockTypeOf(DocumentNode node) {
  final Object? blockType = node.getMetadataValue(NodeMetadata.blockType);
  return blockType is Attribution ? blockType.id : null;
}

/// Frames the components another builder creates, per [styles] (by block type).
class FramedComponentBuilder implements ComponentBuilder {
  const FramedComponentBuilder(this.delegate, {required this.document, required this.styles});

  final ComponentBuilder delegate;
  final Document document;
  final Map<String, StoryBlockStyle> styles;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) =>
      delegate.createViewModel(document, node);

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    final component = delegate.createComponent(componentContext, componentViewModel);
    if (component == null) return null;

    final node = document.getNodeById(componentViewModel.nodeId);
    final style = node == null ? null : styles[blockTypeOf(node)];
    if (style == null) return component;
    // The component (which holds the layout's component key) stays inside, so selection and hit testing measure its
    // content, not the frame.
    return Container(decoration: style.decoration, padding: style.padding, child: component);
  }
}
