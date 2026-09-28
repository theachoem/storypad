import 'package:flutter/material.dart';
import 'package:storypad_editor/storypad_editor.dart';

/// StoryPad's voice note embed. The value is the relative audio path, e.g. `audio/1762500783747.m4a`.
///
/// - Quill: `{"audio": "audio/….m4a"}`.
/// - Markdown: `<audio controls src="audio/….m4a"></audio>`.
class AudioEmbed extends StoryEmbed<String> {
  const AudioEmbed();

  @override
  String get type => 'audio';

  @override
  Set<String> get quillKeys => const {'audio'};

  @override
  Set<String> get htmlTags => const {'audio'};

  @override
  String? fromQuill(QuillEmbedOp op) {
    final value = op.value;
    return value is String && value.isNotEmpty ? value : null;
  }

  @override
  QuillEmbedOp toQuill(String value) => QuillEmbedOp.of('audio', value);

  @override
  String? fromHtml(StoryHtmlElement element) {
    final src = element['src'];
    return src == null || src.isEmpty ? null : src;
  }

  @override
  StoryHtmlElement toHtml(String value) => StoryHtmlElement('audio', attributes: {'controls': '', 'src': value});

  @override
  Widget build(BuildContext context, StoryEmbedContext<String> embed) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.graphic_eq),
          const SizedBox(width: 8),
          Flexible(child: Text(embed.value.split('/').last, overflow: TextOverflow.ellipsis)),
          if (!embed.readOnly)
            IconButton(
              tooltip: 'Remove',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline),
              onPressed: embed.remove,
            ),
        ],
      ),
    );
  }
}
