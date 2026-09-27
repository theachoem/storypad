import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:storypad_editor/storypad_editor.dart';

/// StoryPad's legacy date embed (read-only; nothing inserts it anymore).
///
/// - Quill: `{"date": "[{\"insert\":\"2024-01-01T00:00:00.000\\n\"}]"}` -- oddly, a JSON-encoded one-op mini Delta
///   whose insert is an ISO date. A malformed value is rejected, so the unknown embed preserves it as-is.
/// - Markdown: the semantic `<time datetime="…">…</time>`.
class DateEmbed extends StoryEmbed<DateTime> {
  const DateEmbed();

  @override
  String get type => 'date';

  @override
  Set<String> get quillKeys => const {'date'};

  @override
  Set<String> get htmlTags => const {'time'};

  @override
  DateTime? fromQuill(QuillEmbedOp op) {
    final value = op.value;
    if (value is! String) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
        return DateTime.tryParse('${(decoded.first as Map)['insert']}'.trim());
      }
    } on FormatException {
      // Malformed: fall through, so the unknown embed keeps it.
    }
    return null;
  }

  @override
  DateTime? fromHtml(StoryHtmlElement element) => DateTime.tryParse(element['datetime'] ?? '');

  @override
  StoryHtmlElement toHtml(DateTime value) {
    final iso = value.toIso8601String();
    return StoryHtmlElement('time', attributes: {'datetime': iso}, text: iso);
  }

  @override
  Widget build(BuildContext context, StoryEmbedContext<DateTime> embed) {
    final date = embed.value;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(date.day.toString().padLeft(2, '0'), style: textTheme.headlineSmall),
              const SizedBox(width: 4),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${date.month}', style: textTheme.labelSmall),
                  Text('${date.year}', style: textTheme.labelSmall),
                ],
              ),
            ],
          ),
        ),
        if (!embed.readOnly)
          IconButton(
            tooltip: 'Remove',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline),
            onPressed: embed.remove,
          ),
      ],
    );
  }
}
