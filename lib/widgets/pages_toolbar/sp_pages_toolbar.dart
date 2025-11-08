import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';
import 'package:storypad/core/objects/story_page_object.dart';
import 'package:storypad/core/types/app_product.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/add_ons/add_ons_view.dart';
import 'package:storypad/views/settings/local_widgets/font_weight_tile.dart';
import 'package:storypad/widgets/bottom_sheets/sp_font_weight_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_fonts_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_image_picker_bottom_sheet.dart';
import 'package:storypad/widgets/bottom_sheets/sp_voice_recording_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_quill_toolbar_color_button.dart';

part './quill_toolbar.dart';
part './title_toolbar.dart';

class SpPagesToolbar extends StatefulWidget {
  const SpPagesToolbar({
    super.key,
    required this.pages,
    required this.preferences,
    required this.onThemeChanged,
    required this.backgroundColor,
    required this.managingPage,
  });

  final bool managingPage;
  final List<StoryPageObject> pages;
  final StoryPreferencesDbModel preferences;
  final void Function(StoryPreferencesDbModel) onThemeChanged;
  final Color? backgroundColor;

  @override
  State<SpPagesToolbar> createState() => SpPagesToolbarState();
}

class SpPagesToolbarState extends State<SpPagesToolbar> {
  Map<int, void Function()> titleFocusListenters = {};
  Map<int, void Function()> bodyFocusListenters = {};

  bool titleFocused = false;
  int? bodyFocusedIndex;

  @override
  void initState() {
    super.initState();
    setupListeners();
  }

  void setupListeners() {
    for (int index = 0; index < widget.pages.length; index++) {
      titleFocusListenters[index] = () => titleFocusListener(index);
      bodyFocusListenters[index] = () => bodyFocusListener(index);

      widget.pages[index].titleFocusNode.addListener(titleFocusListenters[index]!);
      widget.pages[index].bodyFocusNode.addListener(bodyFocusListenters[index]!);
    }
  }

  @override
  void didUpdateWidget(covariant SpPagesToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);

    clearPreviousListeners();
    setupListeners();
  }

  void clearPreviousListeners() {
    for (int index = 0; index < widget.pages.length; index++) {
      if (titleFocusListenters[index] != null) {
        widget.pages[index].titleFocusNode.removeListener(titleFocusListenters[index]!);
      }
      if (bodyFocusListenters[index] != null) {
        widget.pages[index].bodyFocusNode.removeListener(bodyFocusListenters[index]!);
      }
    }

    titleFocusListenters.clear();
    bodyFocusListenters.clear();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    clearPreviousListeners();
    setupListeners();
  }

  void titleFocusListener(int index) {
    if (index >= widget.pages.length) return;
    if (widget.pages[index].titleFocusNode.hasFocus) {
      titleFocused = true;
    } else {
      bool everyBodyNoFocus = widget.pages.every((e) => !e.bodyFocusNode.hasFocus);
      if (everyBodyNoFocus && titleFocused) {
        titleFocused = true;
      } else {
        titleFocused = false;
      }
    }

    if (mounted) setState(() {});
  }

  void bodyFocusListener(int index) {
    if (index >= widget.pages.length) return;
    if (widget.pages[index].bodyFocusNode.hasFocus) {
      bodyFocusedIndex = index;
      titleFocused = false;
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    clearPreviousListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: !widget.managingPage,
      child: Stack(
        fit: StackFit.loose,
        children: [
          if (titleFocused) buildTitleToolbar(context),
          if (!titleFocused)
            ...List.generate(
              widget.pages.length,
              (index) {
                return Visibility(
                  visible: index == bodyFocusedIndex,
                  child: Container(
                    color: widget.backgroundColor,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: _QuillToolbar(
                      controller: widget.pages[index].bodyController,
                      context: context,
                      backgroundColor: widget.backgroundColor,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget buildTitleToolbar(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).padding.left,
        right: MediaQuery.of(context).padding.right,
        bottom: MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _TitleToolbar(
        preferences: widget.preferences,
        onThemeChanged: (preferences) => widget.onThemeChanged(preferences),
      ),
    );
  }
}
