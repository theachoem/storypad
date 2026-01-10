import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/providers/root_provider.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

class SpSideBarTogglerButton extends StatelessWidget {
  const SpSideBarTogglerButton({
    super.key,
    required this.visibleOnSideBarShown,
  });

  final bool visibleOnSideBarShown;

  static Widget buildViewButton({
    required BuildContext viewContext,
    required bool open,
    double? right,
  }) {
    if (Platform.isMacOS) return const SizedBox.shrink();

    return ValueListenableBuilder(
      valueListenable: viewContext.read<RootProvider>().sideBarInfoNotifier,
      builder: (context, sideBarInfo, child) {
        bool bigScreen = sideBarInfo?.bigScreen ?? false;
        bool showSideBar = sideBarInfo?.showSideBar ?? false;

        // when bottom navigation is visible, we should use context for screen padding.
        // else if bottom nav is not visible, padding from context is 0, so we use view context for padding instead.
        var screenPadding = MediaQuery.paddingOf(context).bottom == 0
            ? MediaQuery.paddingOf(viewContext)
            : MediaQuery.paddingOf(context);

        return Visibility(
          visible: bigScreen && (open ? !showSideBar : showSideBar),
          child: Positioned(
            left: right != null ? null : screenPadding.left + (Platform.isMacOS ? 12.0 : 8.0),
            right: right,
            bottom: screenPadding.bottom + 12.0,
            child: open
                ? const SpSideBarTogglerButton(visibleOnSideBarShown: false)
                : const SpSideBarTogglerButton(visibleOnSideBarShown: true),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SpTapEffect(
      scaleActive: 1.2,
      effects: [.scaleDown],
      onTap: () {},
      child: _Button(
        icon: Icon(SpIcons.sideBarLeft),
        onPressed: () {
          final sideBarInfo = context.read<RootProvider>().sideBarInfoNotifier.value;
          if (sideBarInfo == null) return;

          context.read<RootProvider>().sideBarInfoNotifier.value = sideBarInfo.copyWith(
            showSideBar: !sideBarInfo.showSideBar,
            manuallyToggled: true,
          );
        },
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.icon,
    required this.onPressed,
  });

  final Widget icon;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return SpTapEffect(
      scaleActive: 1.2,
      effects: [.scaleDown],
      onTap: () {},
      child: IconButton.outlined(
        style: IconButton.styleFrom(
          side: BorderSide(color: Theme.of(context).dividerColor),
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
        icon: icon,
        onPressed: onPressed,
      ),
    );
  }
}
