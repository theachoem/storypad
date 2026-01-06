import 'dart:async';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';
import 'package:storypad/app_theme.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';
import 'package:storypad/core/helpers/path_helper.dart';
import 'package:storypad/core/mixins/debounched_callback.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/gen/story_backgrounds.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/add_ons/add_ons_view.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_firestore_storage_downloader_builder.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_story_preference_theme.dart';

const double _backgroundCardHeight = 123;
const double _backgroundCardAspectRatio = 2 / 2.5;

typedef OnBackgroundThemeChanged =
    void Function({
      int? colorSeedValue,
      int? colorTone,
      String? backgroundImagePath,
    });

class SpBackgroundPicker extends StatefulWidget {
  const SpBackgroundPicker({
    super.key,
    required this.colorSeedValue,
    required this.colorTone,
    required this.backgroundImagePath,
    required this.onThemeChanged,
  });

  final int? colorSeedValue;
  final int? colorTone;
  final String? backgroundImagePath;
  final OnBackgroundThemeChanged onThemeChanged;

  @override
  State<SpBackgroundPicker> createState() => _SpBackgroundPickerState();
}

class _SpBackgroundPickerState extends State<SpBackgroundPicker> with DebounchedCallback {
  int? get colorSeedValue => widget.colorSeedValue;
  int? get colorTone => widget.colorTone;
  String? get backgroundImagePath => widget.backgroundImagePath;

  final Map<String, GlobalKey> groupLabelKeys = {};

  late String selectedGroup;
  late final Map<String, String> allGroups = {
    'colors': tr('general.background_group.colors'),
    'cute': tr('general.background_group.cute'),
    'dailylife': tr('general.background_group.dailylife'),
    'garden': tr('general.background_group.garden'),
    'scenery': tr('general.background_group.scenery'),
  };

