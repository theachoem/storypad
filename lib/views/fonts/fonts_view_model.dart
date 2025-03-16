import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/widgets/base_view/base_view_model.dart';
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
    currentFontFamily = params.currentFontFamily;
    currentFontWeight = params.currentFontWeight;

    load();
  }

  late final List<String> fonts = GoogleFonts.asMap().keys.toList();
  List<String>? recentlySelectedFonts;
  List<FontGroup>? fontGroups;

  late String currentFontFamily;
  late FontWeight currentFontWeight;

  Future<void> load() async {
    recentlySelectedFonts = await RecentlySelectedFontsStorage().readList();
    fontGroups = constructGroup();
    notifyListeners();
  }

  Future<void> changeFont(String fontFamily) async {
    currentFontFamily = fontFamily;
    params.onChanged(fontFamily);
    notifyListeners();

    await saveToRecently(fontFamily);
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
      FontGroup(label: tr("general.defaults"), fontFamilies: [kDefaultFontFamily]),
      if (recentlySelectedFonts != null) FontGroup(label: tr("general.recently"), fontFamilies: recentlySelectedFonts!),
      ...fontGroups,
    ];
  }

  Future<void> saveToRecently(String fontFamily) async {
    if (fontFamily == kDefaultFontFamily) return;

    await RecentlySelectedFontsStorage().add(fontFamily);
    await load();
  }
}
