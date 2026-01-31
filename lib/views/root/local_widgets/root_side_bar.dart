import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/services/windowed_detector_service.dart';
import 'package:storypad/providers/root_provider.dart';
import 'package:storypad/views/relax_sounds/relax_sounds_view.dart';
import 'package:storypad/widgets/sp_floating_music_note.dart';
import 'package:storypad/views/root/local_widgets/root_view_side_bar_info.dart';
import 'package:storypad/widgets/side_items/side_items.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_two_value_listenable_builder.dart';

class RootSideBar extends StatelessWidget {
  const RootSideBar({
    super.key,
    required this.rootProvider,
    required this.sideItems,
  });

  final RootProvider rootProvider;
  final List<IconButtonSideItem> sideItems;

  @override
  Widget build(BuildContext context) {
    bool bigScreen = WindowedDetectorService.isBigWindow(context);

    return SpTwoValueListenableBuilder(
      valueListenable1: rootProvider.sideBarInfoNotifier,
      valueListenable2: rootProvider.selectedRootRouteNameNotifier,
      builder: (context, sideBarInfo, selectedRouteName, child) {
        bool visible = bigScreen == true;

        if (sideBarInfo.temporaryHidden == true) {
          visible = false;
        }

        return Visibility(
          visible: visible,
          child: SpFadeIn.fromLeft(
            duration: Durations.long1,
            child: SizedBox(
              width: 72,
              child: Column(
                mainAxisAlignment: .center,
                spacing: 12.0,
                children: sideItems.map((item) {
                  return _SideBarItem(
                    item: item,
                    selectedRouteName: selectedRouteName,
                    sideBarInfo: sideBarInfo,
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SideBarItem extends StatelessWidget {
  const _SideBarItem({
    required this.item,
    required this.selectedRouteName,
    required this.sideBarInfo,
  });

  final IconButtonSideItem item;
  final String selectedRouteName;
  final RootViewSideBarInfo? sideBarInfo;

  @override
  Widget build(BuildContext context) {
    bool isSelected = selectedRouteName == item.route.routeName;

    Color? backgroundColor;
    Color? foregroundColor;

    if (sideBarInfo?.colorScheme != null) {
      backgroundColor = Colors.transparent;
      foregroundColor = isSelected ? sideBarInfo!.colorScheme?.primary : sideBarInfo!.colorScheme?.onSurface;
    } else {
      backgroundColor = isSelected ? ColorScheme.of(context).readOnly.surface2 : Colors.transparent;
      foregroundColor = isSelected
          ? ColorScheme.of(context).primary
          : ColorScheme.of(context).onSurface.withValues(alpha: 0.7);
    }

    Widget child = IconButton(
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      ),
      isSelected: isSelected,
      onPressed: item.onTap != null ? () => item.onTap!(context, item.route) : null,
      tooltip: item.title,
      icon: Icon(item.iconData),
      selectedIcon: Icon(item.selectedIconData),
    );

    if (item.route is RelaxSoundsRoute) {
      return SpFloatingMusicNote.wrapIfPlaying(child: child);
    }

    return child;
  }
}
