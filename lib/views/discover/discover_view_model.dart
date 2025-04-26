// ignore_for_file: library_private_types_in_public_api

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/views/discover/segments/discover_calendar_content.dart';
import 'package:storypad/views/discover/segments/discover_relax_sounds_content.dart';
import 'package:storypad/views/discover/segments/discover_search_content.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'discover_view.dart';

enum DiscoverSegmentId {
  search,
  calendar,
  relaxSounds,
}

class DiscoverViewModel extends ChangeNotifier with DisposeAwareMixin {
  final DiscoverRoute params;

  DiscoverViewModel({
    required this.params,
  });

  List<_Page> pages() {
    return [
      _Page(
        id: DiscoverSegmentId.search,
        tooltip: tr("page.search.title"),
        icon: SpIcons.search,
        page: const DiscoverSearchContent(),
      ),
      _Page(
        id: DiscoverSegmentId.calendar,
        tooltip: tr("page.calendar.title"),
        icon: SpIcons.calendar,
        page: const DiscoverCalendarContent(),
      ),
      if (kHasRelaxSoundsFeature)
        _Page(
          id: DiscoverSegmentId.relaxSounds,
          tooltip: tr("page.relax_sounds.title"),
          icon: SpIcons.musicNote,
          page: const DiscoverRelaxSoundsContent(),
        ),
    ];
  }

  Set<DiscoverSegmentId> useToSelectedPages = {};
  bool shouldMaintainState(DiscoverSegmentId id) => useToSelectedPages.contains(id);

  late DiscoverSegmentId _selectedPage = params.initialPage ?? DiscoverSegmentId.calendar;
  DiscoverSegmentId get selectedPage => _selectedPage;
  int get selectedIndex => pages().indexWhere((page) => page.id == _selectedPage);

  void switchSelectedPage(DiscoverSegmentId value) {
    if (_selectedPage == value) return;
    _selectedPage = value;
    useToSelectedPages.add(value);
    notifyListeners();
  }
}

class _Page {
  final DiscoverSegmentId id;
  final String tooltip;
  final IconData icon;
  final Widget page;

  _Page({
    required this.id,
    required this.tooltip,
    required this.icon,
    required this.page,
  });
}
