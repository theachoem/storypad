part of '../library_view.dart';

class _ImagesTabContent extends StatefulWidget {
  const _ImagesTabContent({
    required this.constraints,
  });

  final BoxConstraints constraints;

  @override
  State<_ImagesTabContent> createState() => _ImagesTabContentState();
}

class _ImagesTabContentState extends State<_ImagesTabContent> with AutomaticKeepAliveClientMixin {
  Map<int, int> storiesCount = {};
  CollectionDbModel<AssetDbModel>? assets;

  int? selectedTagId;
  Map<String, dynamic> get filters => {
    'type': AssetType.image,
    'tag': selectedTagId,
  };

  @override
  void initState() {
    super.initState();
    _load();

    StoryDbModel.db.addGlobalListener(_listener);
  }

  Future<void> _listener() async {
    if (mounted) _load();
  }

  Future<void> _load() async {
    assets = await AssetDbModel.db.where(filters: filters);
    storiesCount = StoryDbModel.db.getStoryCountByAssets(
      assetIds: assets?.items.map((e) => e.id).toList() ?? [],
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
    StoryDbModel.db.removeGlobalListener(_listener);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final provider = Provider.of<BackupProvider>(context);

    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return [
          SliverToBoxAdapter(
            child: buildFilterableTags(),
          ),
        ];
      },
      body: buildBody(context, provider),
    );
  }

  Widget buildFilterableTags() {
    return Consumer<TagsProvider>(
      builder: (context, tagsProvider, child) {
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: SpScrollableChoiceChips<TagDbModel>(
            choices: tagsProvider.tags?.items ?? [],
            storiesCount: (TagDbModel tag) => tag.id == selectedTagId ? assets?.items.length : null,
            toLabel: (TagDbModel tag) => tag.title,
            selected: (TagDbModel tag) => selectedTagId == tag.id,
            onToggle: (TagDbModel tag) {
              selectedTagId = selectedTagId == tag.id ? null : tag.id;
              _load();
            },
          ),
        );
      },
    );
  }

  Widget buildBody(BuildContext context, BackupProvider provider) {
    if (assets == null) return const Center(child: CircularProgressIndicator.adaptive());
    if (assets?.items.isEmpty == true) return _EmptyBody(context: context);

    // Group assets by day
    final groupedAssets = _groupAssetsByDay(assets!.items);
    return KeyedSubtree(
      key: ValueKey(filters.values.join("-")),
      child: SpFadeIn.fromBottom(
        child: ListView.separated(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16.0,
            left: MediaQuery.of(context).padding.left + 16.0,
            right: MediaQuery.of(context).padding.right + 16.0,
          ),
          separatorBuilder: (context, index) => const SizedBox(height: 12.0),
          itemCount: groupedAssets.length,
          itemBuilder: (context, dayIndex) {
            final dayEntry = groupedAssets[dayIndex];
            final dayLabel = dayEntry['label'] as String;
            final dayAssets = dayEntry['assets'] as List<AssetDbModel>;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                  child: Text(
                    dayLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                MasonryGridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  addAutomaticKeepAlives: false,
                  itemCount: dayAssets.length,
                  mainAxisSpacing: 8.0,
                  crossAxisSpacing: 8.0,
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: widget.constraints.maxWidth ~/ 120,
                  ),
                  itemBuilder: (context, assetIndex) {
                    return _buildItem(
                      dayAssets[assetIndex],
                      provider,
                      context,
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _groupAssetsByDay(List<AssetDbModel> assetList) {
    final Map<String, List<AssetDbModel>> groupedMap = {};

    for (var asset in assetList) {
      final dayKey = _getDayKey(asset.createdAt);
      groupedMap.putIfAbsent(dayKey, () => []).add(asset);
    }

    // Sort by date descending (newest first)
    final sortedKeys = groupedMap.keys.toList()
      ..sort((a, b) {
        final dateA = _parseDateKey(a);
        final dateB = _parseDateKey(b);
        return dateB.compareTo(dateA);
      });

    return sortedKeys.map((key) {
      return {
        'label': key,
        'assets': groupedMap[key]!,
      };
    }).toList();
  }

  String _getDayKey(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return tr('general.date.today');
    } else if (date == yesterday) {
      return tr('general.date.yesterday');
    } else {
      return dateTime.toString().split(' ')[0]; // YYYY-MM-DD
    }
  }

  DateTime _parseDateKey(String key) {
    if (key == tr('general.date.today')) {
      return DateTime.now();
    } else if (key == tr('general.date.yesterday')) {
      return DateTime.now().subtract(const Duration(days: 1));
    } else {
      return DateTime.parse(key);
    }
  }

  Widget _buildItem(AssetDbModel asset, BackupProvider provider, BuildContext context) {
    return SpPopupMenuButton(
      dyGetter: (dy) => dy + 100,
      items: (context) {
        return [
          if (storiesCount[asset.id] == 0)
            _buildDeleteButton(context, provider, asset, storiesCount[asset.id]!)
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
              final embedLinks = assets?.items.map((e) => e.embedLink).toList() ?? [];
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4.0,
              children: [
                Stack(
                  children: [
                    SpImage(
                      link: asset.embedLink,
                      width: double.infinity,
                      height: 120,
                    ),
                    _ImageStatus(context: context, asset: asset, provider: provider),
                    const _BlackOverlay(),
                    _buildStoryCount(asset),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoryCount(AssetDbModel asset) {
    return Positioned(
      left: 8.0,
      right: 8.0,
      bottom: 4.0,
      child: IgnorePointer(
        ignoring: true,
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: plural("plural.story", storiesCount[asset.id] ?? 0)),
              if ((storiesCount[asset.id] ?? 0) == 0) ...[
                const TextSpan(text: ' '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(
                    SpIcons.archive,
                    size: 12.0,
                    color: ColorScheme.of(context).error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  SpPopMenuItem _buildDeleteButton(
    BuildContext context,
    BackupProvider provider,
    AssetDbModel asset,
    int storyCount,
  ) {
    if (asset.getGoogleDriveForEmails()?.isNotEmpty == true) {
      return SpPopMenuItem(
        leadingIconData: SpIcons.delete,
        titleStyle: TextStyle(color: ColorScheme.of(context).error),
        title: tr("button.delete_from_google_drive"),
        onPressed: () => _deleteAsset(context, asset, storyCount),
      );
    } else {
      return SpPopMenuItem(
        leadingIconData: SpIcons.delete,
        titleStyle: TextStyle(color: ColorScheme.of(context).error),
        title: tr("button.delete"),
        onPressed: () => _deleteAsset(context, asset, storyCount),
      );
    }
  }

  Future<void> _deleteAsset(BuildContext context, AssetDbModel asset, int storyCount) async {
    final viewModel = context.read<LibraryViewModel>();
    await viewModel.deleteAsset(context, asset, storyCount);
    if (mounted) {
      await _load();
    }
  }

  @override
  bool get wantKeepAlive => true;
}
