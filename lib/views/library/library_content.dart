part of 'library_view.dart';

class _LibraryContent extends StatelessWidget {
  const _LibraryContent(
    this.viewModel, {
    required this.constraints,
  });

  final LibraryViewModel viewModel;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BackupProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr("page.library.title_with_app_name")),
      ),
      body: buildBody(context, provider),
    );
  }

  Widget buildBody(
    BuildContext context,
    BackupProvider provider,
  ) {
    if (viewModel.assets?.items == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (viewModel.assets?.items.isEmpty == true) {
      return _EmptyBody(context: context);
    }

    return SpDefaultScrollController(
      builder: (context, scrollController) {
        return Scrollbar(
          controller: scrollController,
          thumbVisibility: true,
          interactive: true,
          child: MasonryGridView.builder(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            addAutomaticKeepAlives: false,
            padding: EdgeInsets.only(
              top: 16.0,
              bottom: MediaQuery.of(context).padding.bottom + 16.0,
              left: MediaQuery.of(context).padding.left + 16.0,
              right: MediaQuery.of(context).padding.right + 16.0,
            ),
            itemCount: viewModel.assets?.items.length ?? 0,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
            gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(crossAxisCount: constraints.maxWidth ~/ 120),
            itemBuilder: (context, index) {
              final asset = viewModel.assets!.items[index];
              return buildItem(asset, provider, context);
            },
          ),
        );
      },
    );
  }

  Widget buildItem(AssetDbModel asset, BackupProvider provider, BuildContext context) {
    return SpPopupMenuButton(
      dyGetter: (dy) => dy + 100,
      items: (context) {
        return [
          if (viewModel.storiesCount[asset.id] == 0)
            buildDeleteButton(context, provider, asset, viewModel.storiesCount[asset.id]!)
          else
            SpPopMenuItem(
              leadingIconData: SpIcons.book,
              title: tr("general.stories"),
              onPressed: () => ShowAssetRoute(assetId: asset.id, storyViewOnly: false).push(context),
            ),
          SpPopMenuItem(
            leadingIconData: SpIcons.photo,
            title: tr("button.view"),
            onPressed: () {
              final embedLinks = viewModel.assets?.items.map((e) => e.embedLink).toList() ?? [];
              SpImagesViewer.fromString(
                images: embedLinks,
                initialIndex: embedLinks.indexOf(asset.embedLink),
              ).show(context);
            },
          ),
          SpPopMenuItem(
            leadingIconData: SpIcons.info,
            title: tr("button.info"),
            onPressed: () => SpAssetInfoSheet(asset: asset).show(context: context),
          ),
        ];
      },
      builder: (callback) {
        return SpTapEffect(
          onTap: callback,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4.0,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: SpImage(
                      link: asset.embedLink,
                      width: double.infinity,
                      height: 120,
                    ),
                  ),
                  _ImageStatus(context: context, asset: asset, provider: provider),
                  const _BlackOverlay(),
                  buildStoryCount(asset),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildStoryCount(AssetDbModel asset) {
    return Positioned(
      left: 8.0,
      right: 8.0,
      bottom: 4.0,
      child: IgnorePointer(
        ignoring: true,
        child: Text(plural("plural.story", viewModel.storiesCount[asset.id] ?? 0)),
      ),
    );
  }

  SpPopMenuItem buildDeleteButton(BuildContext context, BackupProvider provider, AssetDbModel asset, int storyCount) {
    if (asset.getGoogleDriveForEmails()?.isNotEmpty == true) {
      return SpPopMenuItem(
        leadingIconData: SpIcons.delete,
        titleStyle: TextStyle(color: ColorScheme.of(context).error),
        title: tr("button.delete_from_google_drive"),
        onPressed: () => viewModel.deleteAsset(context, asset, storyCount),
      );
    } else {
      return SpPopMenuItem(
        leadingIconData: SpIcons.delete,
        titleStyle: TextStyle(color: ColorScheme.of(context).error),
        title: tr("button.delete"),
        onPressed: () => viewModel.deleteAsset(context, asset, storyCount),
      );
    }
  }
}
