import 'package:flutter_quill/flutter_quill.dart';

class EmbedSizeAttribute extends Attribute<String> {
  const EmbedSizeAttribute(String value) : super('custom-embed-size', AttributeScope.embeds, value);

  static EmbedSizeAttribute get defaultSize => const EmbedSizeAttribute('default');
  static EmbedSizeAttribute get maxSize => const EmbedSizeAttribute('max');

  bool hasApplied(Embed node) {
    return node.style.attributes[key]?.value == value;
  }

  static void toggle(QuillController controller, Embed node) {
    final existingValue = node.style.attributes['custom-embed-size']?.value ?? EmbedSizeAttribute.defaultSize.value;

    switch (existingValue) {
      case 'max':
        node.applyAttribute(EmbedSizeAttribute.defaultSize);
        break;
      case 'default':
      default:
        node.applyAttribute(EmbedSizeAttribute.maxSize);
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
