part of 'edit_tag_view.dart';

class _EditTagAdaptive extends StatelessWidget {
  const _EditTagAdaptive(this.viewModel);

  final EditTagViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SpTextInputsPage(
      appBar: AppBar(title: viewModel.tag != null ? const Text("Edit Tag") : const Text("Add Tag")),
      fields: [
        SpTextInputField(
          initialText: viewModel.tag?.title,
          hintText: 'eg. Personal',
          validator: (value) {
            if (value == null || value.trim().isEmpty == true) return "Required";
            if (viewModel.isTagExist(value) == true) return 'Tag already Exist';
            return null;
          },
        ),
      ],
    );
  }
}
