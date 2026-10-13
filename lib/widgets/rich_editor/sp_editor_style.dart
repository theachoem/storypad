import 'package:flutter/material.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/super_editor.dart';

/// How story text looks in the editor: the story's theme (font, weight, colors, and text scale from its preferences),
/// 16 for body text as in Quill, and a heading scale of its own (a page title is a plain `###` heading).
class SpEditorStyle {
  SpEditorStyle(BuildContext context)
    : _colorScheme = ColorScheme.of(context),
      _base = DefaultTextStyle.of(context).style,
      _isCupertino = Theme.of(context).platform == .iOS || Theme.of(context).platform == .macOS;

  // ── Spacing: tune here ──────────────────────────────────────────────────────────────────────────────────────────

  /// The space around the page and each block:
  /// - Paragraphs: none, so a new line sits exactly where a wrapped one would -- as in Quill. Blank lines are how a
  ///   writer spaces text out.
  /// - List items and tasks: 6 below each, as in Quill, so their markers and checkboxes don't touch.
  /// - Headings: set apart from the text above, a little closer to what they head. A page title (the first block) only
  ///   gets the space below, before the body.
  /// - Quotes, code blocks, audio and date blocks: set apart from the text around. Photos and videos a little more, so
  ///   no empty line is needed to space them out (pages from before Markdown drop the ones they had, see
  ///   `StoryCodec.quillPageToMarkdown`).
  /// Between two blocks the larger of their spaces applies (collapsed, not added up), and none at the page's edges:
  /// there, the page padding alone.
  static const spacing = StoryEditorSpacing(
    page: EdgeInsets.only(top: 4, left: 12, bottom: 20, right: 12),
    text: BlockSpacing.zero,
    heading: BlockSpacing.only(top: 12, bottom: 8),
    block: BlockSpacing.all(8),
    byType: {
      'listItem': BlockSpacing.only(bottom: 6),
      'task': BlockSpacing.only(bottom: 6),
      'media': BlockSpacing.all(12),
    },
  );

  /// [spacing] on a page shown as a card (the list and grid layouts): as much space below the content as above it
  /// (the page's 8 above the editor plus its 4) and beside it, rather than the extra room a full page leaves below its
  /// last line.
  static final cardSpacing = spacing.copyWith(page: const EdgeInsets.only(top: 4, left: 12, bottom: 12, right: 12));

  /// Heading levels 1-6: (size, weight, line height, letter spacing). Body text is 16. The toolbar offers levels 1-3;
  /// a page title is level 3.
  static const headings = [
    (26.0, FontWeight.w700, 1.2, -0.4),
    (22.0, FontWeight.w700, 1.25, -0.3),
    (19.0, FontWeight.w600, 1.3, -0.2),
    (17.0, FontWeight.w600, 1.3, 0.0),
    (16.0, FontWeight.w600, 1.35, 0.0),
    (14.0, FontWeight.w600, 1.35, 0.2),
  ];

  /// The widest a full-size photo, video or album gets (centered past it), so it stays a sensible size on a wide
  /// desktop window.
  static const maxMediaWidth = 640.0;

  /// Space inside a quote's frame, around its text.
  static const quotePadding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  /// Space inside a code block's frame, around its text.
  static const codePadding = EdgeInsets.all(12);

  // ────────────────────────────────────────────────────────────────────────────────────────────────────────────────

  final ColorScheme _colorScheme;
  final TextStyle _base;
  final bool _isCupertino;

  /// Merged into every block: the story's font and color, no size (each block type sets its own).
  late final TextStyle baseTextStyle = TextStyle(
    fontFamily: _base.fontFamily,
    fontFamilyFallback: _base.fontFamilyFallback,
    fontWeight: _base.fontWeight,
    color: _base.color ?? _colorScheme.onSurface,
    decoration: TextDecoration.none,
  );

  TextStyle get placeholderStyle => baseTextStyle.copyWith(
    fontSize: 16,
    height: 1.15,
    color: _colorScheme.onSurface.withValues(alpha: 0.5),
  );

  late final List<StyleRule> styleRules = [
    for (final selector in const ['paragraph', 'listItem', 'task', 'blockquote'])
      StyleRule(
        BlockSelector(selector),
        (document, node) => {Styles.textStyle: const TextStyle(fontSize: 16, height: 1.15)},
      ),
    for (final (index, (fontSize, fontWeight, height, letterSpacing)) in headings.indexed)
      StyleRule(
        BlockSelector('header${index + 1}'),
        (document, node) => {
          Styles.textStyle: TextStyle(
            fontSize: fontSize,
            height: height,
            letterSpacing: letterSpacing,
            fontWeight: fontWeight,
            // The smallest heading is set apart by weight, and a softer color than body text.
            color: index == 5 ? _colorScheme.onSurface.withValues(alpha: 0.7) : null,
          ),
        },
      ),
    StyleRule(
      const BlockSelector('blockquote'),
      (document, node) => {
        Styles.textStyle: TextStyle(color: _colorScheme.onSurface.withValues(alpha: 0.8)),
      },
    ),
    StyleRule(
      const BlockSelector('code'),
      (document, node) => {
        Styles.textStyle: TextStyle(fontSize: 13, height: 1.15, fontFamily: _isCupertino ? 'Menlo' : 'Roboto Mono'),
      },
    ),
  ];

  /// The frames around quotes and code blocks, with the space inside them.
  late final Map<String, StoryBlockStyle> blockStyles = {
    'blockquote': StoryBlockStyle(
      decoration: BoxDecoration(
        color: _colorScheme.onSurface.withValues(alpha: 0.04),
        border: Border(left: BorderSide(color: _colorScheme.onSurface.withValues(alpha: 0.25), width: 3)),
      ),
      padding: quotePadding,
    ),
    'code': StoryBlockStyle(
      decoration: BoxDecoration(
        color: _colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: codePadding,
    ),
  };
}
