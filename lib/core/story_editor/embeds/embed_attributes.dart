import 'package:storypad_editor/storypad_editor.dart';

/// Layout attributes of the media embed, each defined once for both formats: the Quill op attribute stories are
/// stored with today, and the HTML attribute used in Markdown.

enum EmbedAlignment { none, left, center, right }

enum EmbedSize { normal, max }

const embedAlignment = StoryEmbedAttribute<EmbedAlignment>.enumeration(
  quillKey: 'custom-embed-alignment',
  htmlName: 'data-align',
  values: {EmbedAlignment.left: 'left', EmbedAlignment.center: 'center', EmbedAlignment.right: 'right'},
  fallback: EmbedAlignment.none,
);

const embedSize = StoryEmbedAttribute<EmbedSize>.enumeration(
  quillKey: 'custom-embed-size',
  htmlName: 'data-size',
  values: {EmbedSize.normal: 'default', EmbedSize.max: 'max'},
  fallback: EmbedSize.normal,
);
