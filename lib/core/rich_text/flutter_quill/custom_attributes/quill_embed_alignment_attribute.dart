part of '../quill_adapter.dart';

class _EmbedAlignmentAttribute extends quill.Attribute<String?> {
  const _EmbedAlignmentAttribute(String? value) : super('custom-embed-alignment', quill.AttributeScope.embeds, value);

  static _EmbedAlignmentAttribute get none => const _EmbedAlignmentAttribute(null);
  static _EmbedAlignmentAttribute get left => const _EmbedAlignmentAttribute('left');
  static _EmbedAlignmentAttribute get center => const _EmbedAlignmentAttribute('center');
  static _EmbedAlignmentAttribute get right => const _EmbedAlignmentAttribute('right');

  bool hasApplied(quill.Embed node) {
    return node.style.attributes[key]?.value == value;
  }

  static Alignment? toAlignment(quill.Embed node) {
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

  void toggle(quill.QuillController controller, quill.Embed node) {
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

  void apply(quill.QuillController controller, quill.Embed node) {
    node.applyAttribute(this);
    controller.replaceText(
      node.documentOffset,
      node.length,
      node.toDelta(),
      controller.selection,
    );
  }
}
