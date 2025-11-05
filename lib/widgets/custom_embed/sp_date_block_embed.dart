import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';

class SpDateBlockEmbed extends EmbedBuilder {
  @override
  String get key => 'date';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    // bool readOnly = embedContext.readOnly;
    DateTime? date = getDate(embedContext);

    if (date == null) return Text(tr("general.unknown"));

    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              date.day.toString().padLeft(2, '0'),
              style: TextTheme.of(context).headlineLarge?.copyWith(color: ColorScheme.of(context).primary),
            ),
            const SizedBox(height: 4.0),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormatHelper.MMM(date, context.locale),
                  style: TextTheme.of(context).labelMedium,
                ),
                Text(
                  DateFormatHelper.y(date, context.locale),
                  style: TextTheme.of(context).labelMedium,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  DateTime? getDate(EmbedContext embedContext) {
    DateTime? date;
    dynamic delta = embedContext.node.value.toJson()['date'];

    if (delta is String) {
      dynamic result = jsonDecode(delta);
      if (result is List && result.isNotEmpty) {
        dynamic insert = result.first;
        if (insert is Map) {
          date = DateTime.tryParse(insert['insert'].toString().trim());
        }
      }
    }

    return date;
  }
}
