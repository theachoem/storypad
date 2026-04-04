import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/services/windowed_detector_service.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/root_provider.dart';
import 'package:storypad/views/relax_sounds/relax_sounds_view.dart';
import 'package:storypad/widgets/sp_floating_music_note.dart';
import 'package:storypad/views/root/local_widgets/root_view_side_bar_info.dart';
import 'package:storypad/widgets/side_items/side_items.dart';
import 'package:storypad/widgets/sp_fade_in.dart';

class RootSideBar extends StatefulWidget {
  const RootSideBar({
    super.key,
    required this.rootProvider,
  });

  final RootProvider rootProvider;

  @override
  State<RootSideBar> createState() => _RootSideBarState();
}

class _RootSideBarState extends State<RootSideBar> {
  late final DevicePreferencesProvider devicePreferencesProvider = context.read<DevicePreferencesProvider>();

  @override
  void initState() {
    super.initState();
    widget.rootProvider.sideBarInfoNotifier.addListener(_listener);
    widget.rootProvider.selectedRootRouteNameNotifier.addListener(_listener);
    devicePreferencesProvider.addListenerForAddOnChanges(_listener);
  }

  @override
  void dispose() {
    devicePreferencesProvider.removeListenerForAddOnChanges(_listener);
    widget.rootProvider.sideBarInfoNotifier.removeListener(_listener);
    widget.rootProvider.selectedRootRouteNameNotifier.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    bool bigScreen = WindowedDetectorService.isBigWindow(context);

    final sideBarInfo = widget.rootProvider.sideBarInfoNotifier.value;
    final selectedRouteName = widget.rootProvider.selectedRootRouteNameNotifier.value;

    bool visible = bigScreen == true;
    if (sideBarInfo.temporaryHidden == true) visible = false;

    final List<IconButtonSideItem> sideItems = SideItems.getSideMenuItems(
      enableRelaxSounds: devicePreferencesProvider.enableRelaxSounds,
    );

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
