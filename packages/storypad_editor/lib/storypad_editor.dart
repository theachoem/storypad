/// Public API for the storypad_editor package.
///
/// A controller-centric rich text editor built on super_editor. Each custom embed is one object; all embeds are passed
/// into one controller, and the controller is passed to the editor widgets. Everything under `lib/src/` is private;
/// only what's exported here is API.
library;

export 'src/codec/story_codec.dart';
export 'src/controller/change_text_alignment_request.dart' show ChangeTextAlignmentRequest;
export 'src/controller/story_editor_actions.dart';
export 'src/controller/story_editor_controller.dart';
export 'src/embed/quill_embed_op.dart';
export 'src/embed/story_embed.dart';
export 'src/embed/story_embed_attribute.dart';
export 'src/embed/story_embed_codec.dart';
export 'src/embed/story_embed_node.dart';
export 'src/embed/story_embed_registry.dart';
export 'src/embed/story_html_element.dart';
export 'src/embed/unknown_embed.dart';
export 'src/quill/quill_exporter.dart' show quillColor;
export 'src/quill/quill_import_losses.dart' show QuillImportLoss, QuillImportLossKind;
export 'src/widgets/block_frame.dart' show StoryBlockStyle;
export 'src/widgets/context_menu_action.dart';
export 'src/widgets/desktop_context_menu.dart'
    show DesktopContextMenuAction, DesktopContextMenuHandler, DesktopContextMenuRequest, showDefaultDesktopContextMenu;
export 'src/widgets/link_tap_handler.dart' show LinkTapCallback;
export 'src/widgets/markdown_editor.dart';
export 'src/widgets/raw_editor.dart';
export 'src/widgets/story_embed_component.dart' show defaultUnknownEmbedBuilder;
