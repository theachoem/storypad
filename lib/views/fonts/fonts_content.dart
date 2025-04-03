part of 'fonts_view.dart';

class _FontsContent extends StatelessWidget {
  const _FontsContent(this.viewModel);

  final FontsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr("page.fonts.title")),
        bottom: buildSearchBar(context),
        actions: [
          IconButton(
            tooltip: "https://fonts.google.com",
            icon: Icon(SpIcons.of(context).exploreBrowser),
            onPressed: () => UrlOpenerService.openInCustomTab(context, "https://fonts.google.com"),
          ),
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
          barLeading: Icon(SpIcons.of(context).search),
          viewLeading: CloseButton(),
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
      thumbVisibility: true,
      interactive: true,
      child: buildListView(context),
    );
  }

  Widget buildListView(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0).copyWith(bottom: MediaQuery.of(context).padding.bottom),
      itemCount: viewModel.fonts.length + viewModel.fontGroups!.length,
      itemBuilder: (context, index) {
        if (index < viewModel.fontGroups!.length) {
          final fontGroup = viewModel.fontGroups![index];
          return StickyHeader(
            header: buildGroupHeader(context, fontGroup.label),
            content: Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                children: List.generate(fontGroup.fontFamilies.length, (index) {
                  return buildFontFamilyTile(context, fontGroup.fontFamilies[index]);
                }),
              ),
            ),
          );
        } else {
          int actualIndex = index - viewModel.fontGroups!.length;
          final previousFont = actualIndex > 0 ? viewModel.fonts[actualIndex - 1] : null;
          final font = viewModel.fonts[actualIndex];

          return Column(
            children: [
              if (previousFont == null || previousFont[0] != font[0]) buildGroupHeader(context, font[0]),
              buildFontFamilyTile(context, font),
            ],
          );
        }
      },
    );
  }

  Widget buildGroupHeader(BuildContext context, String groupLabel) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        spacing: 16.0,
        children: [
          Text(groupLabel, style: TextTheme.of(context).titleLarge),
          const Expanded(child: Divider(height: 1))
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
            trailingIconData: SpIcons.of(context).keyboardRight,
            onPressed: () => viewModel.changeFont(fontFamily),
          )
        ];
      },
      builder: (open) {
        bool selected = viewModel.currentFontFamily == fontFamily;
        return ListTile(
          selected: viewModel.currentFontFamily == fontFamily,
          onTap: () => open(),
          title: Text(fontFamily),
          trailing: Visibility(
            visible: selected,
            child: SpFadeIn.fromBottom(
              child: Icon(
                SpIcons.of(context).checkCircle,
                color: ColorScheme.of(context).primary,
              ),
            ),
          ),
        );
      },
    );
  }
}
