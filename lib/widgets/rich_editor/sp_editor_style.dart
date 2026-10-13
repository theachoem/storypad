import 'package:flutter/material.dart';
import 'package:storypad_editor/storypad_editor.dart';
import 'package:storypad_editor/super_editor.dart';

/// How story text looks in the editor: the story's theme (font, weight, colors, and text scale from its preferences),
/// with Quill's sizes so stories look as they did -- 16 for body text, 34/30/24/20/18/16 for headings.
class SpEditorStyle {
  SpEditorStyle(BuildContext context)
    : _colorScheme = ColorScheme.of(context),
      _base = DefaultTextStyle.of(context).style,
      _isCupertino = Theme.of(context).platform == .iOS || Theme.of(context).platform == .macOS;

  // ── Spacing: tune here ──────────────────────────────────────────────────────────────────────────────────────────

  /// Space above and below each line of text (paragraph, list item, task, heading): none, so a new line sits exactly
  /// where a wrapped one would -- as in Quill. Blank lines are how a writer spaces text out.
  static const lineGap = 0.0;

  /// Space above and below quotes, code blocks, audio and date blocks, setting them apart from the text around. Photos
  /// and videos have none.
  static const blockGap = 8.0;

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
        (document, node) => {
          Styles.textStyle: const TextStyle(fontSize: 16, height: 1.15),
          Styles.padding: const CascadingPadding.symmetric(vertical: lineGap, horizontal: 0.0),
        },
      ),
    for (final selector in const ['blockquote', 'code', 'audio', 'date'])
      StyleRule(
        BlockSelector(selector),
        (document, node) => {Styles.padding: const CascadingPadding.symmetric(vertical: blockGap)},
      ),
    // Photos and videos sit flush against the lines around them, as they always have: no space above or below.
    StyleRule(
      const BlockSelector('media'),
      (document, node) => {Styles.padding: const CascadingPadding.symmetric(vertical: 0, horizontal: 0)},
    ),
    // Headings are spaced like any other line: only their text is bigger.
    for (final (level, fontSize, height, letterSpacing) in const [
      (1, 34.0, 1.083, -0.5),
      (2, 30.0, 1.067, -0.8),
      (3, 24.0, 1.083, -0.5),
      (4, 20.0, 1.1, -0.4),
      (5, 18.0, 1.11, -0.2),
      (6, 16.0, 1.125, -0.1),
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
          Styles.padding: const CascadingPadding.symmetric(vertical: lineGap, horizontal: 0.0),
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