  @override
  void initState() {
    super.initState();

    for (var key in allGroups.keys) {
      groupLabelKeys[key] = GlobalKey();
    }

    if (colorSeedValue != null) {
      selectedGroup = 'colors';
    } else {
      String? selectedGroup = backgroundImagePath
          ?.split('__')
          .where((group) => StoryBackgrounds.all.containsKey(group))
          .firstOrNull;

      this.selectedGroup = selectedGroup != null && allGroups.containsKey(selectedGroup)
          ? selectedGroup
          : allGroups.keys.first;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = groupLabelKeys[selectedGroup];
      if (selectedGroup != allGroups.keys.first && key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          curve: Curves.ease,
          duration: Durations.medium1,
          alignment: 0.5,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      children: [
        if (allGroups.length > 1) buildGroupSelector(),
        if (StoryBackgrounds.all.containsKey(selectedGroup)) ...[
          const SizedBox(height: 8),
          _ImageBackgroundCarousel(
            key: ValueKey(selectedGroup),
            colorSeedValue: colorSeedValue,
            colorTone: colorTone,
            backgroundImagePath: backgroundImagePath,
            groupName: selectedGroup,
            backgrounds: StoryBackgrounds.all[selectedGroup]!,
            onThemeChanged: widget.onThemeChanged,
          ),
        ],
        if (selectedGroup == 'colors') ...[
          const SizedBox(height: 8),
          _ColorBackgroundsCarousel(
            colorSeedValue: colorSeedValue,
            colorTone: colorTone,
            backgroundImagePath: backgroundImagePath,
            onThemeChanged: widget.onThemeChanged,
          ),
        ],
      ],
    );
  }

  Widget buildGroupSelector() {
    return Stack(
      children: [
        Align(
          alignment: .centerLeft,
          child: SingleChildScrollView(
            scrollDirection: .horizontal,
            padding: const EdgeInsets.only(left: 16.0, right: 48.0),
            child: Row(
              spacing: 8.0,
              children: allGroups.entries.map((entry) {
                return FilterChip(
                  key: groupLabelKeys[entry.key],
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
        ),
        if (selectedGroup != 'colors')
          Positioned(
            right: 0,
            child: SpFadeIn.fromRight(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: .centerLeft,
                    end: .centerRight,
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
                      Theme.of(context).scaffoldBackgroundColor,
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                  ),
                ),
                child: IconButton(
                  icon: const Icon(SpIcons.info),
                  onPressed: () => showLicenseDialog(context),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> showLicenseDialog(BuildContext context) {
    return showAdaptiveDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog.adaptive(
          content: Container(
            padding: const EdgeInsets.only(top: 8.0),
            child: MarkdownBody(
              listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
              styleSheet: MarkdownStyleSheet(
                p: TextTheme.of(context).bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                a: TextTheme.of(context).bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  decorationColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  decoration: TextDecoration.underline,
                ),
              ),
              data: tr(
                "general.story_background_credits",
                context: context,
                namedArgs: {
                  'BACKGROUND_LINK': "[Freepik](https://freepik.com)",
                  'APP_NAME': kAppName,
                },
              ),
              onTapLink: (text, href, title) => UrlOpenerService.openForMarkdown(
                context: context,
                text: text,
                href: href,
                title: title,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ImageBackgroundCarousel extends StatefulWidget {
  const _ImageBackgroundCarousel({
    required super.key,
    required this.groupName,
    required this.backgrounds,
    required this.colorSeedValue,
    required this.colorTone,
    required this.backgroundImagePath,
    required this.onThemeChanged,
  });

  final String groupName;
  final int? colorSeedValue;
  final int? colorTone;
  final String? backgroundImagePath;
  final List<StoryBackground> backgrounds;
  final OnBackgroundThemeChanged onThemeChanged;

  @override
  State<_ImageBackgroundCarousel> createState() => _ImageBackgroundCarouselState();
}

class _ImageBackgroundCarouselState extends State<_ImageBackgroundCarousel> {
  late final CarouselController controller;

  bool isSelected(StoryBackground background) {
    return widget.backgroundImagePath == basename(background.path);
  }

  @override
  void initState() {
    controller = CarouselController();
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      int? lastSelectedIndex;
      for (int i = 0; i < widget.backgrounds.length; i++) {
        if (isSelected(widget.backgrounds[i])) lastSelectedIndex = i;
      }

      if (lastSelectedIndex != null) {
        controller.jumpTo(
          min(
            controller.position.maxScrollExtent,
            _backgroundCardHeight * _backgroundCardAspectRatio * lastSelectedIndex,
          ),
        );
      }
    });
  }

  // First 3 backgrounds has no restriction.
  bool isLocked(int index) {
    return index > 0 && !context.read<InAppPurchaseProvider>().backgrounds;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(widget.groupName),
      height: _backgroundCardHeight,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      clipBehavior: .hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9.0),
      ),
      child: CarouselView(
        controller: controller,
        itemExtent: _backgroundCardHeight * _backgroundCardAspectRatio,
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Theme.of(context).dividerColor, width: 1.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        onTap: (index) async {
          HapticFeedback.selectionClick();

          if (isLocked(index)) {
            AddOnsRoute.pushAndNavigateTo(product: .backgrounds, context: context);
            return;
          }

          final background = widget.backgrounds[index];
          bool selected = widget.backgroundImagePath == basename(background.path);

          widget.onThemeChanged(
            colorTone: null,
            colorSeedValue: null,
            backgroundImagePath: selected ? null : basename(background.path),
          );
        },
        children: List.generate(widget.backgrounds.length, (index) {
          return _ImageItem(
            background: widget.backgrounds[index],
            locked: isLocked(index),
            selected: isSelected(widget.backgrounds[index]),
          );
        }),
      ),
    );
  }
}

class _ImageItem extends StatelessWidget {
  const _ImageItem({
    required this.background,
    required this.locked,
    required this.selected,
  });

  final StoryBackground background;
  final bool locked;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        buildImage(),
        if (selected) buildSelectedCheck(),
        if (locked) ...[
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Icon(
                SpIcons.lock,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Positioned buildImage() {
    return Positioned.fill(
      child: AspectRatio(
        aspectRatio: 2 / 2.5,
        child: SpFirestoreStorageDownloaderBuilder(
          filePath: background.path,
          builder: (context, file, failed) {
            if (failed || file == null) return const SizedBox.shrink();
            return Image.file(
              file,
              fit: .cover,
              filterQuality: .low,
              alignment: switch (background.align) {
                .left => .centerLeft,
                .center => .center,
                .right => .centerRight,
              },
            );
          },
        ),
      ),
    );
  }

  Widget buildSelectedCheck() {
    final Color foregroundColor = switch (background.textColor) {
      .black => Colors.black.withValues(alpha: 0.7),
      .white => Colors.white.withValues(alpha: 0.7),
    };

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
    required this.colorSeedValue,
    required this.colorTone,
    required this.backgroundImagePath,
    required this.onThemeChanged,
  });

  final int? colorSeedValue;
  final int? colorTone;
  final String? backgroundImagePath;
  final OnBackgroundThemeChanged onThemeChanged;

  @override
  State<_ColorBackgroundsCarousel> createState() => _ColorBackgroundsCarouselState();
}

class _ColorBackgroundsCarouselState extends State<_ColorBackgroundsCarousel> {
  late final CarouselController controller;

  final backgroundColors = [
    ColorSwatch(Colors.black.toARGB32(), {
      200: Colors.white,
      700: Colors.black,
    }),
    ...kMaterialColors,
  ];

  @override
  void initState() {
    controller = CarouselController();
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      int? lastSelectedIndex;

      for (int i = 0; i < backgroundColors.length; i++) {
        bool selected = widget.colorSeedValue == backgroundColors[i].toARGB32();
        if (selected) lastSelectedIndex = i;
      }

      if (lastSelectedIndex != null) {
        controller.jumpTo(
          min(
            controller.position.maxScrollExtent,
            _backgroundCardHeight * _backgroundCardAspectRatio * lastSelectedIndex,
          ),
        );
      }
    });
  }

  int get colorToneFallback => widget.colorTone ?? 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void onTap(List<ColorSwatch<dynamic>> backgroundColors, int index) {
    HapticFeedback.selectionClick();

    Color backgroundColor = backgroundColors[index];
    bool selected = widget.colorSeedValue == backgroundColor.toARGB32();
    int nextColorTone;

    if (selected) {
      nextColorTone = colorToneFallback + 33 > 99 ? 0 : colorToneFallback + 33;
    } else {
      nextColorTone = 33;
    }

    widget.onThemeChanged(
      colorSeedValue: nextColorTone == 0 ? null : backgroundColor.toARGB32(),
      colorTone: nextColorTone == 0 ? null : nextColorTone,
      backgroundImagePath: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('colors'),
      height: _backgroundCardHeight,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      clipBehavior: .hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9.0),
      ),
      child: CarouselView(
        controller: controller,
        scrollDirection: .horizontal,
        itemExtent: _backgroundCardHeight * _backgroundCardAspectRatio,
        padding: const EdgeInsets.symmetric(horizontal: 6.0),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        onTap: (index) => onTap(backgroundColors, index),
        children: List.generate(backgroundColors.length, (index) {
          return SpFadeIn(child: buildColorItem(backgroundColors[index], context));
        }),
      ),
    );
  }

  Widget buildColorItem(ColorSwatch<dynamic> backgroundColor, BuildContext context) {
    bool selected = widget.colorSeedValue == backgroundColor.toARGB32();

    ColorScheme colorScheme = AppTheme.isDarkMode(context)
        ? SpStoryPreferenceThemeConstructor.getDarkColorScheme(backgroundColor, DynamicSchemeVariant.tonalSpot)
        : SpStoryPreferenceThemeConstructor.getLightColorScheme(backgroundColor, DynamicSchemeVariant.tonalSpot);

    Color? scaffoldBackgroundColor = SpStoryPreferenceThemeConstructor.getScaffoldBackgroundColor(
      colorScheme: colorScheme,
      preferences: StoryPreferencesDbModel.create().copyWith(
        backgroundImagePath: null,
        colorSeedValue: backgroundColor.toARGB32(),
        colorTone: selected ? widget.colorTone : 0,
      ),
    );

    return Column(
      children: [
        Flexible(
          child: Stack(
            children: [
              Container(color: scaffoldBackgroundColor),
              buildToneBackground(selected, colorScheme),
              buildToneCurrentProgress(selected),
            ],
          ),
        ),
        Flexible(child: Container(color: backgroundColor[500])),
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
              begin: colorToneFallback - 33 < 0 ? 0 : colorToneFallback - 33,
              end: colorToneFallback.toDouble(),
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
            color: colorScheme.brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.2),
            value: 1,
            strokeCap: StrokeCap.round,
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }
}
