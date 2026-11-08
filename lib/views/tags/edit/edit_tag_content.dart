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
          trailing: buildColorBox(context),
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

  // Beside the title, as tall as the field. The same picker as the theme's Color Seed: picking the
  // current color again, or black/white, clears it.
  Widget buildColorBox(BuildContext context) {
    final value = viewModel.selectedColorSeedValue;
    final color = value != null ? TagColorService.resolve(Color(value), Theme.of(context).brightness).dot : null;

    return SpAdaptivePopUpButton(
      // At the field's end: line up the ends so the picker stays on screen.
      horizontalAnchor: Directionality.of(context) == .rtl ? -1.0 : 1.0,
      floatingBuilder: (close, openAbove) {
        return SpColorPicker(
          isDarkMode: AppTheme.isDarkMode(context),
          position: openAbove ? .bottom : .top,
          currentColor: value != null ? Color(value) : null,
          level: .one,
          onPickedColor: (color) async {
            await close();
            viewModel.setColor(color);
          },
        );
      },
      builder: (open) {
        return Tooltip(
          message: tr("general.color"),
          child: SpTapEffect(
            onTap: open,
            child: Container(
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                border: Border.all(color: color?.withValues(alpha: 0.5) ?? ColorScheme.of(context).outlineVariant),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Container(
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4.0)),
              ),
            ),
          ),
        );
      },
    );
  }
}
