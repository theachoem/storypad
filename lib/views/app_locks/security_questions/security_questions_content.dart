part of 'security_questions_view.dart';

class _SecurityQuestionsContent extends StatelessWidget {
  const _SecurityQuestionsContent(this.viewModel);

  final SecurityQuestionsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppLockProvider>(context);
    return Scaffold(
      appBar: AppBar(),
      body: ListView.builder(
        itemCount: AppLockQuestion.values.length,
        itemBuilder: (context, index) {
          final question = AppLockQuestion.values.elementAt(index);
          final answer = provider.appLock.securityAnswers?[question];

          return ListTile(
            title: Text(question.translatedQuestion),
            subtitle: answer != null ? Text(List.generate(answer.length, (e) => "*").join("")) : null,
            trailing: answer != null
                ? Icon(Icons.check, color: ColorScheme.of(context).primary)
                : const Icon(Icons.keyboard_arrow_right),
            onTap: () => viewModel.goToEnterAnswerFor(question, context),
          );
        },
      ),
    );
  }
}
