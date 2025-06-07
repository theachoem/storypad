part of 'library_view.dart';

class _LibraryContent extends StatelessWidget {
  const _LibraryContent(this.viewModel);

  final LibraryViewModel viewModel;

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
      return buildEmptyBody(context);
    }

    return MasonryGridView.builder(
      padding: EdgeInsets.only(
        top: 16.0,
        bottom: MediaQuery.of(context).padding.bottom + 16.0,
        left: MediaQuery.of(context).padding.left + 16.0,
        right: MediaQuery.of(context).padding.right + 16.0,
      ),
      itemCount: viewModel.assets?.items.length ?? 0,
      mainAxisSpacing: 8.0,
      crossAxisSpacing: 8.0,
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
      itemBuilder: (context, index) {
        final asset = viewModel.assets!.items[index];

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
                  final assetLinks = viewModel.assets?.items.map((e) => e.link).toList() ?? [];
                  SpImagesViewer.fromString(
                    images: assetLinks,
                    initialIndex: assetLinks.indexOf(asset.link),
                  ).show(context);
                },
              )
            ];
          },
          builder: (callback) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4.0,
              children: [
                Stack(
                  children: [
                    buildImage(context, asset, callback),
                    Positioned(
                      top: 8.0,
                      right: 8.0,
                      child: buildImageStatus(
                        context: context,
                        asset: asset,
                        provider: provider,
                      ),
                    ),
                  ],
                ),
                Text(plural("plural.story", viewModel.storiesCount[asset.id] ?? 0)),
              ],
            );
          },
        );
      },
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

  Widget buildImageStatus({
    required BuildContext context,
    required AssetDbModel asset,
    required BackupProvider provider,
  }) {
    Widget child;

    if (!asset.isGoogleDriveUploadedFor(provider.currentUser?.email)) {
      child = CircleAvatar(
        radius: 16.0,
        backgroundColor: ColorScheme.of(context).bootstrap.warning.color,
        foregroundColor: ColorScheme.of(context).bootstrap.warning.onColor,
        child: Icon(
          SpIcons.cloudOff,
          size: 20.0,
        ),
      );
    } else if (asset.isGoogleDriveUploadedFor(provider.currentUser?.email)) {
      child = Tooltip(
        message: asset.getGoogleDriveUrlForEmail(provider.currentUser!.email),
        child: CircleAvatar(
          radius: 16.0,
          backgroundColor: ColorScheme.of(context).bootstrap.success.color,
          foregroundColor: ColorScheme.of(context).bootstrap.success.onColor,
          child: const Icon(
            SpIcons.cloudDone,
            size: 20.0,
          ),
        ),
      );
    } else {
      child = CircleAvatar(
        radius: 16.0,
        backgroundColor: ColorScheme.of(context).bootstrap.info.color,
        foregroundColor: ColorScheme.of(context).bootstrap.info.onColor,
        child: const Icon(
          SpIcons.warning,
          size: 20.0,
        ),
      );
    }

    return child;
  }

  Widget buildImage(
    BuildContext context,
    AssetDbModel asset,
    void Function() onTap,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: SpTapEffect(
        onTap: onTap,
        child: SpImage(
          link: asset.link,
          width: 200,
          height: 200,
          errorWidget: (context, url, error) {
            String message = error is StateError ? error.message : error.toString();
            return Material(
              color: ColorScheme.of(context).readOnly.surface3,
              child: InkWell(
                onTap: () => onTap(),
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Wrap(
                    spacing: 8.0,
                    runAlignment: WrapAlignment.center,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 8.0,
                    children: [
                      const Icon(SpIcons.imageNotSupported),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildEmptyBody(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: constraints.maxHeight,
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12.0,
              children: [
                const Icon(SpIcons.photo, size: 32.0),
                Text(
                  tr("page.library.empty_message"),
                  textAlign: TextAlign.center,
                  style: TextTheme.of(context).bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
