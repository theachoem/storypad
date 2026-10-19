import 'package:super_editor/super_editor.dart';

/// Headings as block types: `header1` … `header6`, and the level (1–6) each stands for.
class Heading {
  const Heading._();

  /// The heading level (1–6) for a block type, or `null` if it isn't a heading.
  static int? levelOf(Attribution? blockType) {
    if (blockType == header1Attribution) return 1;
    if (blockType == header2Attribution) return 2;
    if (blockType == header3Attribution) return 3;
    if (blockType == header4Attribution) return 4;
    if (blockType == header5Attribution) return 5;
    if (blockType == header6Attribution) return 6;
    return null;
  }

  /// The block type for a heading level (1–6).
  static Attribution blockType(int level) => switch (level) {
    1 => header1Attribution,
    2 => header2Attribution,
    3 => header3Attribution,
    4 => header4Attribution,
    5 => header5Attribution,
    _ => header6Attribution,
  };
}
