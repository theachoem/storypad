import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/extensions/string_extension.dart';
import 'package:storypad/core/helpers/path_helper.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/gen/story_backgrounds.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_firestore_storage_downloader_builder.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_story_preference_theme.dart';

class SpBackgroundPicker extends StatefulWidget {
  const SpBackgroundPicker({
    super.key,
    required this.preferences,
    required this.onThemeChanged,
  });

  final StoryPreferencesDbModel preferences;
  final void Function(StoryPreferencesDbModel preferences) onThemeChanged;

  @override
  State<SpBackgroundPicker> createState() => _SpBackgroundPickerState();
}

class _SpBackgroundPickerState extends State<SpBackgroundPicker> with DebounchedCallback {
  StoryPreferencesDbModel get preferences => widget.preferences;

  late String selectedGroup;
  late final Map<String, String> allGroups = {
    'colors': 'Colors',
    for (final key in StoryBackgrounds.all.keys) key: key.capitalize,
  };

  @override
  void initState() {
    super.initState();

    selectedGroup =
        preferences.backgroundImagePath
            ?.split('__')
            .firstWhere((group) => StoryBackgrounds.all.containsKey(group), orElse: () => 'colors') ??
        'colors';
    selectedGroup = allGroups.containsKey(selectedGroup) ? selectedGroup : 'colors';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      children: [
        buildGroupSelector(),
        if (StoryBackgrounds.all.containsKey(selectedGroup)) ...[
          const SizedBox(height: 8),
          _ImageBackgroundCarousel(
            key: ValueKey(selectedGroup),
            preferences: preferences,
            widget: widget,
            groupName: selectedGroup,
            backgrounds: StoryBackgrounds.all[selectedGroup]!,
          ),
        ],
        if (selectedGroup == 'colors') ...[
          const SizedBox(height: 8),
          _ColorBackgroundsCarousel(preferences: preferences, widget: widget),
        ],
      ],
    );
  }

  Widget buildGroupSelector() {
    return Align(
      alignment: .centerLeft,
      child: SingleChildScrollView(
        scrollDirection: .horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          spacing: 8.0,
          children: allGroups.entries.map((entry) {
            return FilterChip(
              selected: selectedGroup == entry.key,
              label: Text(entry.value),
              showCheckmark: false,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    selectedGroup = entry.key;
                  });
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ImageBackgroundCarousel extends StatefulWidget {
  const _ImageBackgroundCarousel({
    required super.key,
    required this.preferences,
    required this.widget,
    required this.groupName,
    required this.backgrounds,
  });

  final StoryPreferencesDbModel preferences;
  final SpBackgroundPicker widget;
  final String groupName;
  final List<StoryBackground> backgrounds;

  @override
  State<_ImageBackgroundCarousel> createState() => _ImageBackgroundCarouselState();
}

class _ImageBackgroundCarouselState extends State<_ImageBackgroundCarousel> {
  final Map<int, GlobalKey> backgroundKeys = {};

  @override
  void initState() {
    super.initState();

    Future.delayed(Durations.medium2, () {
      int? lastSelectedIndex;

      for (int i = 0; i < widget.backgrounds.length; i++) {
        bool selected = widget.preferences.backgroundImagePath == basename(widget.backgrounds[i].path);
        if (selected) lastSelectedIndex = i;
      }

      if (lastSelectedIndex != null) {
        _scrollToIndex(
          index: lastSelectedIndex,
          keys: backgroundKeys,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(widget.groupName),
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      clipBehavior: .hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9.0),
      ),
      child: CarouselView(
        scrollDirection: .horizontal,
        itemExtent: 72 * (16 / 9),
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        onTap: (index) async {
          final background = widget.backgrounds[index];
          bool selected = widget.preferences.backgroundImagePath == basename(background.path);

          widget.widget.onThemeChanged(
            widget.preferences.copyWith(
              colorTone: null,
              colorSeedValue: null,
              backgroundImagePath: selected ? null : basename(background.path),
            ),
          );
        },
        children: List.generate(widget.backgrounds.length, (index) {
          backgroundKeys[index] ??= GlobalKey();
          return SpFadeIn(
            key: backgroundKeys[index],
            delay: Duration(milliseconds: 50 * index),
            duration: Durations.medium1,
            child: buildImageItem(widget.backgrounds[index]),
          );
        }),
      ),
    );
  }

  Widget buildImageItem(StoryBackground background) {
    return Stack(
      children: [
        Positioned.fill(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: SpFirestoreStorageDownloaderBuilder(
              filePath: background.path,
              builder: (context, file, failed) {
                if (failed || file == null) return const SizedBox.shrink();
                return Image.file(
                  file,
                  fit: .cover,
                );
              },
            ),
          ),
        ),
        if (widget.preferences.backgroundImagePath == basename(background.path)) ...[
          buildSelectedCheck(
            foregroundColor: switch (background.textColor) {
              .black => Colors.black.withValues(alpha: 0.7),
              .white => Colors.white.withValues(alpha: 0.7),
            },
          ),
        ],
      ],
    );
  }

  Widget buildSelectedCheck({
    Key? key,
    Color? foregroundColor,
  }) {
    return Positioned(
      key: ValueKey('$foregroundColor'),
      top: 8,
      right: 8,
      child: SpFadeIn.fromBottom(
        child: Icon(
          SpIcons.checkCircle,
          color: foregroundColor,
        ),
      ),
    );
  }
}

class _ColorBackgroundsCarousel extends StatefulWidget {
  const _ColorBackgroundsCarousel({
    required this.preferences,
    required this.widget,
  });

  final StoryPreferencesDbModel preferences;
  final SpBackgroundPicker widget;

  @override
  State<_ColorBackgroundsCarousel> createState() => _ColorBackgroundsCarouselState();
}

class _ColorBackgroundsCarouselState extends State<_ColorBackgroundsCarousel> {
  final Map<int, GlobalKey> colorKeys = {};

  final backgroundColors = [
    ColorSwatch(Colors.black.toARGB32(), {
      200: Colors.white,
      700: Colors.black,
    }),
    ...kMaterialColors,
  ];

  @override
  void initState() {
    super.initState();

    Future.delayed(Durations.medium2, () {
      int? lastSelectedIndex;
      for (int i = 0; i < backgroundColors.length; i++) {
        bool selected = widget.preferences.colorSeed?.toARGB32() == backgroundColors[i].toARGB32();
        if (selected) lastSelectedIndex = i;
      }

      if (lastSelectedIndex != null) {
        _scrollToIndex(
          index: lastSelectedIndex,
          keys: colorKeys,
        );
      }
    });
  }

  void onTap(List<ColorSwatch<dynamic>> backgroundColors, int index) {
    HapticFeedback.selectionClick();

    Color backgroundColor = backgroundColors[index];
    bool selected = widget.preferences.colorSeed?.toARGB32() == backgroundColor.toARGB32();
    int nextColorTone;

    if (selected) {
      nextColorTone = widget.preferences.colorToneFallback + 33 > 99 ? 0 : widget.preferences.colorToneFallback + 33;
    } else {
      nextColorTone = 33;
    }

    widget.widget.onThemeChanged(
      widget.preferences.copyWith(
        backgroundImagePath: null,
        colorSeedValue: nextColorTone == 0 ? null : backgroundColor.toARGB32(),
        colorTone: nextColorTone == 0 ? null : nextColorTone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('colors'),
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      clipBehavior: .hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9.0),
      ),
      child: CarouselView(
        scrollDirection: .horizontal,
        itemExtent: 72 * (16 / 9),
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        onTap: (index) => onTap(backgroundColors, index),
        children: List.generate(backgroundColors.length, (index) {
          colorKeys[index] ??= GlobalKey();
          return KeyedSubtree(
            key: colorKeys[index],
            child: buildColorItem(backgroundColors[index], context),
          );
        }),
      ),
    );
  }

  Widget buildColorItem(ColorSwatch<dynamic> backgroundColor, BuildContext context) {
    bool selected = widget.preferences.colorSeed?.toARGB32() == backgroundColor.toARGB32();

    ColorScheme colorScheme = AppTheme.isDarkMode(context)
        ? SpStoryPreferenceTheme.getDarkColorScheme(backgroundColor, DynamicSchemeVariant.tonalSpot)
        : SpStoryPreferenceTheme.getLightColorScheme(backgroundColor, DynamicSchemeVariant.tonalSpot);

    Color? scaffoldBackgroundColor = SpStoryPreferenceTheme.getScaffoldBackgroundColor(
      colorScheme: colorScheme,
      preferences: widget.preferences.copyWith(
        backgroundImagePath: null,
        colorSeedValue: backgroundColor.toARGB32(),
        colorTone: selected ? widget.preferences.colorTone : 0,
      ),
    );

    return Stack(
      children: [
        Row(
          children: [
            Flexible(child: Container(color: backgroundColor[500])),
            Flexible(
              child: Stack(
                children: [
                  Container(color: scaffoldBackgroundColor),
                  buildToneBackground(selected, colorScheme),
                  buildToneCurrentProgress(selected),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildToneCurrentProgress(bool selected) {
    return Visibility(
      visible: selected,
      child: Positioned(
        top: 8,
        right: 8,
        child: SizedBox(
          width: 24,
          height: 24,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: widget.preferences.colorToneFallback - 33 < 0 ? 0 : widget.preferences.colorToneFallback - 33,
              end: widget.preferences.colorToneFallback.toDouble(),
            ),
            duration: Durations.long1,
            curve: Curves.easeInOutQuart,
            builder: (context, value, _) {
              return CircularProgressIndicator(
                value: value / 100,
                strokeCap: StrokeCap.round,
                strokeWidth: 3,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildToneBackground(bool selected, ColorScheme colorScheme) {
    return Visibility(
      visible: selected,
      child: Positioned(
        top: 8,
        right: 8,
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: colorScheme.readOnly.surface5,
            value: 1,
            strokeCap: StrokeCap.round,
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }
}

Future<void> _scrollToIndex({
  required Map<int, GlobalKey<State<StatefulWidget>>> keys,
  required int index,
}) async {
  if (keys[index]?.currentContext != null) return;
  for (int i = 0; i <= index; i++) {
    if (i == index) {
      final key = keys[i];

      if (key?.currentContext != null) {
        await Scrollable.ensureVisible(
          key!.currentContext!,
          duration: Durations.short1,
          curve: Curves.ease,
          alignment: 0.5,
        );
      }
    } else {
      if (keys[i]?.currentContext != null) {
        await Scrollable.ensureVisible(
          keys[i]!.currentContext!,
          duration: Duration.zero,
          curve: Curves.ease,
          alignment: 0.5,
        );
        Completer<void> completer = Completer<void>();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          completer.complete();
        });
        await completer.future;
      }
    }
  }
}
