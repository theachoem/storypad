import 'package:storypad_editor/storypad_editor.dart';

/// StoryPad's voice note embed. The value is the relative audio path, e.g. `audio/1762500783747.m4a`.
///
/// - Quill: `{"audio": "audio/….m4a"}`.
/// - Markdown: `<audio controls src="audio/….m4a"></audio>`.
class AudioEmbed extends StoryEmbedCodec<String> {
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
  String? fromHtml(StoryHtmlElement element) {
    final src = element['src'];
    return src == null || src.isEmpty ? null : src;
  }

  @override
  StoryHtmlElement toHtml(String value) => StoryHtmlElement('audio', attributes: {'controls': '', 'src': value});
}
