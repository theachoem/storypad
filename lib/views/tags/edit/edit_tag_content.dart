part of 'edit_tag_view.dart';

class _EditTagContent extends StatelessWidget {
  const _EditTagContent(this.viewModel);

  final EditTagViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SpTextInputsPage(
      appBar: AppBar(
        title: viewModel.tag != null ? Text(tr("page.edit_tag.title")) : Text(tr("page.new_tag.title")),
      ),
      fields: [
        SpTextInputField(
          initialText: viewModel.tag?.title,
          hintText: tr("input.tag.hint"),
          validator: (value) {
            if (value == null || value.trim().isEmpty == true) return tr("input.message.required");
            if (viewModel.isTagExist(value) == true) return tr("input.message.already_exist");
            return null;
          },
        ),
      ],
    );
  }
}
