import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/objects/reminder_object.dart';
import 'package:storypad/core/types/reminder_type.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/views/reminders/local_widgets/reminder_schedule_summary.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';

import 'reminders_view_model.dart';

part 'reminders_content.dart';

class RemindersRoute extends BaseRoute {
  const RemindersRoute();

  @override
  String? get routeName => 'reminders';

  @override
  Widget buildPage(BuildContext context) => const RemindersView();
}

class RemindersView extends StatelessWidget {
  const RemindersView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RemindersViewModel>(
      create: (context) => RemindersViewModel(context: context),
      builder: (context, child) {
        return _RemindersContent(Provider.of(context));
      },
    );
  }
}
