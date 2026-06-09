part of 'edit_tag_view.dart';

class _EditTagContent extends StatelessWidget {
  const _EditTagContent(this.viewModel);

  final EditTagViewModel viewModel;

  bool get isPerson => viewModel.selectedCategoryId == TagCategoryDbModel.peopleId;

  @override
  Widget build(BuildContext context) {
    return SpTextInputsPage(
      appBar: AppBar(
        title: viewModel.tag != null ? Text(tr("page.edit_tag.title")) : Text(tr("page.new_tag.title")),
        actions: [
          if (viewModel.tag != null)
            IconButton(
              color: ColorScheme.of(context).error,
              icon: const Icon(SpIcons.deleteForever),
              onPressed: () async {
                bool deleted = await context.read<TagsProvider>().deleteTag(context, viewModel.tag!);
                if (deleted && context.mounted) Navigator.maybePop(context);
              },
            ),
        ],
      ),
      header: buildCategorySelector(context),
      onSubmitted: (values) =>
          Navigator.of(context).pop(EditTagResult(title: values.first, categoryId: viewModel.selectedCategoryId)),
      fields: [
        SpTextInputField(
          initialText: viewModel.tag?.title,
          hintText: isPerson ? tr("input.people.hint") : tr("input.tag.hint"),
          validator: (value) {
            if (value == null || value.trim().isEmpty == true) return tr("input.message.required");

            final exists = context.read<TagsProvider>().isTagExist(value, categoryId: viewModel.selectedCategoryId);
            // Allow keeping the same title when editing an existing tag.
            final unchanged = viewModel.tag?.title.toLowerCase() == value.trim().toLowerCase();
            if (exists && !unchanged) return tr("input.message.already_exist");

            return null;
          },
        ),
      ],
    );
  }

  Widget buildCategorySelector(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8.0,
        children: [
          ChoiceChip(
            label: Text(tr("page.tags.title")),
            selected: !isPerson,
            onSelected: (_) => viewModel.setCategory(null),
          ),
          ChoiceChip(
            label: Text(tr("general.tag_category.people_title")),
            selected: isPerson,
            onSelected: (_) => viewModel.setCategory(TagCategoryDbModel.peopleId),
          ),
        ],
      ),
    );
  }
}
