import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/services/messenger_service.dart' show MessengerService;
import 'package:storypad/providers/app_lock_provider.dart' show AppLockProvider;
import 'package:storypad/widgets/view/base_view_model.dart';
import 'enter_security_question_view.dart';

class EnterSecurityQuestionViewModel extends BaseViewModel {
  final EnterSecurityQuestionRoute params;
  late final TextEditingController controller;

  EnterSecurityQuestionViewModel({
    required this.params,
  }) {
    controller = TextEditingController(text: params.answer);
  }

  Future<void> save(BuildContext context) async {
    await saveAnswer(
      context: context,
      answer: controller.value.text,
    );
  }

  Future<void> clear(BuildContext context) async {
    final result = await showOkCancelAlertDialog(
      context: context,
      isDestructiveAction: true,
      title: tr("dialog.are_you_sure.title"),
      okLabel: tr("button.clear"),
    );

    if (context.mounted && result == OkCancelResult.ok) {
      await saveAnswer(
        answer: null,
        context: context,
      );
    }
  }

  Future<void> saveAnswer({
    required BuildContext context,
    required String? answer,
  }) async {
    var securityAnswers = {...context.read<AppLockProvider>().appLock.securityAnswers ?? {}};

    if (answer == null || answer.trim().isEmpty) {
      securityAnswers.removeWhere((key, _) => key == params.question);
    } else {
      securityAnswers[params.question] = answer;
    }

    if (securityAnswers.values.where((e) => e.isNotEmpty).isEmpty) {
      MessengerService.of(context).showSnackBar(
        tr('snack_bar.at_least_one_answer_required_to_reset_your_pin'),
        success: false,
      );
      return;
    }

    await context.read<AppLockProvider>().setSecurityAnswer(securityAnswers);
    if (context.mounted) await Navigator.maybePop(context);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
