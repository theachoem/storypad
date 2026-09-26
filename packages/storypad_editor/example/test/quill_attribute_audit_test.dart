import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

/// Every Quill attribute and embed key in the real-shape fixtures is either converted to Markdown or on an explicit
/// list of accepted losses. A fixture refreshed from real data with a new key fails here, instead of that formatting
/// silently disappearing in the migration.
void main() {
  // Converted by the package's Quill import.
  const inline = {'bold', 'italic', 'underline', 'strike', 'code', 'color', 'background', 'script', 'link'};
  const block = {'header', 'blockquote', 'code-block', 'list', 'indent', 'align'};
  // Converted by the demo embeds.
  const embedKeys = {'media', 'image', 'audio', 'date'};
  const embedAttributes = {'custom-embed-size', 'custom-embed-alignment'};

  // Accepted losses: Markdown has no place for them, and StoryPad's toolbar never set them.
  const dropped = {'size', 'font', 'direction'};

  test('every attribute and embed key is converted or explicitly dropped', () {
    final unknown = <String>{};
    final unknownEmbedKeys = <String>{};

    for (final MapEntry(key: name, value: ops) in loadQuillFixtures().entries) {
      for (final op in ops.cast<Map<String, Object?>>()) {
        final insert = op['insert'];
        final attributes = (op['attributes'] as Map<String, Object?>?) ?? const {};
        final known = insert is Map ? {...embedAttributes, ...block} : {...inline, ...block};
        for (final key in attributes.keys) {
          if (!known.contains(key) && !dropped.contains(key)) unknown.add('$name: $key');
        }
        if (insert is Map) {
          for (final key in insert.keys) {
            if (!embedKeys.contains(key)) unknownEmbedKeys.add(key);
          }
        }
      }
    }

    expect(unknown, isEmpty, reason: 'Unhandled Quill attributes');
    // An unknown embed key is preserved losslessly (<sp-unknown>), but should be a deliberate choice.
    expect(unknownEmbedKeys, {'sticker'});
  });

  test('alignment on list and task lines is dropped (lists have no alignment in Markdown)', () {
    final alignedListLines = [
      for (final MapEntry(key: name, value: ops) in loadQuillFixtures().entries)
        for (final op in ops.cast<Map<String, Object?>>())
          if (op['attributes'] case {'list': _, 'align': _}) name,
    ];
    // None in the fixtures. If real data has many, revisit: it would need a list-item alignment representation.
    expect(alignedListLines, isEmpty);
  });
}
