part of 'enter_security_question_view.dart';

class _EnterSecurityQuestionContent extends StatelessWidget {
  const _EnterSecurityQuestionContent(this.viewModel);

  final EnterSecurityQuestionViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(viewModel.params.question.translatedQuestion),
          SizedBox(height: 8.0),
          TextFormField(
            controller: viewModel.controller,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              hintText: "...",
            ),
            onFieldSubmitted: (text) => viewModel.save(context),
          ),
          const SizedBox(height: 16.0),
          FilledButton.icon(
            label: Text(tr("button.save")),
            onPressed: () => viewModel.save(context),
          ),
          const SizedBox(height: 4.0),
          ValueListenableBuilder(
            valueListenable: viewModel.controller,
            builder: (context, value, child) {
              return OutlinedButton.icon(
                label: Text(tr("button.clear")),
                onPressed: value.text.isNotEmpty ? () => viewModel.controller.clear() : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
