part of 'edit_tag_view.dart';

class _EditTagContent extends StatelessWidget {
  const _EditTagContent(this.viewModel, {required this.inSheet});

  final EditTagViewModel viewModel;
  final bool inSheet;

  String get title => viewModel.tag != null ? tr("page.edit_tag.title") : tr("page.new_tag.title");

  bool get isPerson => viewModel.selectedCategoryId == TagCategoryDbModel.peopleId;

  @override
  Widget build(BuildContext context) {
    return SpTextInputsPage(
      contentOnly: inSheet,
      appBar: AppBar(
        title: Text(title),
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
      header: inSheet ? buildSheetHeader(context) : buildCategorySelector(context),
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

  // A sheet has no app bar: the title goes above the category, styled like the other sheets'.
  Widget buildSheetHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      spacing: 12.0,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: .ellipsis,
          style: TextTheme.of(context).titleLarge?.copyWith(color: ColorScheme.of(context).primary),
        ),
        buildCategorySelector(context),
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
  // (TagColors.swatch); tapping the selected one again clears it, as toggles do elsewhere in the app.
  Widget buildColors(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final selected = viewModel.selectedColorSeedValue;

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
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
