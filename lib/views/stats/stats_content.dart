part of 'stats_view.dart';

/// How many ranked items each section shows before the inline "show more" toggle.
/// The service returns every item; sections collapse to this count by default.
const int _kStatsTopVisible = 5;

class _StatsContent extends StatelessWidget {
  const _StatsContent(this.viewModel);

  final StatsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final int year = viewModel.selectedYear;

    return Scaffold(
      appBar: AppBar(
        title: SpTapEffect(
          onTap: () => viewModel.pickYear(context),
          child: Row(
            mainAxisSize: .min,
            spacing: 4.0,
            children: [
              Text('$year'),
              const Icon(SpIcons.dropDown),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: tr('button.more_options'),
            icon: const Icon(SpIcons.moreVert),
            onPressed: () => SpToggleListSheet<StatsSection>(
              items: [
                for (final section in viewModel.sectionsForCurrentTab()) (value: section, label: section.label),
              ],
              isEnabled: viewModel.isSectionVisible,
              onToggle: viewModel.toggleSection,
              onReset: viewModel.resetSections,
              listenable: viewModel,
            ).show(context: context),
          ),
        ],
        bottom: TabBar(
          isScrollable: true,
          tabAlignment: .start,
          tabs: [
            Tab(text: tr('general.all')),
            for (int month = 1; month <= 12; month++)
              Tab(
                text: DateFormatHelper.MMM(
                  DateTime(year, month),
                  context.locale,
                ),
              ),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          for (int tabIndex = 0; tabIndex <= 12; tabIndex++)
            _buildTabBody(
              context,
              tabIndex: tabIndex,
              stats: viewModel.statsFor(tabIndex),
            ),
        ],
      ),
    );
  }

  /// One stats tab. All data loading is owned by [StatsViewModel]; this just
  /// renders what it receives: a spinner while loading, an empty state, or the
  /// ranked sections.
  Widget _buildTabBody(
    BuildContext context, {
    required int tabIndex,
    required StoryStatsObject? stats,
  }) {
    if (stats == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final List<Widget> sections = [
      for (final section in sectionsForTab(tabIndex))
        if (viewModel.isSectionVisible(section))
          _buildStatsSection(
            context,
            title: section.label,
            child: section.hasEnoughData(stats)
                ? _buildSectionChild(
                    context,
                    section: section,
                    stats: stats,
                    tabIndex: tabIndex,
                  )
                : _buildNotEnoughData(context),
          ),
      const _StatsShareFooter(),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: 16.0,
        bottom: 48.0 + MediaQuery.paddingOf(context).bottom,
        left: MediaQuery.paddingOf(context).left,
        right: MediaQuery.paddingOf(context).right,
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        spacing: 24.0,
        children: List.generate(sections.length, (index) {
          final child = sections[index];
          return SpFadeIn.fromBottom(
            // Fade differently for first 5 sections, then fade remaining sections together to avoid a long fade-in sequence.
            delay: const Duration(milliseconds: 50) * min(index + 1, 4),
            child: child,
          );
        }),
      ),
    );
  }

  /// Titled block: a [SpSectionTitle] header above arbitrary content, inset to
  /// the page gutter.
  Widget _buildStatsSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: .start,
        spacing: 8.0,
        children: [
          SpSectionTitle(
            title: title,
            padding: EdgeInsets.zero,
          ),
          child,
        ],
      ),
    );
  }

  /// Renders the content for [section] (only called when it has data).
  Widget _buildSectionChild(
    BuildContext context, {
    required StatsSection section,
    required StoryStatsObject stats,
    required int tabIndex,
  }) {
    void openTag(int tagId) => viewModel.openStoriesForTag(context, tagId, tabIndex);

    return switch (section) {
      StatsSection.overview => _buildOverview(context, stats, tabIndex),
      StatsSection.feelings => _StatsEmojiGrid(
        items: stats.topFeelings,
        onTap: openTag,
      ),
      StatsSection.activities => _StatsEmojiGrid(
        items: stats.topActivities,
        onTap: openTag,
      ),
      StatsSection.tags => _StatsLabelList(
        items: stats.topTags,
        icon: SpIcons.tag,
        onTap: (item) => openTag(item.tagId!),
      ),
      StatsSection.people => _StatsLabelList(
        items: stats.topPeople,
        icon: SpIcons.person,
        onTap: (item) => openTag(item.tagId!),
      ),
      StatsSection.places => _StatsLabelList(
        items: stats.topPlaces,
        icon: SpIcons.locationPin,
        onTap: (item) => viewModel.openStoriesForPlace(context, item, tabIndex),
      ),
      StatsSection.countries => _StatsLabelList(
        items: stats.topCountries,
        icon: SpIcons.globe,
      ),
      StatsSection.trend => _StatsTrend(
        stats: stats,
        range: viewModel.rangeForTab(tabIndex),
      ),
    };
  }

  /// Muted placeholder shown when a visible section has no data for the tab.
  Widget _buildNotEnoughData(BuildContext context) {
    return Text(
      tr('page.stats.not_enough_data'),
      style: TextTheme.of(context).bodySmall?.copyWith(
        color: ColorScheme.of(context).onSurface.withValues(alpha: 0.5),
      ),
    );
  }

  /// Compact summary chips, three per row. Core metrics always show; media/place
  /// chips only appear when they carry a value, so quiet ranges stay uncluttered.
  ///
  /// Chips backed by a list of stories (entries/photos/voices/places) open the
  /// filtered stories sheet on tap; metrics without a story list (active days,
  /// words) carry a null [onTap] and stay inert to avoid confusion.
  Widget _buildOverview(BuildContext context, StoryStatsObject stats, int tabIndex) {
    final List<({IconData icon, String value, String label, VoidCallback? onTap})> metrics = [
      (
        icon: SpIcons.book,
        value: '${stats.entryCount}',
        label: tr('general.entries'),
        onTap: () => viewModel.openStoriesForRange(context, tabIndex),
      ),
      (
        icon: SpIcons.calendar,
        value: '${stats.activeDays}',
        label: tr('general.active_days'),
        onTap: null,
      ),
      if (stats.wordCount > 0)
        (
          icon: SpIcons.text,
          value: '${stats.wordCount}',
          label: tr('general.words'),
          onTap: null,
        ),
      if (stats.photoCount > 0)
        (
          icon: SpIcons.photo,
          value: '${stats.photoCount}',
          label: tr('general.photos'),
          onTap: () => viewModel.openStoriesForIds(context, stats.photoStoryIds, tabIndex),
        ),
      if (stats.voiceCount > 0)
        (
          icon: SpIcons.voice,
          value: '${stats.voiceCount}',
          label: tr('general.voices'),
          onTap: () => viewModel.openStoriesForIds(context, stats.voiceStoryIds, tabIndex),
        ),
      if (stats.locatedCount > 0)
        (
          icon: SpIcons.locationPin,
          value: '${stats.locatedCount}',
          label: tr('general.places'),
          onTap: () => viewModel.openStoriesForIds(context, stats.locatedStoryIds, tabIndex),
        ),
    ];

    const double spacing = 8.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = (constraints.maxWidth - spacing * 2) / 3;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: cardWidth,
                child: _StatsMetricChip(
                  icon: metric.icon,
                  value: metric.value,
                  label: metric.label,
                  onTap: metric.onTap,
                ),
              ),
          ],
        );
      },
    );
  }
}
