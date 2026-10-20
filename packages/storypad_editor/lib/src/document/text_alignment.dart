import 'dart:ui' show TextAlign;

import 'package:super_editor/super_editor.dart';

/// Text alignment as a node holds it: its `textAlign` metadata (`left`, `center`, `right` or `justify`), like
/// super_editor's.
class TextAlignment {
  const TextAlignment._();

  /// The `textAlign` metadata value for [alignment].
  static String name(TextAlign alignment) => switch (alignment) {
    TextAlign.center => 'center',
    TextAlign.right || TextAlign.end => 'right',
    TextAlign.justify => 'justify',
    TextAlign.left || TextAlign.start => 'left',
  };

  /// The alignment in [node]'s `textAlign` metadata, or `null` if it has none (or an unknown one).
  static TextAlign? of(DocumentNode node) => switch (node.getMetadataValue(TextNodeMetadata.textAlign)) {
    'left' => TextAlign.left,
    'center' => TextAlign.center,
    'right' => TextAlign.right,
    'justify' => TextAlign.justify,
    _ => null,
  };
}
