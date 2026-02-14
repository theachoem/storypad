part of '../quill_adapter.dart';

class _EmbedSizeAttribute extends quill.Attribute<String> {
  const _EmbedSizeAttribute(String value) : super('custom-embed-size', quill.AttributeScope.embeds, value);

  static _EmbedSizeAttribute get defaultSize => const _EmbedSizeAttribute('default');
  static _EmbedSizeAttribute get maxSize => const _EmbedSizeAttribute('max');

  bool hasApplied(quill.Embed node) {
    return node.style.attributes[key]?.value == value;
  }

  static void toggle(quill.QuillController controller, quill.Embed node) {
    final existingValue = node.style.attributes['custom-embed-size']?.value ?? _EmbedSizeAttribute.defaultSize.value;

    switch (existingValue) {
      case 'max':
        node.applyAttribute(_EmbedSizeAttribute.defaultSize);
        break;
      case 'default':
      default:
        node.applyAttribute(_EmbedSizeAttribute.maxSize);
        break;
    }

    controller.replaceText(
      node.documentOffset,
      node.length,
      node.toDelta(),
      controller.selection,
    );
  }
}
