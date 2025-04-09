part of 'security_questions_view.dart';

class _SecurityQuestionsContent extends StatelessWidget {
  const _SecurityQuestionsContent(this.viewModel);

  final SecurityQuestionsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final bool saveable = viewModel.securityAnswers.isNotEmpty == true;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !CupertinoSheetRoute.hasParentSheet(context),
        actions: [
          if (CupertinoSheetRoute.hasParentSheet(context))
            CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context))
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FilledButton.icon(
        icon: const Icon(SpIcons.save),
        label: Text(tr('button.done')),
        onPressed: saveable ? () => viewModel.save(context) : null,
      ),
      body: ListView(
        controller: PrimaryScrollController.maybeOf(context),
        children: AppLockQuestion.values.map((question) {
          final answer = viewModel.securityAnswers[question];
          return ListTile(
            title: Text(question.translatedQuestion),
            subtitle: answer != null ? Text(List.generate(answer.length, (e) => "*").join("")) : null,
            trailing: answer != null
                ? Icon(SpIcons.checkCircle, color: ColorScheme.of(context).primary)
                : const Icon(SpIcons.keyboardRight),
            onTap: () => viewModel.goToEnterAnswerFor(question, context),
          );
        }).toList(),
      ),
    );
  }
}
