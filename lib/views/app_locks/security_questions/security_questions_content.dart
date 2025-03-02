part of 'security_questions_view.dart';

class _SecurityQuestionsContent extends StatelessWidget {
  const _SecurityQuestionsContent(this.viewModel);

  final SecurityQuestionsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppLockProvider>(context);
    final bool saveable = provider.appLock.securityAnswers.toString() != viewModel.securityAnswers.toString() &&
        provider.appLock.securityAnswers?.isNotEmpty == true;

    return Scaffold(
      appBar: AppBar(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FilledButton.icon(
        icon: Icon(Icons.save_outlined),
        label: Text(tr('button.done')),
        onPressed: saveable ? () => viewModel.save(context) : null,
      ),
      body: ListView(
        children: AppLockQuestion.values.map((question) {
          final answer = viewModel.securityAnswers[question];
          return ListTile(
            title: Text(question.translatedQuestion),
            subtitle: answer != null ? Text(List.generate(answer.length, (e) => "*").join("")) : null,
            trailing: answer != null
                ? Icon(Icons.check, color: ColorScheme.of(context).primary)
                : const Icon(Icons.keyboard_arrow_right),
            onTap: () => viewModel.goToEnterAnswerFor(question, context),
          );
        }).toList(),
      ),
    );
  }
}
