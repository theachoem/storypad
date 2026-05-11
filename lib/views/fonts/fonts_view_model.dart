import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/storages/recently_selected_fonts_storage.dart';
import 'package:storypad/views/paywall/paywall_view.dart';
import 'fonts_view.dart';

class FontGroup {
  final String label;
  final List<String> fontFamilies;

  FontGroup({
    required this.label,
    required this.fontFamilies,
  });
}

class FontsViewModel extends ChangeNotifier with DisposeAwareMixin {
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

  // When customization is locked (for example, global theme customization),
  // only a limited free subset is selectable: the default font plus up to
  // 5 fonts from each group.
  Set<String> freeGlobalFonts = {};

  late String currentFontFamily;
  late FontWeight currentFontWeight;

  Future<void> load() async {
    recentlySelectedFonts = await RecentlySelectedFontsStorage().readList();
    fontGroups = constructGroup();

    freeGlobalFonts = {kDefaultFontFamily};
    fontGroups?.forEach((group) {
      freeGlobalFonts.addAll(group.fontFamilies.where((font) => fonts.contains(font)).take(5));
    });

    notifyListeners();
  }

  bool available(String fontFamily) {
    if (params.locked) {
      return freeGlobalFonts.contains(fontFamily);
    }

    return true;
  }

  Future<void> changeFont(String fontFamily) async {
    if (params.locked && !freeGlobalFonts.contains(fontFamily)) {
      const PaywallRoute(initialFocus: .customizations).push(context);
      return;
    }

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

    List<FontGroup> alphabeticalGroups = groupedFonts.entries.map((entry) {
      return FontGroup(label: entry.key, fontFamilies: entry.value);
    }).toList();

    return [
      FontGroup(label: tr("general.defaults"), fontFamilies: [kDefaultFontFamily]),
      if (recentlySelectedFonts != null) FontGroup(label: tr("general.recently"), fontFamilies: recentlySelectedFonts!),
      ...alphabeticalGroups,
    ];
  }

  Future<void> saveToRecently(String fontFamily) async {
    if (fontFamily == kDefaultFontFamily) return;

    await RecentlySelectedFontsStorage().add(fontFamily);
    await load();
  }
}
