// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/views/discover/segments/discover_calendar_content.dart';
import 'package:storypad/views/discover/segments/discover_relax_sounds_content.dart';
import 'package:storypad/views/discover/segments/discover_search_content.dart';
import 'discover_view.dart';

class _Page {
  final String id;
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

class DiscoverViewModel extends ChangeNotifier with DisposeAwareMixin {
  final DiscoverRoute params;

  DiscoverViewModel({
    required this.params,
  });

  List<_Page> pages() {
    return [
      _Page(
        id: "search",
        tooltip: "Search",
        icon: Icons.search_outlined,
        page: const DiscoverSearchContent(),
      ),
      _Page(
        id: "calendar",
        tooltip: "Calendar",
        icon: Icons.calendar_month_outlined,
        page: const DiscoverCalendarContent(),
      ),
      _Page(
        id: "relax_sounds",
        tooltip: "Relax Sounds",
        icon: Icons.music_note_outlined,
        page: const DiscoverRelaxSoundsContent(),
      ),
    ];
  }

  String _selectedPage = "search";
  String get selectedPage => _selectedPage;
  int get selectedIndex => pages().indexWhere((page) => page.id == _selectedPage);

  void switchSelectedPage(String value) {
    _selectedPage = value;
    notifyListeners();
  }
}
