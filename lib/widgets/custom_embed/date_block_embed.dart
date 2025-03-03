import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';

class DateBlockEmbed extends EmbedBuilder {
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
                Text(getDayOfMonthSuffix(date.day).toLowerCase(), style: TextTheme.of(context).labelSmall),
                Text(
                  DateFormatHelper.yM(date, context.locale),
                  style: TextTheme.of(context).labelMedium,
                ),
              ],
            ),
            // const SizedBox(height: 4.0),
            // SpAnimatedIcons(
            //   showFirst: !readOnly,
            //   secondChild: const SizedBox.shrink(),
            //   firstChild: const Icon(Icons.arrow_drop_down),
            // ),
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

  static String getDayOfMonthSuffix(int dayNum) {
    if (!(dayNum >= 1 && dayNum <= 31)) {
      throw Exception('invalid_day_of_month');
    }

    if (dayNum >= 11 && dayNum <= 13) {
      return 'th';
    }

    switch (dayNum % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}
