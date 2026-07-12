part of 'fonts_view.dart';

class _FontsContent extends StatelessWidget {
  const _FontsContent(this.viewModel);

  final FontsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !CupertinoSheetRoute.hasParentSheet(context),
        title: Text(tr("page.fonts.title")),
        bottom: buildSearchBar(context),
        actions: [
          IconButton(
            tooltip: "https://fonts.google.com",
            icon: const Icon(SpIcons.exploreBrowser),
            onPressed: () => UrlOpenerService.openInCustomTab(context, "https://fonts.google.com"),
          ),
          if (CupertinoSheetRoute.hasParentSheet(context))
            CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context)),
        ],
      ),
      body: buildBody(context),
    );
  }

  PreferredSize buildSearchBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56.0 + 12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SearchAnchor.bar(
          isFullScreen: false,
          barLeading: const Icon(SpIcons.search),
          viewLeading: const CloseButton(),
          suggestionsBuilder: (context, controller) {
            final fuzzy = Fuzzy<String>(viewModel.fonts, options: FuzzyOptions(isCaseSensitive: false));
            List<Result<String>> result = fuzzy.search(controller.text.trim());
            result.sort((a, b) => a.score.compareTo(b.score));

            return result.map((fontFamily) {
              return buildFontFamilyTile(context, fontFamily.item);
            }).toList();
          },
        ),
      ),
    );
  }

  Widget buildBody(BuildContext context) {
    if (viewModel.fontGroups == null) return const Center(child: CircularProgressIndicator.adaptive());
    return Scrollbar(
      controller: PrimaryScrollController.maybeOf(context),
      thumbVisibility: true,
      interactive: true,
      child: buildListView(context),
    );
  }

  Widget buildListView(BuildContext context) {
    final items = <(String label, String fontFamily)>[
      for (final fontGroup in viewModel.fontGroups!)
        for (final fontFamily in fontGroup.fontFamilies) (fontGroup.label, fontFamily),
    ];

    return ListView.builder(
      controller: PrimaryScrollController.maybeOf(context),
      padding: const EdgeInsets.symmetric(vertical: 8.0).copyWith(bottom: MediaQuery.of(context).padding.bottom),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final (label, fontFamily) = items[index];
        final previousLabel = index > 0 ? items[index - 1].$1 : null;

        return Column(
          children: [
            if (previousLabel != label) buildGroupHeader(context, label, isFirst: index == 0),
            buildFontFamilyTile(context, fontFamily),
          ],
        );
      },
    );
  }

  Widget buildGroupHeader(BuildContext context, String groupLabel, {bool isFirst = false}) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
      padding: EdgeInsets.only(left: 16.0, right: 16.0, top: isFirst ? 8.0 : 24.0, bottom: 8.0),
      child: Row(
        spacing: 16.0,
        children: [
          Text(groupLabel, style: TextTheme.of(context).titleLarge),
          const Expanded(child: Divider(height: 1)),
        ],
      ),
    );
  }

  Widget buildFontFamilyTile(
    BuildContext context,
    String fontFamily,
  ) {
    return SpPopupMenuButton(
      dyGetter: (dy) => dy + 88.0,
      items: (BuildContext context) {
        return [
          SpPopMenuItem(
            title: tr("list_tile.use_this_font.title"),
            subtitle: tr("list_tile.use_this_font.loreum_ipsum"),
            subtitleStyle: GoogleFonts.getFont(fontFamily),
            trailingIconData: SpIcons.keyboardRight,
            onPressed: () => viewModel.changeFont(fontFamily),
          ),
        ];
      },
      builder: (open) {
        bool selected = viewModel.currentFontFamily == fontFamily;
        return ListTile(
          selected: viewModel.currentFontFamily == fontFamily,
          onTap: () => open(),
          title: Text(fontFamily),
          trailing: !viewModel.available(fontFamily)
              ? const Icon(SpIcons.lock)
              : Visibility(
                  visible: selected,
                  child: SpFadeIn.fromBottom(
                    child: Icon(
                      SpIcons.checkCircle,
                      color: ColorScheme.of(context).primary,
                    ),
                  ),
                ),
        );
      },
    );
  }
}
