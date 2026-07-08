import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart' show kIsCupertino;
import 'package:storypad/core/objects/reminder_object.dart';
import 'package:storypad/views/reminders/local_widgets/reminder_schedule_summary.dart';
import 'package:storypad/views/reminders/local_widgets/reminder_weekdays_chips.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';
import 'package:storypad/widgets/sp_section_title.dart';

import 'edit_custom_reminder_view_model.dart';

part 'edit_custom_reminder_content.dart';

class EditCustomReminderRoute extends BaseRoute {
  const EditCustomReminderRoute({required this.reminder, this.isNew = false});

  /// The custom reminder being edited. For a new one, pass a fresh object with
  /// a pre-allocated id (see [DevicePreferencesProvider.nextCustomReminderId]).
  final ReminderObject reminder;

  /// True when creating a brand-new reminder (not yet persisted) — hides the
  /// Delete action, since there's nothing saved to delete yet.
  final bool isNew;

  @override
  Widget buildPage(BuildContext context) => EditCustomReminderView(reminder: reminder, isNew: isNew);
}

class EditCustomReminderView extends StatelessWidget {
  const EditCustomReminderView({super.key, required this.reminder, this.isNew = false});

  final ReminderObject reminder;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditCustomReminderViewModel>(
      create: (context) => EditCustomReminderViewModel(reminder: reminder, isNew: isNew),
      builder: (context, child) {
        return _EditCustomReminderContent(Provider.of(context));
      },
    );
  }
}
