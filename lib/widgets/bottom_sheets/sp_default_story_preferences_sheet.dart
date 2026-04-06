import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/objects/default_story_preferences_object.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_background_picker.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_layout_type_section.dart';

class SpDefaultStoryPreferencesSheet extends BaseBottomSheet {
  const SpDefaultStoryPreferencesSheet();

  @override
  bool get fullScreen => true;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    if (kIsCupertino) {
      return buildView(context, bottomPadding);
    } else {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        builder: (context, controller) {
          return PrimaryScrollController(
            controller: controller,
            child: buildView(context, bottomPadding),
          );
        },
      );
    }
  }

  Widget buildView(BuildContext context, double bottomPadding) {
    return _StoryEditingPreferencesSheetContent(
      bottomPadding: bottomPadding,
    );
  }
}

class _StoryEditingPreferencesSheetContent extends StatefulWidget {
  const _StoryEditingPreferencesSheetContent({
    required this.bottomPadding,
  });

  final double bottomPadding;

  @override
  State<_StoryEditingPreferencesSheetContent> createState() => _StoryEditingPreferencesSheetContentState();
}

class _StoryEditingPreferencesSheetContentState extends State<_StoryEditingPreferencesSheetContent> {
  late var defaultStoryPreferences = context.read<DevicePreferencesProvider>().preferences.defaultStoryPreferences;
  late var defaultStoryPreferencesDefault = DefaultStoryPreferencesObject();
  late var initialStoryEditingPreferences = defaultStoryPreferences;

  bool get changed =>
      jsonEncode(defaultStoryPreferences.toJson()) != jsonEncode(initialStoryEditingPreferences.toJson());

  bool get resettable =>
      jsonEncode(defaultStoryPreferences.toJson()) != jsonEncode(defaultStoryPreferencesDefault.toJson());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(tr("list_tile.default_story_preferences.title")),
        automaticallyImplyLeading: !CupertinoSheetRoute.hasParentSheet(context),
        actions: [
          if (resettable)
            IconButton(
              icon: const Icon(SpIcons.refresh),
              onPressed: () => setState(() => defaultStoryPreferences = defaultStoryPreferencesDefault),
            ),
          if (CupertinoSheetRoute.hasParentSheet(context))
            CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context)),
        ],
      ),
      bottomNavigationBar: Visibility(
        visible: changed,
        child: SpFadeIn.fromBottom(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 1),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ).add(EdgeInsets.only(bottom: widget.bottomPadding)),
                child: FilledButton.icon(
                  label: Text(tr("button.save")),
                  onPressed: () => Navigator.maybePop(context, defaultStoryPreferences),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        controller: PrimaryScrollController.maybeOf(context),
        children: [
          const SizedBox(height: 8.0),
          SpBackgroundPicker(
            backgroundColor: ColorScheme.of(context).surfaceContainerLow,
            colorSeedValue: defaultStoryPreferences.defaultColorSeedValue,
            colorTone: defaultStoryPreferences.defaultColorTone,
            backgroundImagePath: defaultStoryPreferences.defaultBackgroundImagePath,
            onThemeChanged: ({colorSeedValue, colorTone, backgroundImagePath}) {
              defaultStoryPreferences = defaultStoryPreferences.copyWith(
                defaultColorSeedValue: colorSeedValue,
                defaultColorTone: colorTone,
                defaultBackgroundImagePath: backgroundImagePath,
              );
              setState(() {});
            },
          ),
          const SizedBox(height: 12.0),
          SpLayoutTypeSection(
            selected: defaultStoryPreferences.defaultLayoutType,
            onThemeChanged: (layoutType) {
              defaultStoryPreferences = defaultStoryPreferences.copyWith(defaultLayoutType: layoutType);
              setState(() {});
            },
          ),
          SizedBox(height: widget.bottomPadding),
        ],
      ),
    );
  }
}
