import '../controller/story_editor_controller.dart';
import 'story_embed.dart';
import 'story_embed_codec.dart';

/// What an embed's [StoryEmbed.build] gets: its value, its state in the editor, and operations on itself.
final class StoryEmbedContext<T extends Object> {
  StoryEmbedContext({
    required this.nodeId,
    required this.value,
    required this.isSelected,
    required this.controller,
    required StoryEmbedCodec<T> embed,
  }) : _embed = embed;

  /// The embed's document node id.
  final String nodeId;

  /// The value when this widget was built. [update] always works from the live value, not this snapshot.
  final T value;

  /// Whether the embed is (wholly) inside the user's selection, e.g. after select-all or a shift-arrow. The editor
  /// already paints a selection highlight over the embed; this is for embeds that want to show more.
  final bool isSelected;

  final StoryEditorController controller;

  final StoryEmbedCodec<T> _embed;

  /// Whether the editor is read-only. Embeds should hide editing controls (resize, remove, …) when it is.
  bool get readOnly => controller.readOnly;

  /// Replaces the embed's value with `transform(current)`, as an undoable edit. [transform] receives the *live* value
  /// at the moment of the call (not [value], which may be stale -- e.g. after an `await`, or on a fast double tap), so
  /// toggles stay correct. Returns `false` if the embed no longer exists, or the value didn't change.
  bool update(T Function(T current) transform) => controller.updateEmbed(_embed, nodeId, transform);

  /// Removes the embed from the document, as an undoable edit. Returns `false` if it no longer exists.
  bool remove() => controller.removeEmbed(nodeId);
}
