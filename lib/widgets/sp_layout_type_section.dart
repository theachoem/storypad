import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/types/page_layout_type.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_section_title.dart';

class SpLayoutTypeSection extends StatelessWidget {
  const SpLayoutTypeSection({
    super.key,
    required this.onThemeChanged,
    required this.selected,
  });

  final void Function(PageLayoutType layoutType) onThemeChanged;
  final PageLayoutType selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SpSectionTitle(title: tr("general.page_layout.title")),
        const SizedBox(height: 8.0),
        SizedBox(
          height: 150,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            itemCount: PageLayoutType.values.length,
            scrollDirection: Axis.horizontal,
            separatorBuilder: (context, index) => const SizedBox(width: 12.0),
            itemBuilder: (context, index) {
              final layoutType = PageLayoutType.values[index];

              return Column(
                spacing: 8.0,
                children: [
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Material(
                          color: ColorScheme.of(context).surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(4.0),
                            onTap: () => onThemeChanged(layoutType),
                            child: AspectRatio(
                              aspectRatio: 148 / 210,
                              child: buildLayoutDemo(layoutType, context),
                            ),
                          ),
                        ),
                        if (selected == layoutType) const _CheckedIcon(),
                      ],
                    ),
                  ),
                  Text(layoutType.translatedName),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildLayoutDemo(PageLayoutType layoutType, BuildContext context) {
    switch (layoutType) {
      case PageLayoutType.list:
        return Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            spacing: 6.0,
            children: List.generate(
              3,
              (index) {
                return Flexible(
                  child: Container(
                    decoration: BoxDecoration(
                      color: ColorScheme.of(context).readOnly.surface2,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      case PageLayoutType.pages:
        return Container(
          margin: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: ColorScheme.of(context).readOnly.surface2,
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
        );
    }
  }
}

class _CheckedIcon extends StatelessWidget {
  const _CheckedIcon();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -4,
      right: -4,
      child: Container(
        decoration: BoxDecoration(
          color: ColorScheme.of(context).secondary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          SpIcons.check,
          color: ColorScheme.of(context).onSecondary,
          size: 16.0,
        ),
      ),
    );
  }
}
