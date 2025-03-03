import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/core/types/app_lock_question.dart';
import 'package:storypad/widgets/view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/view/base_route.dart';

import 'enter_security_question_view_model.dart';

part 'enter_security_question_content.dart';

class EnterSecurityQuestionRoute extends BaseRoute {
  EnterSecurityQuestionRoute({
    required this.question,
    required this.answer,
  });

  final AppLockQuestion question;
  final String? answer;

  @override
  bool get preferredNestedRoute => true;

  @override
  Map<String, String?>? get analyticsParameters {
    return {
      'question': question.translatedQuestion,
    };
  }

  @override
  Widget buildPage(BuildContext context) => EnterSecurityQuestionView(params: this);
}

class EnterSecurityQuestionView extends StatelessWidget {
  const EnterSecurityQuestionView({
    super.key,
    required this.params,
  });

  final EnterSecurityQuestionRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<EnterSecurityQuestionViewModel>(
      create: (context) => EnterSecurityQuestionViewModel(params: params),
      builder: (context, viewModel, child) {
        return _EnterSecurityQuestionContent(viewModel);
      },
    );
  }
}
