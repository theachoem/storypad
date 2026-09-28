import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad_editor/storypad_editor.dart';

/// A legacy date block (read-only; nothing inserts it anymore).
///
/// - Quill: `{"date": "[{\"insert\":\"2024-01-01T00:00:00.000\"}]"}` -- a JSON-encoded one-op Delta holding an ISO
///   date. A malformed value is rejected, so the unknown embed keeps it as-is.
/// - Markdown: `<time datetime="…">…</time>`.
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
      // Malformed: the unknown embed keeps it.
    }
    return null;
  }

  @override
  QuillEmbedOp toQuill(DateTime value) => QuillEmbedOp.of(
    'date',
    jsonEncode([
      {'insert': value.toIso8601String()},
    ]),
  );

  @override
  DateTime? fromHtml(StoryHtmlElement element) => DateTime.tryParse(element['datetime'] ?? '');

  @override
  StoryHtmlElement toHtml(DateTime value) {
    final iso = value.toIso8601String();
    return StoryHtmlElement('time', attributes: {'datetime': iso}, text: iso);
  }

  @override
  String toPlainText(DateTime value) => value.toIso8601String();

  @override
  Widget build(BuildContext context, StoryEmbedContext<DateTime> embed) {
    final date = embed.value;
    return Row(
      children: [
        Text(
          date.day.toString().padLeft(2, '0'),
          style: TextTheme.of(context).headlineLarge?.copyWith(color: ColorScheme.of(context).primary),
        ),
        const SizedBox(width: 4.0),
        Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            Text(DateFormatHelper.MMM(date, context.locale), style: TextTheme.of(context).labelMedium),
            Text(DateFormatHelper.y(date, context.locale), style: TextTheme.of(context).labelMedium),
          ],
        ),
      ],
    );
  }
}
