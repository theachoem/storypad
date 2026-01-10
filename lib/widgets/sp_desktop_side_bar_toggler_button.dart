import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/providers/device_preferences_provider.dart';
import 'package:storypad/providers/root_provider.dart';
import 'package:storypad/widgets/sp_animated_icon.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';
import 'package:storypad/widgets/sp_theme_mode_icon.dart';

class SpDesktopSideBarTogglerButton extends StatefulWidget {
  const SpDesktopSideBarTogglerButton({
    super.key,
  });

  @override
  State<SpDesktopSideBarTogglerButton> createState() => _SpDesktopSideBarTogglerButtonState();
}

class _SpDesktopSideBarTogglerButtonState extends State<SpDesktopSideBarTogglerButton> {
  double macMenuWidth = 80;
  double sideBarWidth = 260;
  double get buttonsWidth => 32.0 * buttonsItems.length;

  List<_ButtonItem> get buttonsItems => [
    _ButtonItem(
      visibleOnSideBarClosed: false,
      icon: ValueListenableBuilder(
        valueListenable: context.read<RootProvider>().sideBarInfoNotifier,
        builder: (context, sideBarInfo, child) {
          return SpAnimatedIcons.fadeScale(
            showFirst: sideBarInfo?.optionsExpanded == true,
            firstChild: Icon(
              SpIcons.clear,
              size: 20,
              color: ColorScheme.of(context).onSurface.withValues(alpha: 0.5),
            ),
            secondChild: Icon(
              SpIcons.moreVert,
              size: 20,
              color: ColorScheme.of(context).onSurface.withValues(alpha: 0.5),
            ),
          );
        },
      ),
      onTap: () {
        final notifier = context.read<RootProvider>().sideBarInfoNotifier;
        notifier.value = notifier.value?.copyWith(optionsExpanded: !(notifier.value?.optionsExpanded ?? false));
      },
    ),
    _ButtonItem(
      visibleOnSideBarClosed: false,
      icon: SpThemeModeIcon(
        parentContext: context,
        iconSize: 20,
        color: ColorScheme.of(context).onSurface.withValues(alpha: 0.5),
      ),
      onTap: () => context.read<DevicePreferencesProvider>().toggleThemeMode(context),
    ),
    _ButtonItem(
      visibleOnSideBarClosed: true,
      icon: Icon(
        SpIcons.sideBarLeft,
        size: 20,
        color: ColorScheme.of(context).onSurface.withValues(alpha: 0.5),
      ),
      onTap: () {
        final sideBarInfo = context.read<RootProvider>().sideBarInfoNotifier.value;
        if (sideBarInfo == null) return;

        context.read<RootProvider>().sideBarInfoNotifier.value = sideBarInfo.copyWith(
          showSideBar: !sideBarInfo.showSideBar,
          optionsExpanded: false, // reset expanded to original state when toggling sidebar
          manuallyToggled: true,
        );
      },
    ),
  ];

  // 260 - 120 - 32 = 108
  // (-4 for small padding)
  double get marginFromMenuToButtons => (sideBarWidth - macMenuWidth) - buttonsWidth - 4;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 80,
      top: 0,
      child: ValueListenableBuilder(
        valueListenable: context.read<RootProvider>().sideBarInfoNotifier,
        builder: (context, sideBarInfo, button) {
          final bool bigScreen = sideBarInfo?.bigScreen ?? false;

          return Visibility(
            visible: bigScreen,
            child: SpFadeIn(
              // Add delay for a nice transition when resizing screen which 1 of side bar button / end drawer button
              // will appear with transition. see [_HomeTabBar#buildOpenEndDrawerButton]
              delay: Durations.long2,
              child: AnimatedContainer(
                duration: Durations.medium1,
                curve: Curves.easeInOut,
                margin: EdgeInsets.only(
                  left: sideBarInfo?.showSideBar == true ? marginFromMenuToButtons : 0.0,
                ),
                child: Row(
                  children: buttonsItems.map((button) {
                    if (button.visibleOnSideBarClosed) {
                      return _Button(
                        icon: button.icon,
                        onTap: button.onTap,
                      );
                    } else {
                      return Visibility(
                        visible: sideBarInfo?.showSideBar == true,
                        child: _Button(
                          icon: button.icon,
                          onTap: button.onTap,
                        ),
                      );
                    }
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ButtonItem {
  _ButtonItem({
    required this.icon,
    required this.onTap,
    required this.visibleOnSideBarClosed,
  });

  final Widget icon;
  final VoidCallback onTap;
  final bool visibleOnSideBarClosed;
}

class _Button extends StatelessWidget {
  const _Button({
    required this.icon,
    required this.onTap,
  });

  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SpTapEffect(
      onTap: onTap,
      effects: [.border],
      borderOption: SpTapEffectBorderOption(
        shape: BoxShape.circle,
        scale: 1.0,
        width: 1.0,
        color: Theme.of(context).dividerColor,
      ),
      child: Container(
        height: 32,
        width: 32,
        alignment: .center,
        child: icon,
      ),
    );
  }
}
