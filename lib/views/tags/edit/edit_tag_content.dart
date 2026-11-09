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
      footer: buildColors(context),
      onSubmitted: (values) => Navigator.of(context).pop(
        EditTagResult(
          title: values.first,
          categoryId: viewModel.selectedCategoryId,
          colorSeedValue: viewModel.selectedColorSeedValue,
        ),
      ),
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

  // Every color in the palette, below the title. Each swatch is the color the tag's chip becomes
  // (TagColors.swatch); the first one is no color, and picking the current color again clears it too.
  Widget buildColors(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final selected = viewModel.selectedColorSeedValue;

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        SpColorItem(
          color: Colors.transparent,
          selected: selected == null,
          onPressed: (_) => viewModel.setColor(null),
          child: Icon(SpIcons.clear, size: 16.0, color: ColorScheme.of(context).onSurfaceVariant),
        ),
        for (final seed in TagColorService.palette)
          SpColorItem(
            color: TagColorService.resolve(seed, brightness).swatch,
            selected: seed.toARGB32() == selected,
            onPressed: (_) => viewModel.setColor(seed),
          ),
      ],
    );
  }
}
