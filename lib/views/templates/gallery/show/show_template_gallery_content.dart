part of 'show_template_gallery_view.dart';

class _ShowTemplateGalleryContent extends StatelessWidget {
  const _ShowTemplateGalleryContent(this.viewModel);

  final ShowTemplateGalleryViewModel viewModel;

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
        title: Text(viewModel.galleryTemplate.name),
        actions: [
          SpPopupMenuButton(
            dyGetter: (dy) => dy + 72,
            items: (context) {
              return [
                SpPopMenuItem(
                  leadingIconData: SpIcons.book,
                  title: tr("general.previous_stories"),
                  onPressed: () => viewModel.goToPreviousStories(context),
                ),
                SpPopMenuItem(
                  leadingIconData: SpIcons.save,
                  trailingIconData: !context.read<InAppPurchaseProvider>().template ? SpIcons.lock : null,
                  title: tr('button.save_template'),
                  titleStyle: context.read<InAppPurchaseProvider>().template
                      ? null
                      : TextStyle(color: Theme.of(context).disabledColor),
                  onPressed: () {
                    if (context.read<InAppPurchaseProvider>().template) {
                      viewModel.saveTemplate(context);
                    } else {
                      AddOnsRoute.pushAndNavigateTo(
                        product: AppProduct.templates,
                        context: context,
                      );
                    }
                  },
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
      floatingActionButton: FloatingActionButton.extended(
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

    final note = viewModel.galleryTemplate.note;

    return StoryPagesBuilder(
      preferences: StoryPreferencesDbModel.create().copyWith(layoutType: PageLayoutType.list),
      pages: pages,
      storyContent: viewModel.draftContent!,
      headerBuilder: note != null
          ? (_) => Padding(
              padding: CupertinoSheetRoute.hasParentSheet(context) ? EdgeInsets.zero : const EdgeInsets.only(top: 12.0),
              child: TemplateNote(note: note),
            )
          : null,
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).padding.left,
        right: MediaQuery.of(context).padding.right,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      pageScrollController: viewModel.pagesManager.pageScrollController,
      viewInsets: MediaQuery.viewInsetsOf(context),
      onGoToEdit: null,
      onPageChanged: null,
      actions: null,
    );
  }
}
