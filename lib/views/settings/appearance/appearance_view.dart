import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';
import 'package:storypad/widgets/sp_section_title.dart';

import 'appearance_view_model.dart';

part 'appearance_content.dart';

class AppearanceRoute extends BaseRoute {
  const AppearanceRoute();

  @override
  Widget buildPage(BuildContext context) => const AppearanceView();
}

class AppearanceView extends StatelessWidget {
  const AppearanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppearanceViewModel>(
      create: (context) => AppearanceViewModel(),
      builder: (context, child) {
        return _AppearanceContent(Provider.of(context));
      },
    );
  }
}
