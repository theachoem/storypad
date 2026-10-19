import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';
import 'story_block_style.dart';
import '../../document/block_type.dart';

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
    final style = node == null ? null : styles[BlockType.of(node)];
    if (style == null) return component;
    // The component (which holds the layout's component key) stays inside, so selection and hit testing measure its
    // content, not the frame.
    return Container(decoration: style.decoration, padding: style.padding, child: component);
  }
}
