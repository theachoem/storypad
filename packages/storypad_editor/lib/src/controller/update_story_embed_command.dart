import 'package:super_editor/super_editor.dart';

import '../embed/story_embed_node.dart';

import 'update_story_embed_request.dart';

class UpdateStoryEmbedCommand extends EditCommand {
  const UpdateStoryEmbedCommand(this.node);

  final StoryEmbedNode node;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.document;
    if (document.getNodeById(node.id) is! StoryEmbedNode) return;

    document.replaceNodeById(node.id, node);
    executor.logChanges([DocumentEdit(NodeChangeEvent(node.id))]);
  }

  /// Turns a [UpdateStoryEmbedRequest] into this command; register with the editor's request handlers.
  static EditCommand? handler(Editor editor, EditRequest request) =>
      request is UpdateStoryEmbedRequest ? UpdateStoryEmbedCommand(request.node) : null;
}
