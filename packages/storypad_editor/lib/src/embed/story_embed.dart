import 'package:flutter/widgets.dart';

import '../controller/story_editor_controller.dart';
import 'story_embed_codec.dart';
import 'story_embed_node.dart';

/// Builds an embed's widget. See [StoryEmbed.build].
typedef StoryEmbedBuilder<T extends Object> = Widget Function(BuildContext context, StoryEmbedContext<T> embed);

/// One kind of embed, complete: its Quill/Markdown codec (see [StoryEmbedCodec]) plus how it looks in the editor.
/// Pass every embed to the [StoryEditorController]; the editor renders each embed node through its [build].
///
/// ```dart
/// class DateEmbed extends StoryEmbed<DateTime> {
///   const DateEmbed();
///
///   // … type, quillKeys, htmlTags, fromQuill, fromHtml, toHtml (see StoryEmbedCodec) …
///
///   @override
///   Widget build(BuildContext context, StoryEmbedContext<DateTime> embed) {
///     return DateChip(date: embed.value, onRemove: embed.readOnly ? null : embed.remove);
///   }
/// }
/// ```
///
/// Apps never write super_editor component builders, view models or nodes for an embed: the editor hosts [build]'s
/// widget, paints selection over it, and rebuilds it when its value, selection state or the editor's read-only mode
/// changes.
abstract class StoryEmbed<T extends Object> extends StoryEmbedCodec<T> {
  const StoryEmbed();

  /// The embed's widget. [embed] carries the value and the operations on it (update, remove). Read app state from
  /// [context] as usual (e.g. `context.watch`), so the widget rebuilds when that state changes too.
  Widget build(BuildContext context, StoryEmbedContext<T> embed);

  /// Builds [node] (one of this embed's nodes), typed. Used by the editor; not for overriding.
  Widget buildNode(
    BuildContext context,
    StoryEmbedNode node, {
    required StoryEditorController controller,
    required bool isSelected,
  }) {
    return build(
      context,
      StoryEmbedContext<T>(
        nodeId: node.id,
        value: valueOf(node),
        isSelected: isSelected,
        controller: controller,
        embed: this,
      ),
    );
  }
}

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
