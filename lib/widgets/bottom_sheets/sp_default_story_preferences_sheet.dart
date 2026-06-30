import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/objects/default_story_preferences_object.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/paywall/paywall_view.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_background_picker.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_layout_type_section.dart';

class SpDefaultStoryPreferencesSheet extends BaseBottomSheet {
  const SpDefaultStoryPreferencesSheet({this.onChanged});

  /// Reports the live draft on every change ([null] when nothing differs from
  /// the saved value). The caller commits it after the sheet closes.
  final void Function(DefaultStoryPreferencesObject? preferences)? onChanged;

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
      onChanged: onChanged,
    );
  }
}

class _StoryEditingPreferencesSheetContent extends StatefulWidget {
  const _StoryEditingPreferencesSheetContent({
    required this.bottomPadding,
    this.onChanged,
  });

  final double bottomPadding;
  final void Function(DefaultStoryPreferencesObject? preferences)? onChanged;

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

  void _apply(DefaultStoryPreferencesObject next) {
    setState(() => defaultStoryPreferences = next);
    widget.onChanged?.call(changed ? defaultStoryPreferences : null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(tr("list_tile.default_story_preferences.title")),
        automaticallyImplyLeading: !CupertinoSheetRoute.hasParentSheet(context),
        actions: [
          // Pro users save automatically when the sheet closes, so no save button.
          // Non-pro users keep a locked save button that opens the paywall; they can
          // still preview changes but cannot persist them.
          if (changed && !Provider.of<InAppPurchaseProvider>(context).isProUser)
            IconButton(
              tooltip: tr("button.done"),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(SpIcons.save, color: Theme.of(context).colorScheme.primary),
                  const Positioned(
                    top: -2,
                    right: -8,
                    child: Icon(SpIcons.lock, size: 12.0),
                  ),
                ],
              ),
              onPressed: () => const PaywallRoute(initialFocus: .customizations).push(context),
            ),
          IconButton(
            icon: const Icon(SpIcons.refresh),
            onPressed: resettable ? () => _apply(defaultStoryPreferencesDefault) : null,
          ),
          if (CupertinoSheetRoute.hasParentSheet(context))
            CloseButton(onPressed: () => CupertinoSheetRoute.popSheet(context)),
        ],
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
              _apply(
                defaultStoryPreferences.copyWith(
                  defaultColorSeedValue: colorSeedValue,
                  defaultColorTone: colorTone,
                  defaultBackgroundImagePath: backgroundImagePath,
                ),
              );
            },
          ),
          const SizedBox(height: 12.0),
          SpLayoutTypeSection(
            selected: defaultStoryPreferences.defaultLayoutType,
            onThemeChanged: (layoutType) {
              _apply(defaultStoryPreferences.copyWith(defaultLayoutType: layoutType));
            },
          ),
          SizedBox(height: widget.bottomPadding),
        ],
      ),
    );
  }
}
