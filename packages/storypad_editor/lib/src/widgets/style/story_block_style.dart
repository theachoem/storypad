import 'package:flutter/material.dart';

/// How a block type is framed: a box [decoration] (background, border, corners) and the [padding] between the frame
/// and the block's content -- e.g. a quote's tinted box with its text inset from the edges.
///
/// Space *between* blocks is `RawEditor.spacing` (see `StoryEditorSpacing`), outside the frame.
@immutable
final class StoryBlockStyle {
  const StoryBlockStyle({this.decoration, this.padding = EdgeInsets.zero});

  final BoxDecoration? decoration;
  final EdgeInsets padding;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is StoryBlockStyle && decoration == other.decoration && padding == other.padding;

  @override
  int get hashCode => Object.hash(decoration, padding);
}
