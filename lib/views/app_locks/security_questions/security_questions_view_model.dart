import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/types/app_lock_question.dart' show AppLockQuestion;
import 'package:storypad/providers/app_lock_provider.dart';
import 'package:storypad/views/app_locks/security_questions/enter/enter_security_question_view.dart';
import 'package:storypad/widgets/base_view/base_view_model.dart';
import 'security_questions_view.dart';

class SecurityQuestionsViewModel extends BaseViewModel {
  final SecurityQuestionsRoute params;

  SecurityQuestionsViewModel({
    required this.params,
    required BuildContext context,
  }) {
    securityAnswers = {...context.read<AppLockProvider>().appLock.securityAnswers ?? {}};
  }

  late Map<AppLockQuestion, String> securityAnswers;

  Future<void> save(BuildContext context) async {
    await context.read<AppLockProvider>().setSecurityAnswer(securityAnswers);
    if (context.mounted) Navigator.maybePop(context);
  }

  Future<void> goToEnterAnswerFor(
    AppLockQuestion question,
    BuildContext context,
  ) async {
    final answer = securityAnswers[question];
    final updatedAnswer = await EnterSecurityQuestionRoute(
      question: question,
      answer: answer,
    ).push(context);

    if (updatedAnswer is String) {
      if (updatedAnswer.trim().isEmpty) {
        securityAnswers.removeWhere((key, _) => key == question);
      } else {
        securityAnswers[question] = updatedAnswer.trim();
      }
    }

    notifyListeners();
  }
}
