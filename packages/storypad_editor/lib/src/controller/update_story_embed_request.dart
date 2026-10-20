import 'package:super_editor/super_editor.dart';

import '../embed/story_embed_node.dart';

/// Replaces an embed node in place (same id), as an undoable edit that reports a node *change*.
///
/// Not super_editor's `ReplaceNodeRequest`, which reports a removal plus an insertion -- enough to trigger reactions
/// that respond to deleted nodes.
class UpdateStoryEmbedRequest implements EditRequest {
  const UpdateStoryEmbedRequest(this.node);

  final StoryEmbedNode node;
}
