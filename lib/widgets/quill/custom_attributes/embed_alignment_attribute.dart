import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';

class EmbedAlignmentAttribute extends Attribute<String?> {
  const EmbedAlignmentAttribute(String? value) : super('custom-embed-alignment', AttributeScope.embeds, value);

  static EmbedAlignmentAttribute get none => const EmbedAlignmentAttribute(null);
  static EmbedAlignmentAttribute get left => const EmbedAlignmentAttribute('left');
  static EmbedAlignmentAttribute get center => const EmbedAlignmentAttribute('center');
  static EmbedAlignmentAttribute get right => const EmbedAlignmentAttribute('right');

  bool hasApplied(Embed node) {
    return node.style.attributes[key]?.value == value;
  }

  static Alignment? toAlignment(Embed node) {
    switch (node.style.attributes[none.key]?.value) {
      case 'center':
        return Alignment.center;
      case 'right':
        return Alignment.centerRight;
      case 'left':
        return Alignment.centerLeft;
      default:
        return null;
    }
  }

  void toggle(QuillController controller, Embed node) {
    if (hasApplied(node)) {
      node.applyAttribute(none);
    } else {
      node.applyAttribute(this);
    }

    controller.replaceText(
      node.documentOffset,
      node.length,
      node.toDelta(),
      controller.selection,
    );
  }

  void apply(QuillController controller, Embed node) {
    node.applyAttribute(this);
    controller.replaceText(
      node.documentOffset,
      node.length,
      node.toDelta(),
      controller.selection,
    );
  }
}
