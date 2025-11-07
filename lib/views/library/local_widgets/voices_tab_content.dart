part of '../library_view.dart';

class _VoicesTabContent extends StatefulWidget {
  const _VoicesTabContent({
    required this.constraints,
  });

  final BoxConstraints constraints;

  @override
  State<_VoicesTabContent> createState() => _VoicesTabContentState();
}

class _VoicesTabContentState extends State<_VoicesTabContent> with AutomaticKeepAliveClientMixin {
  Map<int, int> storiesCount = {};
  CollectionDbModel<AssetDbModel>? assets;

  int? selectedTagId;
  Map<String, dynamic> get filters => {
    'type': AssetType.audio,
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

  Widget buildBody(
    BuildContext context,
    BackupProvider provider,
  ) {
    if (assets == null) return const Center(child: CircularProgressIndicator.adaptive());
    if (assets?.items.isEmpty == true) return _EmptyBody(context: context);

    // Group assets by day
    final groupedAssets = _groupAssetsByDay(assets!.items);
    return KeyedSubtree(
      key: ValueKey(filters.values.join("-")),
      child: SpFadeIn.fromBottom(
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            top: 16.0,
            bottom: MediaQuery.of(context).padding.bottom + 16.0,
            left: MediaQuery.of(context).padding.left,
            right: MediaQuery.of(context).padding.right,
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
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: Text(
                    dayLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                ...dayAssets.map((asset) {
                  return _buildListTile(asset, provider, context);
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildListTile(AssetDbModel asset, BackupProvider provider, BuildContext context) {
    return SpPopupMenuButton(
      smartDx: true,
      dyGetter: (dy) => dy + 36,
      items: (context) {
        return [
          if (storiesCount[asset.id] == 0)
            _buildDeleteButton(context, provider, asset, storiesCount[asset.id]!)
          else
            SpPopMenuItem(
              leadingIconData: SpIcons.book,
              title: tr("button.view"),
              onPressed: () async {
                var stories = await StoryDbModel.db.where(filters: {'asset': asset.id}).then((e) => e?.items);

                if (!context.mounted) return;
                if (stories?.length == 1) {
                  ShowStoryRoute(
                    id: stories![0].id,
                    story: stories[0],
                  ).push(context);
                } else {
                  // Typically, audio assets are linked to a single story.
                  // This block handles the rare case where multiple stories exist for one asset.
                  ShowAssetRoute(
                    assetId: asset.id,
                    storyViewOnly: false,
                  ).push(context);
                }
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
        final timeFormat = context.read<DevicePreferencesProvider>().preferences.timeFormat;
        final createdTimeString = timeFormat.formatTime(asset.createdAt, context.locale);
        final storyCount = storiesCount[asset.id] ?? 0;
        final durationText = asset.formattedDuration ?? tr('general.unknown');

        return ListTile(
          onTap: () {
            SpVoicePlaybackSheet(asset: asset).show(context: context);
          },
          leading: const Icon(SpIcons.voice),
          contentPadding: const EdgeInsets.only(left: 16.0, right: 4.0),
          title: Text.rich(
            TextSpan(
              text: '$createdTimeString ',
              children: [
                WidgetSpan(
                  child: _buildBackupStatus(asset, provider, context),
                ),
              ],
            ),
          ),
          subtitle: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: durationText),
                if (storyCount == 0) ...[
                  const TextSpan(text: ' '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(
                      SpIcons.delete,
                      size: 12.0,
                      color: ColorScheme.of(context).error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: callback,
          ),
        );
      },
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

  Widget _buildBackupStatus(AssetDbModel asset, BackupProvider provider, BuildContext context) {
    Widget child;

    if (!asset.isGoogleDriveUploadedFor(provider.currentUser?.email)) {
      child = CircleAvatar(
        radius: 10.0,
        backgroundColor: ColorScheme.of(context).bootstrap.warning.color,
        foregroundColor: ColorScheme.of(context).bootstrap.warning.onColor,
        child: const Icon(
          SpIcons.cloudUpload,
          size: 14.0,
        ),
      );
    } else if (asset.isGoogleDriveUploadedFor(provider.currentUser?.email)) {
      child = CircleAvatar(
        radius: 10.0,
        backgroundColor: ColorScheme.of(context).bootstrap.success.color,
        foregroundColor: ColorScheme.of(context).bootstrap.success.onColor,
        child: const Icon(
          SpIcons.cloudDone,
          size: 14.0,
        ),
      );
    } else {
      child = CircleAvatar(
        radius: 10.0,
        backgroundColor: ColorScheme.of(context).bootstrap.info.color,
        foregroundColor: ColorScheme.of(context).bootstrap.info.onColor,
        child: const Icon(
          SpIcons.warning,
          size: 14.0,
        ),
      );
    }

    return child;
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
    if (mounted) await _load();
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

  @override
  bool get wantKeepAlive => true;
}
