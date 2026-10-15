import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:super_editor/super_editor.dart';

import 'block_frame.dart';

/// Space above and below one block, outside any frame it has (see [StoryBlockStyle] for the space inside one).
@immutable
final class BlockSpacing {
  const BlockSpacing.only({this.top = 0, this.bottom = 0});

  const BlockSpacing.all(double space) : top = space, bottom = space;

  static const zero = BlockSpacing.only();

  final double top;
  final double bottom;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BlockSpacing && top == other.top && bottom == other.bottom;

  @override
  int get hashCode => Object.hash(top, bottom);

  @override
  String toString() => 'BlockSpacing(top: $top, bottom: $bottom)';
}

/// All the editor's spacing in one place: around the document ([page]), and above and below each block, by kind --
/// lines of text, headings, and every other block -- with per-type overrides.
///
/// - Between two blocks, the space is the larger of the one's space below and the other's above -- collapsed, as
///   margins are on the web, not added up. Each value is "at least this much room", e.g. a photo after a title is as
///   far from it as the photo's own space, not that plus the title's.
/// - The document's first block never gets space above it, nor its last block space below it, so the content sits
///   exactly [page] in from the edges -- a lone heading (a page title) as evenly as a lone paragraph.
/// - Side space is [page] alone: blocks get none of their own, so every block type lines up.
/// - Space inside a frame (a quote's or code block's box) is the frame's own, [StoryBlockStyle.padding].
///
/// Applied before the editor's `styleRules`, so a rule there can still override `Styles.padding` for a block.
@immutable
final class StoryEditorSpacing {
  const StoryEditorSpacing({
    this.page,
    this.text = const BlockSpacing.all(2),
    this.heading = const BlockSpacing.all(2),
    this.block = const BlockSpacing.all(2),
    this.byType = const {},
  });

  /// Around the document. `null`: 16 all round (18 on the left on desktop/web, room for the drag handle).
  final EdgeInsets? page;

  /// Lines of text: paragraphs, list items, tasks.
  final BlockSpacing text;

  /// Headings (`header1` … `header6`).
  final BlockSpacing heading;

  /// Every other block: quotes, code blocks, dividers, images and embeds.
  final BlockSpacing block;

  /// Per block type (e.g. `media`, `blockquote`, `header1`), over the kind it belongs to.
  final Map<String, BlockSpacing> byType;

  static const _textTypes = {'paragraph', 'listItem', 'task'};

  /// The space [node] asks for, by its kind (before collapsing and the document's edges).
  BlockSpacing _wanted(DocumentNode node) {
    final type = blockTypeOf(node) ?? (node is ParagraphNode ? 'paragraph' : '');
    return byType[type] ??
        (_textTypes.contains(type)
            ? text
            : type.startsWith('header')
            ? heading
            : block);
  }

  /// The space laid out around [node], in [document]: each block keeps its space below, and above it gets only what
  /// the block before doesn't already give (so the gap between them is the larger of the two). None at the edges.
  BlockSpacing of(Document document, DocumentNode node) {
    final wanted = _wanted(node);
    final previous = document.getNodeBeforeById(node.id);
    return BlockSpacing.only(
      top: previous == null ? 0 : max(0, wanted.top - _wanted(previous).bottom),
      // `document.last` would walk the whole document, for every node styled.
      bottom: document.getNodeAfterById(node.id) == null ? 0 : wanted.bottom,
    );
  }

  /// The stylesheet rule giving each block its space.
  StyleRule toStyleRule() {
    return StyleRule(BlockSelector.all, (document, node) {
      final spacing = of(document, node);
      return {Styles.padding: CascadingPadding.only(left: 0, right: 0, top: spacing.top, bottom: spacing.bottom)};
    });
  }

  StoryEditorSpacing copyWith({
    EdgeInsets? page,
    BlockSpacing? text,
    BlockSpacing? heading,
    BlockSpacing? block,
    Map<String, BlockSpacing>? byType,
  }) {
    return StoryEditorSpacing(
      page: page ?? this.page,
      text: text ?? this.text,
      heading: heading ?? this.heading,
      block: block ?? this.block,
      byType: byType ?? this.byType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryEditorSpacing &&
          page == other.page &&
          text == other.text &&
          heading == other.heading &&
          block == other.block &&
          mapEquals(byType, other.byType);

  @override
  int get hashCode => Object.hash(
    page,
    text,
    heading,
    block,
    Object.hashAllUnordered(byType.entries.map((entry) => Object.hash(entry.key, entry.value))),
  );
}
