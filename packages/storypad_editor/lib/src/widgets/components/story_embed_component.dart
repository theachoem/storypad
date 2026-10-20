import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import '../../controller/story_editor_controller.dart';
import '../../embed/story_embed.dart';
import '../../embed/story_embed_context.dart';
import '../../embed/unknown_embed_codec.dart';
import '../../embed/unknown_embed_value.dart';
import 'story_embed_view_model.dart';

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
      final builder = controller.unknownBuilder ?? defaultUnknownBuilder;
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

  /// The default look for content no embed understood: a small neutral placeholder, removable unless read-only.
  static Widget defaultUnknownBuilder(BuildContext context, StoryEmbedContext<UnknownEmbedValue> embed) {
    return _Placeholder(
      key: ValueKey('story-embed-unknown-${embed.nodeId}'),
      label: 'Unsupported content',
      onRemove: embed.readOnly ? null : embed.remove,
    );
  }
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
