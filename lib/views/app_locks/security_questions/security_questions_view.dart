import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:storypad/core/types/app_lock_question.dart' show AppLockQuestion;
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';

import 'security_questions_view_model.dart';

part 'security_questions_content.dart';

class SecurityQuestionsRoute extends BaseRoute {
  SecurityQuestionsRoute();

  @override
  Widget buildPage(BuildContext context) => SecurityQuestionsView(params: this);
}

class SecurityQuestionsView extends StatelessWidget {
  const SecurityQuestionsView({
    super.key,
    required this.params,
  });

  final SecurityQuestionsRoute params;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SecurityQuestionsViewModel>(
      create: (context) => SecurityQuestionsViewModel(params: params, context: context),
      builder: (context, child) {
        return _SecurityQuestionsContent(Provider.of(context));
      },
    );
  }
}
