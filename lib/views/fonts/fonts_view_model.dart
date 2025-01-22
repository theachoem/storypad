import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storypad/core/base/base_view_model.dart';
import 'package:storypad/core/constants/theme_constant.dart';
import 'package:storypad/core/storages/recently_selected_fonts_storage.dart';
import 'fonts_view.dart';

class FontGroup {
  final String label;
  final List<String> fontFamilies;

  FontGroup({
    required this.label,
    required this.fontFamilies,
  });
}

class FontsViewModel extends BaseViewModel {
  final FontsRoute params;
  final BuildContext context;

  FontsViewModel({
    required this.params,
    required this.context,
  }) {
    load();
  }

  late final List<String> fonts = GoogleFonts.asMap().keys.toList();
  List<String>? recentlySelectedFonts;
  List<FontGroup>? fontGroups;

  Future<void> load() async {
    recentlySelectedFonts = await RecentlySelectedFontsStorage().readList();
    fontGroups = constructGroup();
    notifyListeners();
  }

  List<FontGroup> constructGroup() {
    Map<String, List<String>> groupedFonts = SplayTreeMap();

    for (String font in fonts) {
      String label = font[0].toUpperCase();
      groupedFonts.putIfAbsent(label, () => []).add(font);
    }

    List<FontGroup> fontGroups = groupedFonts.entries.map((entry) {
      return FontGroup(label: entry.key, fontFamilies: entry.value);
    }).toList();

    return [
      FontGroup(label: 'Defaults', fontFamilies: [ThemeConstant.defaultFontFamily]),
      if (recentlySelectedFonts != null) FontGroup(label: 'Recently', fontFamilies: recentlySelectedFonts!),
      ...fontGroups,
    ];
  }

  Future<void> saveToRecently(String fontFamily) async {
    if (fontFamily == ThemeConstant.defaultFontFamily) return;

    await RecentlySelectedFontsStorage().add(fontFamily);
    await load();
  }
}
