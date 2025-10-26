part of 'show_template_view.dart';

class _ShowTemplateContent extends StatelessWidget {
  const _ShowTemplateContent(this.viewModel);

  final ShowTemplateViewModel viewModel;

  List<StoryPageObject> constructPages() {
    if (viewModel.pagesManager.pagesMap.keys.isEmpty) return <StoryPageObject>[];
    return List.generate(viewModel.draftContent?.richPages?.length ?? 0, (index) {
      final page = viewModel.draftContent!.richPages![index];
      return viewModel.pagesManager.pagesMap[page.id];
    }).toList().whereType<StoryPageObject>().toList();
  }

  @override
  Widget build(BuildContext context) {
    List<StoryPageObject> pages = constructPages();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !CupertinoSheetRoute.hasParentSheet(context),
        title: viewModel.template.name != null ? Text(viewModel.template.name!) : null,
        actions: [
          if (!viewModel.template.archived)
            IconButton(
              tooltip: tr("button.edit"),
              icon: const Icon(SpIcons.edit),
              onPressed: () => viewModel.goToEditPage(context),
            ),
          SpPopupMenuButton(
            dyGetter: (dy) => dy + 72,
            items: (context) {
              return [
                SpPopMenuItem(
                  leadingIconData: SpIcons.book,
                  title: tr("general.previous_stories"),
                  onPressed: () => viewModel.goToPreviousStories(context),
                ),
                if (viewModel.template.archived)
                  SpPopMenuItem(
                    leadingIconData: SpIcons.putBack,
                    title: tr("button.put_back"),
                    onPressed: () => viewModel.putBack(context),
                  )
                else
                  SpPopMenuItem(
                    leadingIconData: SpIcons.archive,
                    title: tr("button.archive"),
                    onPressed: () => viewModel.archive(context),
                  ),
                SpPopMenuItem(
                  titleStyle: TextStyle(color: ColorScheme.of(context).error),
                  leadingIconData: SpIcons.delete,
                  title: tr("button.delete"),
                  onPressed: () => viewModel.delete(context),
                ),
                SpPopMenuItem(
                  leadingIconData: SpIcons.info,
                  title: tr("button.info"),
                  onPressed: () => viewModel.showInfo(context),
                ),
              ];
            },
            builder: (callback) {
              return IconButton(
                tooltip: tr("button.more_options"),
                icon: const Icon(SpIcons.moreVert),
                onPressed: callback,
              );
            },
          ),
          if (CupertinoSheetRoute.hasParentSheet(context))
            CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context)),
        ],
      ),
      body: buildBody(context, pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: viewModel.template.archived
          ? null
          : FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => viewModel.useTemplate(context),
              shape: const StadiumBorder(),
              label: Text(tr('button.use_template')),
              icon: const Icon(SpIcons.newStory),
            ),
    );
  }

  Widget buildBody(BuildContext context, List<StoryPageObject> pages) {
    if (viewModel.draftContent == null || pages.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    return StoryPagesBuilder(
      preferences: viewModel.template.preferences,
      pages: pages,
      storyContent: viewModel.draftContent!,
      headerBuilder: (_) => buildPageHeader(context),
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).padding.left,
        right: MediaQuery.of(context).padding.right,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      pageScrollController: viewModel.pagesManager.pageScrollController,
      viewInsets: MediaQuery.viewInsetsOf(context),
      onGoToEdit: () => viewModel.goToEditPage(context),
      onPageChanged: null,
      actions: null,
    );
  }

  Widget buildPageHeader(BuildContext context) {
    return TemplateTagLabels(
      template: viewModel.template,
      margin: const EdgeInsets.symmetric(horizontal: 12.0).copyWith(top: 12.0),
    );
  }
}
