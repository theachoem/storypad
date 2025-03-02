import 'package:flutter/material.dart';
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
    String answer = controller.value.text;
    if (context.mounted) await Navigator.maybePop(context, answer);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
