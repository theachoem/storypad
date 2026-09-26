import 'package:storypad_editor/storypad_editor.dart';

/// Layout attributes StoryPad's media embed carries, as typed attributes: one definition each for the Quill attribute
/// they're imported from and the HTML attribute they're stored as.

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
