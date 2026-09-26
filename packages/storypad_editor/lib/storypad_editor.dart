/// Public API for the storypad_editor package.
///
/// A controller-centric rich text editor built on super_editor. Each custom embed is one object; all embeds are passed
/// into one controller, and the controller is passed to the editor widgets. Everything under `lib/src/` is private;
/// only what's exported here is API.
library;

export 'src/codec/story_codec.dart';
export 'src/embed/quill_embed_op.dart';
export 'src/embed/story_embed_attribute.dart';
export 'src/embed/story_embed_codec.dart';
export 'src/embed/story_embed_node.dart';
export 'src/embed/story_embed_registry.dart';
export 'src/embed/story_html_element.dart';
export 'src/embed/unknown_embed.dart';
