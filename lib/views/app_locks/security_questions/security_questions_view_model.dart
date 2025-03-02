import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/types/app_lock_question.dart' show AppLockQuestion;
import 'package:storypad/providers/app_lock_provider.dart';
import 'package:storypad/views/app_locks/security_questions/enter/enter_security_question_view.dart';
import 'package:storypad/widgets/view/base_view_model.dart';
import 'security_questions_view.dart';

class SecurityQuestionsViewModel extends BaseViewModel {
  final SecurityQuestionsRoute params;

  SecurityQuestionsViewModel({
    required this.params,
  });

  Future<void> goToEnterAnswerFor(
    AppLockQuestion question,
    BuildContext context,
  ) async {
    final answer = context.read<AppLockProvider>().appLock.securityAnswers?[question];
    await EnterSecurityQuestionRoute(
      question: question,
      answer: answer,
    ).push(context);
  }
}
