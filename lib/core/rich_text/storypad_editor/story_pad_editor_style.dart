import 'package:flutter/material.dart';
import 'package:storypad_editor/super_editor.dart';

/// How story text looks in the editor: the story's theme (font, weight, colors, and text scale from its preferences),
/// with Quill's sizes so stories look as they did -- 16 for body text, 34/30/24/20/18/16 for headings.
class StoryPadEditorStyle {
  StoryPadEditorStyle(BuildContext context)
    : _colorScheme = ColorScheme.of(context),
      _base = DefaultTextStyle.of(context).style,
      _isCupertino = Theme.of(context).platform == .iOS || Theme.of(context).platform == .macOS;

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
        Styles.backgroundColor: _colorScheme.onSurface.withValues(alpha: 0.05),
        Styles.borderRadius: BorderRadius.circular(4),
      },
    ),
    StyleRule(
      const BlockSelector('code'),
      (document, node) => {
        Styles.textStyle: TextStyle(fontSize: 13, height: 1.15, fontFamily: _isCupertino ? 'Menlo' : 'Roboto Mono'),
      },
    ),
  ];
}
