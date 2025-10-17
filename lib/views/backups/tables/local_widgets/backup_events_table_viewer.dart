import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/event_db_model.dart';
import 'package:storypad/core/extensions/string_extension.dart';
import 'package:storypad/core/helpers/date_format_helper.dart';
import 'package:storypad/widgets/sp_icons.dart';

class BackupEventsTableViewer extends StatelessWidget {
  const BackupEventsTableViewer({
    super.key,
    required this.events,
  });

  final List<EventDbModel> events;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];

        return ListTile(
          leading: switch (event.eventType) {
            'period' => const Icon(SpIcons.waterDrop),
            _ => const Icon(Icons.event),
          },
          title: RichText(
            text: TextSpan(
              text: "${event.eventType.capitalize} ",
              children: [
                if (event.permanentlyDeletedAt != null)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(
                      SpIcons.deleteForever,
                      color: ColorScheme.of(context).error,
                      size: 12,
                    ),
                  ),
              ],
            ),
          ),
          subtitle: Text(DateFormatHelper.yMEd_jmNullable(event.date, context.locale) ?? tr("general.na")),
        );
      },
    );
  }
}
