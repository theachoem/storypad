part of '../root_view.dart';

class _SideBar extends StatelessWidget {
  const _SideBar({
    required this.viewModel,
  });

  final RootViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: viewModel.sideBarInfoNotifier,
      builder: (context, sideBarInfo, child) {
        bool showSideBar = sideBarInfo?.showSideBar ?? false;

        return AnimatedContainer(
          duration: Durations.medium3,
          curve: Curves.ease,
          width: showSideBar ? 260.0 : 0.0,
          child: child!,
        );
      },
      child: Material(
        color: ColorScheme.of(context).surface,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1.0,
              ),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                width: 260.0,
                height: MediaQuery.sizeOf(context).height,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top + 16.0,
                    left: MediaQuery.paddingOf(context).left,
                    bottom: MediaQuery.paddingOf(context).bottom + 32,
                  ),
                  child: buildSideBarItems(context),
                ),
              ),
              SpSideBarTogglerButton.buildViewButton(
                right: 12.0,
                viewContext: context,
                open: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSideBarItems(BuildContext context) {
    final tagsProvider = Provider.of<TagsProvider>(context);
    final List<TagDbModel> tags = tagsProvider.tags?.items ?? [];

    return Column(
      children: [
        _SideBarItem(
          routeName: 'home',
          title: tr('page.home.title'),
          leading: const Icon(SpIcons.home, size: 24.0),
          viewModel: viewModel,
          onTap: () => viewModel.navigate('home', null),
        ),
        _SideBarItem(
          routeName: SearchRoute.routeName,
          title: tr('page.search.title'),
          leading: const Icon(SpIcons.search, size: 24.0),
          viewModel: viewModel,
          onTap: () => viewModel.navigate(SearchRoute.routeName, SearchRoute(initialYear: DateTime.now().year)),
        ),
        _SideBarItem(
          routeName: CalendarRoute.routeName,
          title: tr('page.calendar.title'),
          leading: const Icon(SpIcons.calendar, size: 24.0),
          viewModel: viewModel,
          onTap: () => viewModel.navigate(
            CalendarRoute.routeName,
            CalendarRoute(
              initialMonth: DateTime.now().month,
              initialYear: DateTime.now().year,
              initialSegment: .mood,
            ),
          ),
        ),
        _SideBarItem(
          routeName: LibraryRoute.routeName,
          title: tr('page.library.title'),
          leading: const Icon(SpIcons.photo, size: 24.0),
          viewModel: viewModel,
          onTap: () => viewModel.navigate(LibraryRoute.routeName, LibraryRoute()),
        ),
        _SideBarItem(
          routeName: RelaxSoundsRoute.routeName,
          title: tr('general.sounds'),
          leading: const Icon(SpIcons.musicNote, size: 24.0),
          viewModel: viewModel,
          onTap: () => viewModel.navigate(RelaxSoundsRoute.routeName, const RelaxSoundsRoute()),
        ),
        const SizedBox(height: 12.0),
        _TagHeader(viewModel),
        ...tags.map((tag) {
          return _SideBarItem(
            routeName: 'tags/${tag.id}',
            title: tag.title,
            leading: const Icon(SpIcons.tag, size: 24.0),
            viewModel: viewModel,
            onTap: () => viewModel.navigate('tags/${tag.id}', ShowTagRoute(tag: tag, storyViewOnly: false)),
          );
        }),
      ],
    );
  }
}
