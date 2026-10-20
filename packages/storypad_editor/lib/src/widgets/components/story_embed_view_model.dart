import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import '../../embed/story_embed_node.dart';

/// The view model for any embed node. Equality covers the node's type and value (plus selection and layout), so the
/// embed rebuilds exactly when its value or selection changes.
class StoryEmbedViewModel extends SingleColumnLayoutComponentViewModel with SelectionAwareViewModelMixin {
  StoryEmbedViewModel({
    required super.nodeId,
    super.createdAt,
    super.maxWidth,
    super.padding = EdgeInsets.zero,
    super.opacity = 1.0,
    required this.node,
    DocumentNodeSelection? selection,
    Color selectionColor = Colors.transparent,
  }) {
    this.selection = selection;
    this.selectionColor = selectionColor;
  }

  final StoryEmbedNode node;

  /// Whether the embed is wholly inside an expanded selection.
  bool get isSelected {
    final nodeSelection = selection?.nodeSelection;
    return nodeSelection is UpstreamDownstreamNodeSelection && !nodeSelection.isCollapsed;
  }

  @override
  StoryEmbedViewModel copy() {
    return StoryEmbedViewModel(
      nodeId: nodeId,
      createdAt: createdAt,
      maxWidth: maxWidth,
      padding: padding,
      opacity: opacity,
      node: node,
      selection: selection,
      selectionColor: selectionColor,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other && other is StoryEmbedViewModel && node.type == other.node.type && node.value == other.node.value;

  @override
  int get hashCode => Object.hash(super.hashCode, node.type, node.value);
}
