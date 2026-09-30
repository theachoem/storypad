import 'package:flutter/material.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/super_editor.dart';

/// How story text looks in the editor: the story's theme (font, weight, colors, and text scale from its preferences),
/// with Quill's sizes so stories look as they did -- 16 for body text, 34/30/24/20/18/16 for headings.
class StoryPadEditorStyle {
  StoryPadEditorStyle(BuildContext context, {TextStyle? titleStyle})
    : _titleStyle = titleStyle,
      _colorScheme = ColorScheme.of(context),
      _base = DefaultTextStyle.of(context).style,
      _isCupertino = Theme.of(context).platform == .iOS || Theme.of(context).platform == .macOS;

  // ── Spacing: tune here ──────────────────────────────────────────────────────────────────────────────────────────

  /// Space above and below each line of text (paragraph, list item, task): two lines sit `2 × lineGap` apart.
  static const lineGap = 3.0;

  /// Space above and below quotes, code blocks and embeds (photos, audio), setting them apart from the text around.
  static const blockGap = 8.0;

  /// Space inside a quote's frame, around its text.
  static const quotePadding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  /// Space inside a code block's frame, around its text.
  static const codePadding = EdgeInsets.all(12);

  // ────────────────────────────────────────────────────────────────────────────────────────────────────────────────

  final TextStyle? _titleStyle;
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
        (document, node) => {
          Styles.textStyle: const TextStyle(fontSize: 16, height: 1.15),
          Styles.padding: const CascadingPadding.symmetric(vertical: lineGap, horizontal: 0.0),
        },
      ),
    for (final selector in const ['blockquote', 'code', 'media', 'audio', 'date'])
      StyleRule(
        BlockSelector(selector),
        (document, node) => {Styles.padding: const CascadingPadding.symmetric(vertical: blockGap)},
      ),
    for (final (level, fontSize, height, letterSpacing, topPadding) in const [
      (1, 34.0, 1.083, -0.5, 16.0),
      (2, 30.0, 1.067, -0.8, 8.0),
      (3, 24.0, 1.083, -0.5, 8.0),
      (4, 20.0, 1.1, -0.4, 6.0),
      (5, 18.0, 1.11, -0.2, 6.0),
      (6, 16.0, 1.125, -0.1, 4.0),
    ])
      StyleRule(
        BlockSelector('header$level'),
        (document, node) => {
          Styles.textStyle: TextStyle(
            fontSize: fontSize,
            height: height,
            letterSpacing: letterSpacing,
            fontWeight: FontWeight.bold,
          ),
          Styles.padding: CascadingPadding.only(top: topPadding),
        },
      ),
    StyleRule(
      const BlockSelector('blockquote'),
      (document, node) => {
        Styles.textStyle: TextStyle(color: _colorScheme.onSurface.withValues(alpha: 0.8)),
      },
    ),
    // The page title: a heading that's the page's first block (see StoryCodec.pageTitleOf), in the story's title font.
    if (_titleStyle case final titleStyle?)
      StyleRule(BlockSelector.all, (document, node) {
        if (!_isTitle(document, node)) return const {};
        return {
          Styles.textStyle: titleStyle.copyWith(letterSpacing: 0, height: 1.25),
          Styles.padding: const CascadingPadding.only(top: 0),
        };
      }),
    StyleRule(
      const BlockSelector('code'),
      (document, node) => {
        Styles.textStyle: TextStyle(fontSize: 13, height: 1.15, fontFamily: _isCupertino ? 'Menlo' : 'Roboto Mono'),
      },
    ),
  ];

  static bool _isTitle(Document document, DocumentNode node) {
    if (node is! ParagraphNode || document.getNodeIndexById(node.id) != 0) return false;
    final Object? blockType = node.getMetadataValue(NodeMetadata.blockType);
    return blockType is NamedAttribution && blockType.id.startsWith('header');
  }

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
