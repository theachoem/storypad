import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import '../../controller/story_editor_controller.dart';
import '../../embed/story_embed.dart';
import '../../embed/story_embed_node.dart';
import 'story_embed_component.dart';
import 'story_embed_view_model.dart';

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
