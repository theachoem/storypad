import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/story_list/sp_story_list.dart';

import 'throwback_view_model.dart';

part 'throwback_content.dart';

class ThrowbackRoute extends BaseRoute {
  const ThrowbackRoute({
    required this.day,
    required this.month,
  });

  final int day;
  final int month;

  @override
  Widget buildPage(BuildContext context) => ThrowbackView(params: this);
}

class ThrowbackView extends StatelessWidget {
  const ThrowbackView({
    super.key,
    required this.params,
  });

  final ThrowbackRoute params;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThrowbackViewModel>(
      create: (context) => ThrowbackViewModel(params: params),
      builder: (context, child) {
        return _ThrowbackContent(Provider.of(context));
      },
    );
  }
}
