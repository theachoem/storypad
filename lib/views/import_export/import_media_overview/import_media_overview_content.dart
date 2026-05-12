part of 'import_media_overview_view.dart';

class _ImportMediaOverviewContent extends StatelessWidget {
  const _ImportMediaOverviewContent(this.viewModel);

  final ImportMediaOverviewViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final entries = viewModel.entries;

    final imageEntries = entries?.where((e) => e.scanEntry.type == AssetType.image).toList() ?? const [];
    final audioEntries = entries?.where((e) => e.scanEntry.type == AssetType.audio).toList() ?? const [];
    final hasImages = imageEntries.isNotEmpty;
    final hasAudio = audioEntries.isNotEmpty;

    final tabs = <Tab>[];
    final tabViews = <Widget>[];

    if (hasImages) {
      tabs.add(Tab(icon: const Icon(SpIcons.photo), text: plural('plural.row', imageEntries.length)));
      tabViews.add(_ImagesImportTab(entries: imageEntries));
    }

    if (hasAudio) {
      tabs.add(Tab(icon: const Icon(SpIcons.voice), text: plural('plural.row', audioEntries.length)));
      tabViews.add(_AudioImportTab(entries: audioEntries));
    }

    return buildDefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr("general.review")),
          bottom: entries == null
              ? null
              : tabs.length > 1
              ? TabBar(tabs: tabs)
              : null,
        ),
        body: buildBody(entries, tabs, tabViews),
        bottomNavigationBar: entries == null ? null : buildBottomBar(context, entries),
      ),
    );
  }

  Widget buildBody(List<ImportMediaEntry>? entries, List<Tab> tabs, List<Widget> tabViews) {
    if (entries == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (entries.isEmpty) {
      return Center(child: Text(tr('snack_bar.empty_or_invalid_file')));
    }
    if (tabs.length == 1) {
      return tabViews.single;
    }
    return TabBarView(children: tabViews);
  }

  Widget buildDefaultTabController({
    required Widget child,
    required int length,
  }) {
    if (length >= 2) {
      return DefaultTabController(
        length: length,
        child: child,
      );
    }
    return child;
  }

  Widget buildBottomBar(BuildContext context, List<ImportMediaEntry> entries) {
    final toImport = viewModel.toImportCount;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: toImport == 0 ? null : () => viewModel.performImport(context),
              child: Text(
                "${tr('button.import')} (${plural('plural.row', toImport)})",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagesImportTab extends StatelessWidget {
  const _ImagesImportTab({
    required this.entries,
  });

  final List<ImportMediaEntry> entries;

  @override
  Widget build(BuildContext context) {
    final groupedEntries = _groupEntriesByDay(entries);
    return SpFadeIn.fromBottom(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView.separated(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16.0,
              left: MediaQuery.of(context).padding.left + 16.0,
              right: MediaQuery.of(context).padding.right + 16.0,
            ),
            separatorBuilder: (context, index) => const SizedBox(height: 12.0),
            itemCount: groupedEntries.length,
            itemBuilder: (context, dayIndex) {
              final dayEntry = groupedEntries[dayIndex];
              final dayLabel = dayEntry['label'] as String;
              final dayAssets = dayEntry['entries'] as List<ImportMediaEntry>;

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
                      crossAxisCount: max(1, constraints.maxWidth ~/ 120),
                    ),
                    itemBuilder: (context, index) {
                      return _ImageImportTile(entry: dayAssets[index]);
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ImageImportTile extends StatelessWidget {
  const _ImageImportTile({
    required this.entry,
  });

  final ImportMediaEntry entry;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4.0,
        children: [
          Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return Material(
                    clipBehavior: Clip.hardEdge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    child: Image.file(
                      entry.previewFile,
                      width: constraints.maxWidth,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) {
                        return Container(
                          width: constraints.maxWidth,
                          height: 120,
                          color: ColorScheme.of(context).surfaceContainerHighest,
                          child: Center(
                            child: Icon(
                              SpIcons.photo,
                              color: ColorScheme.of(context).onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              SpAssetStatusBadge(
                backgroundColor: _badgeBackgroundColor(context, entry),
                foregroundColor: _badgeForegroundColor(context, entry),
                icon: _badgeIcon(entry),
              ),
              SpAssetStoryCountOverlay(
                storyCount: entry.storyCount,
                showArchiveIconWhenZero: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AudioImportTab extends StatelessWidget {
  const _AudioImportTab({
    required this.entries,
  });

  final List<ImportMediaEntry> entries;

  @override
  Widget build(BuildContext context) {
    final groupedEntries = _groupEntriesByDay(entries);
    return SpFadeIn.fromBottom(
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          top: 16.0,
          bottom: MediaQuery.of(context).padding.bottom + 16.0,
          left: MediaQuery.of(context).padding.left,
          right: MediaQuery.of(context).padding.right,
        ),
        separatorBuilder: (context, index) => const SizedBox(height: 12.0),
        itemCount: groupedEntries.length,
        itemBuilder: (context, dayIndex) {
          final dayEntry = groupedEntries[dayIndex];
          final dayLabel = dayEntry['label'] as String;
          final dayAssets = dayEntry['entries'] as List<ImportMediaEntry>;

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
              ...dayAssets.map((entry) => _AudioImportTile(entry: entry)),
            ],
          );
        },
      ),
    );
  }
}

class _AudioImportTile extends StatelessWidget {
  const _AudioImportTile({
    required this.entry,
  });

  final ImportMediaEntry entry;

  @override
  Widget build(BuildContext context) {
    final createdAt = _entryDate(entry);
    final createdTimeString =
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    return ListTile(
      leading: const Icon(SpIcons.voice),
      contentPadding: const EdgeInsets.only(left: 16.0, right: 16.0),
      title: Text.rich(
        TextSpan(
          text: '$createdTimeString ',
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: CircleAvatar(
                radius: 10.0,
                backgroundColor: _badgeBackgroundColor(context, entry),
                foregroundColor: _badgeForegroundColor(context, entry),
                child: Icon(
                  _badgeIcon(entry),
                  size: 14.0,
                ),
              ),
            ),
          ],
        ),
      ),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: entry.scanEntry.ext.replaceFirst('.', '').toUpperCase()),
            const TextSpan(text: ' • '),
            TextSpan(text: plural('plural.story', entry.storyCount)),
            if (entry.storyCount == 0) ...[
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
      trailing: const Icon(SpIcons.musicNote),
    );
  }
}

List<Map<String, dynamic>> _groupEntriesByDay(List<ImportMediaEntry> source) {
  final sorted = [...source]..sort((a, b) => _entryDate(b).compareTo(_entryDate(a)));
  final groupedMap = <String, List<ImportMediaEntry>>{};

  for (final entry in sorted) {
    final dayKey = _dayKey(_entryDate(entry));
    groupedMap.putIfAbsent(dayKey, () => []).add(entry);
  }

  final sortedKeys = groupedMap.keys.toList()
    ..sort((a, b) {
      final dateA = _dateKey(a);
      final dateB = _dateKey(b);
      return dateB.compareTo(dateA);
    });

  return sortedKeys.map((key) => {'label': key, 'entries': groupedMap[key]!}).toList();
}

DateTime _entryDate(ImportMediaEntry entry) {
  return entry.existingAsset?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(entry.scanEntry.id);
}

String _dayKey(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

  if (date == today) {
    return tr('general.date.today');
  } else if (date == yesterday) {
    return tr('general.date.yesterday');
  }

  return dateTime.toString().split(' ')[0];
}

DateTime _dateKey(String key) {
  if (key == tr('general.date.today')) {
    return DateTime.now();
  } else if (key == tr('general.date.yesterday')) {
    return DateTime.now().subtract(const Duration(days: 1));
  }
  return DateTime.parse(key);
}

Color _badgeBackgroundColor(BuildContext context, ImportMediaEntry entry) {
  if (entry.isNew) return ColorScheme.of(context).bootstrap.success.color;
  if (entry.isRestore) return ColorScheme.of(context).bootstrap.info.color;
  return ColorScheme.of(context).surfaceContainerHighest.withValues(alpha: 0.8);
}

Color _badgeForegroundColor(BuildContext context, ImportMediaEntry entry) {
  if (entry.isNew) return ColorScheme.of(context).bootstrap.success.onColor;
  if (entry.isRestore) return ColorScheme.of(context).bootstrap.info.onColor;
  return ColorScheme.of(context).onSurfaceVariant;
}

IconData _badgeIcon(ImportMediaEntry entry) {
  if (entry.isNew) return SpIcons.add;
  if (entry.isRestore) return SpIcons.restore;
  return SpIcons.check;
}
