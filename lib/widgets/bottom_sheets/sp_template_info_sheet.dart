import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/template_db_model.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';

class SpTemplateInfoSheet extends BaseBottomSheet {
  final TemplateDbModel template;
  final bool persisted;

  SpTemplateInfoSheet({
    required this.template,
    required this.persisted,
  });

  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (persisted) ...[
          if (template.archivedAt != null)
            ListTile(
              leading: const Icon(SpIcons.delete),
              title: Text(tr('list_tile.archived_at.title')),
              subtitle: Text(context
                  .read<DevicePreferencesProvider>()
                  .preferences
                  .timeFormat
                  .formatDateTime(template.archivedAt!, context.locale)),
            ),
          ListTile(
            leading: const Icon(SpIcons.calendar),
            title: Text(tr("list_tile.updated_at.title")),
            subtitle: Text(context
                .read<DevicePreferencesProvider>()
                .preferences
                .timeFormat
                .formatDateTime(template.updatedAt, context.locale)),
          ),
          ListTile(
            leading: const Icon(SpIcons.info),
            title: Text(tr("list_tile.created_at.title")),
            subtitle: Text(context
                .read<DevicePreferencesProvider>()
                .preferences
                .timeFormat
                .formatDateTime(template.createdAt, context.locale)),
          ),
        ],
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}
