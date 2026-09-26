import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import '../controller/story_editor_controller.dart';
import '../embed/story_embed.dart';
import '../embed/story_embed_node.dart';
import '../embed/unknown_embed.dart';

/// Renders every embed node, whatever its type, through its embed's [StoryEmbed.build] (or the controller's unknown
/// embed builder). The one super_editor component builder all embeds share -- apps never write their own.
class StoryEmbedComponentBuilder implements ComponentBuilder {
  const StoryEmbedComponentBuilder(this.controller);

  final StoryEditorController controller;

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    if (node is! StoryEmbedNode) return null;
    return StoryEmbedViewModel(nodeId: node.id, createdAt: node.metadata[NodeMetadata.createdAt], node: node);
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! StoryEmbedViewModel) return null;
    return StoryEmbedComponent(
      componentKey: componentContext.componentKey,
      viewModel: componentViewModel,
      controller: controller,
    );
  }
}

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

/// Hosts one embed's widget in the document layout: a [BoxComponent] (so the editor can select, delete and place the
/// caret around it) with the embed's widget inside and a selection highlight painted over it.
///
/// Not super_editor's `SelectableBox`: that wraps its child in `IgnorePointer`, which would disable every button in
/// an embed.
class StoryEmbedComponent extends StatelessWidget {
  const StoryEmbedComponent({super.key, required this.componentKey, required this.viewModel, required this.controller});

  final GlobalKey componentKey;
  final StoryEmbedViewModel viewModel;
  final StoryEditorController controller;

  @override
  Widget build(BuildContext context) {
    final isSelected = viewModel.isSelected;
    return BoxComponent(
      key: componentKey,
      opacity: viewModel.opacity,
      child: Stack(
        children: [
          // The embed also depends on read-only mode, which isn't part of the view model.
          ValueListenableBuilder<bool>(
            valueListenable: controller.readOnlyListenable,
            builder: (context, _, _) => _buildEmbed(context, isSelected),
          ),
          if (isSelected)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  key: ValueKey('story-embed-selection-${viewModel.nodeId}'),
                  color: viewModel.selectionColor.withValues(alpha: viewModel.selectionColor.a * 0.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmbed(BuildContext context, bool isSelected) {
    final node = viewModel.node;
    final embed = controller.embedFor(node);
    if (embed is StoryEmbed) {
      return embed.buildNode(context, node, controller: controller, isSelected: isSelected);
    }
    if (embed is UnknownEmbedCodec) {
      final builder = controller.unknownBuilder ?? defaultUnknownEmbedBuilder;
      return builder(
        context,
        StoryEmbedContext<UnknownEmbedValue>(
          nodeId: node.id,
          value: embed.valueOf(node),
          isSelected: isSelected,
          controller: controller,
          embed: embed,
        ),
      );
    }
    // A node of a type this controller has no embed for (e.g. inserted through the escape hatches). Kept, visibly.
    return _Placeholder(label: 'No embed registered for "${node.type}"');
  }
}

/// The default look for content no embed understood: a small neutral placeholder, removable unless read-only.
Widget defaultUnknownEmbedBuilder(BuildContext context, StoryEmbedContext<UnknownEmbedValue> embed) {
  return _Placeholder(
    key: ValueKey('story-embed-unknown-${embed.nodeId}'),
    label: 'Unsupported content',
    onRemove: embed.readOnly ? null : embed.remove,
  );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({super.key, required this.label, this.onRemove});

  final String label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.help_outline, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label, style: TextStyle(color: colors.onSurfaceVariant)),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Remove',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
