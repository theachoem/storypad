import '../markdown/markdown_format.dart';
import 'quill_import_loss.dart';
import 'quill_import_loss_kind.dart';
import 'quill_importer.dart';

/// Finds the formatting `QuillImporter` drops from Quill ops, by applying the same rules it does. Keep the two in
/// step: the property test "no losses ⇒ the Quill round trip is equivalent" checks they agree.
class QuillImportLossFinder {
  const QuillImportLossFinder();

  static const _flags = {'bold', 'italic', 'underline', 'strike', 'code'};
  static const _colors = {'color', 'background'};
  static const _blockKeys = {'header', 'list', 'blockquote', 'code-block', 'align', 'indent'};
  static const _lists = {'bullet', 'ordered', 'checked', 'unchecked'};
  static const _aligns = {'left', 'center', 'right', 'justify'};
  static final _hexColor = RegExp(r'^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');

  /// Inline formats: invisible on a line's `\n`, so dropping them there loses nothing.
  static const _inlineKeys = {..._flags, ..._colors, 'script', 'link', 'font', 'size', 'small'};

  List<QuillImportLoss> find(List<Object?> ops) {
    final losses = <QuillImportLoss>[];
    for (final op in ops) {
      if (!_isWellFormed(op)) losses.add(const QuillImportLoss(QuillImportLossKind.invalidOp, line: 0));
    }
    // Invalid ops are reported at line 0: sanitizing removes them before lines are counted.

    var line = 0;
    var segments = <Map<String, Object?>>[];
    for (final op in QuillImporter.sanitize(ops)) {
      if (op['insert'] == '\n') {
        _checkLine(line, segments, _attributes(op), losses);
        segments = [];
        line++;
      } else {
        segments.add(op);
      }
    }
    if (segments.isNotEmpty) _checkLine(line, segments, const {}, losses);
    return losses;
  }

  static bool _isWellFormed(Object? op) {
    if (op is! Map) return false;
    final attributes = op['attributes'];
    if (attributes != null && attributes is! Map) return false;
    final insert = op['insert'];
    return insert is String || insert is Map;
  }

  static Map<String, Object?> _attributes(Map<String, Object?> op) {
    final attributes = op['attributes'];
    return attributes is Map ? Map<String, Object?>.from(attributes) : const {};
  }

  void _checkLine(
    int line,
    List<Map<String, Object?>> segments,
    Map<String, Object?> block,
    List<QuillImportLoss> losses,
  ) {
    void loss(QuillImportLossKind kind, String key, Object? value) =>
        losses.add(QuillImportLoss(kind, line: line, key: key, value: value));

    // Block attributes, read with the importer's precedence: code > task/list > header > quote.
    for (final MapEntry(:key, :value) in block.entries) {
      if (!_blockKeys.contains(key) && !_inlineKeys.contains(key) && value != null) {
        loss(QuillImportLossKind.unsupportedAttribute, key, value);
      }
    }

    final code = _isSet(block['code-block']);
    final listValue = block['list'];
    final list = _lists.contains(listValue);
    final headerValue = block['header'];
    final header = headerValue is int && headerValue >= 1 && headerValue <= 6;
    final quote = _isSet(block['blockquote']);

    if (listValue != null && !list) loss(QuillImportLossKind.invalidAttributeValue, 'list', listValue);
    if (headerValue != null && !header) loss(QuillImportLossKind.invalidAttributeValue, 'header', headerValue);
    if (code && block['code-block'] != true) {
      loss(QuillImportLossKind.attributeValueDropped, 'code-block', block['code-block']);
    }

    final _Kind kind;
    if (code) {
      kind = _Kind.code;
      if (list) loss(QuillImportLossKind.conflictingBlockFormat, 'list', listValue);
      if (header) loss(QuillImportLossKind.conflictingBlockFormat, 'header', headerValue);
      if (quote) loss(QuillImportLossKind.conflictingBlockFormat, 'blockquote', block['blockquote']);
    } else if (list) {
      kind = _Kind.list;
      if (header) loss(QuillImportLossKind.conflictingBlockFormat, 'header', headerValue);
      if (quote) loss(QuillImportLossKind.conflictingBlockFormat, 'blockquote', block['blockquote']);
    } else if (header) {
      kind = _Kind.paragraph;
      if (quote) loss(QuillImportLossKind.conflictingBlockFormat, 'blockquote', block['blockquote']);
    } else {
      kind = quote ? _Kind.quote : _Kind.paragraph;
    }

    final alignValue = block['align'];
    final align = alignValue is String && _aligns.contains(alignValue) && alignValue != 'left' ? alignValue : null;
    if (alignValue != null && !(alignValue is String && _aligns.contains(alignValue))) {
      loss(QuillImportLossKind.invalidAttributeValue, 'align', alignValue);
    } else if (align != null && kind == _Kind.code) {
      loss(QuillImportLossKind.alignmentDropped, 'align', alignValue);
    }

    final indentValue = block['indent'];
    final indent = _intValue(indentValue);
    if (indentValue != null && (indent == null || indent < 0)) {
      loss(QuillImportLossKind.invalidAttributeValue, 'indent', indentValue);
    } else if (indent != null && indent > 0) {
      if (kind == _Kind.code) {
        loss(QuillImportLossKind.indentDropped, 'indent', indentValue);
      } else if (indent > MarkdownFormat.maxIndent) {
        loss(QuillImportLossKind.attributeValueDropped, 'indent', indentValue);
      }
    }

    // Inline attributes on text; embeds carry their own attributes (their embed reads them).
    var hasEmbed = false;
    final reported = <String>{};
    for (final segment in segments) {
      if (segment['insert'] is! String) {
        hasEmbed = true;
        continue;
      }
      for (final MapEntry(:key, :value) in _attributes(segment).entries) {
        if (value == null || reported.contains(key)) continue;
        final kept = _inlineLoss(key, value, (kind, value) {
          reported.add(key);
          loss(kind, key, value);
        });
        if (kept && kind == _Kind.code && value != false) {
          reported.add(key);
          loss(QuillImportLossKind.formattingInCode, key, value);
        }
      }
    }

    final hasBlockFormat = code || list || header || quote || align != null || (indent != null && indent > 0);
    if (hasEmbed && hasBlockFormat) {
      losses.add(QuillImportLoss(QuillImportLossKind.embedLineFormat, line: line, value: block));
    }
  }

  /// Reports a dropped inline attribute through [report] and returns false, or returns true if it's kept.
  static bool _inlineLoss(String key, Object value, void Function(QuillImportLossKind kind, Object value) report) {
    final bool valid;
    if (_flags.contains(key)) {
      valid = value == true || value == false;
    } else if (_colors.contains(key)) {
      valid = value is String && _hexColor.hasMatch(value.trim());
    } else if (key == 'script') {
      valid = value == 'super' || value == 'sub';
    } else if (key == 'link') {
      valid = value is String && value.isNotEmpty;
    } else {
      report(QuillImportLossKind.unsupportedAttribute, value);
      return false;
    }
    if (!valid) report(QuillImportLossKind.invalidAttributeValue, value);
    return valid;
  }

  static bool _isSet(Object? value) => value != null && value != false;

  static int? _intValue(Object? value) => switch (value) {
    null => null,
    int() => value,
    num() => value.toInt(),
    String() => int.tryParse(value),
    _ => null,
  };
}

enum _Kind { paragraph, quote, list, code }
