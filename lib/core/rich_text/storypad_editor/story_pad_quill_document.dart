import 'package:storypad/core/rich_text/rich_text_document.dart';
import 'package:storypad/core/rich_text/storypad_editor/story_pad_embeds.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/super_editor.dart';

/// A stored page body (Quill Delta JSON) read without an editor, e.g. for its plain text.
class StoryPadQuillDocument implements RichTextDocument {
  StoryPadQuillDocument(this._json);

  final List<dynamic> _json;

  late final List<DocumentNode> _nodes = storyPadCodec.decodeQuill(_json);

  @override
  int get length => _nodes.fold(0, (sum, node) => sum + (node is TextNode ? node.text.length : 1) + 1);

  @override
  List<dynamic> toJson() => _json;

  @override
  String toPlainText() => StoryCodec.plainTextOf(_nodes);
}
