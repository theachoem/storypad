/// Public API for the storypad_editor package.
///
/// A controller-centric rich text editor built on super_editor. Each custom embed is one object; all embeds are passed
/// into one controller, and the controller is passed to the editor widgets. Everything under `lib/src/` is private;
/// only what's exported here is API.
///
/// Grouped in reading order: start with the editor and its controller, then what plugs into them.
library;

// Start here: the editor widget and the controller it shows.
export 'src/controller/story_editor_actions.dart';
export 'src/controller/story_editor_controller.dart';
export 'src/widgets/editor/markdown_editor.dart';
export 'src/widgets/editor/raw_editor.dart';
export 'src/widgets/editor/story_editor_layout.dart';

// Conversion without an editor: Markdown and Quill in and out, page titles, plain text.
export 'src/codec/story_codec.dart';

// Embeds: the app's own blocks (photos, audio, …) and the catch-all for ones nothing reads.
export 'src/embed/quill_embed_op.dart';
export 'src/embed/story_embed.dart';
export 'src/embed/story_embed_attribute.dart';
export 'src/embed/story_embed_codec.dart';
export 'src/embed/story_embed_context.dart';
export 'src/embed/story_embed_node.dart';
export 'src/embed/story_embed_registry.dart';
export 'src/embed/story_html_element.dart';
export 'src/embed/unknown_embed_codec.dart';
export 'src/embed/unknown_embed_value.dart';

// Look: spacing between blocks and frames around them.
export 'src/widgets/style/block_spacing.dart';
export 'src/widgets/style/story_block_style.dart';
export 'src/widgets/style/story_editor_spacing.dart';

// Menus and links: extra context-menu actions, the desktop menu, tapped links.
export 'src/widgets/input/story_link_tap_handler.dart' show LinkTapCallback;
export 'src/widgets/menus/desktop/desktop_context_menu.dart' show DesktopContextMenu, DesktopContextMenuHandler;
export 'src/widgets/menus/desktop/desktop_context_menu_action.dart';
export 'src/widgets/menus/desktop/desktop_context_menu_request.dart';
export 'src/widgets/menus/story_context_menu_action.dart';

// What converting a Quill page would drop (see `StoryCodec.quillImportLosses`).
export 'src/quill/quill_import_loss.dart';
export 'src/quill/quill_import_loss_kind.dart';
