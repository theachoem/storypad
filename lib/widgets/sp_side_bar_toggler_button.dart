import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/views/root/root_view_model.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';

class SpSideBarTogglerButton extends StatelessWidget {
  const SpSideBarTogglerButton({
    super.key,
    required this.visibleOnSideBarShown,
  });

  final bool visibleOnSideBarShown;

  factory SpSideBarTogglerButton.open() {
    return const SpSideBarTogglerButton(visibleOnSideBarShown: false);
  }

  factory SpSideBarTogglerButton.close() {
    return const SpSideBarTogglerButton(visibleOnSideBarShown: true);
  }

  static Widget buildViewButton({
    required BuildContext viewContext,
    required bool open,
    double? right,
  }) {
    return Builder(
      builder: (context) {
        // when bottom navigation is visible, we should use context for screen padding.
        // else if bottom nav is not visible, padding from context is 0, so we use view context for padding instead.
        var screenPadding = MediaQuery.paddingOf(context).bottom == 0
            ? MediaQuery.paddingOf(viewContext)
            : MediaQuery.paddingOf(context);

        return Positioned(
          left: right != null ? null : screenPadding.left + (Platform.isMacOS ? 12.0 : 8.0),
          right: right,
          bottom: screenPadding.bottom + 12.0,
          child: open ? SpSideBarTogglerButton.open() : SpSideBarTogglerButton.close(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: context.read<RootViewModel>().sideBarInfoNotifier,
      builder: (context, sideBarInfo, child) {
        bool bigScreen = sideBarInfo?.bigScreen ?? false;
        bool showSideBar = sideBarInfo?.showSideBar ?? false;

        return Visibility(
          visible: bigScreen && (visibleOnSideBarShown ? showSideBar : !showSideBar),
          child: SpTapEffect(
            scaleActive: 1.2,
            effects: [.scaleDown],
            onTap: () {},
            child: IconButton.outlined(
              style: IconButton.styleFrom(
                side: BorderSide(color: Theme.of(context).dividerColor),
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              icon: Icon(SpIcons.sideBarLeft),
              onPressed: () {
                if (context.read<RootViewModel>().sideBarInfoNotifier.value == null) return;
                context.read<RootViewModel>().sideBarInfoNotifier.value = context
                    .read<RootViewModel>()
                    .sideBarInfoNotifier
                    .value!
                    .copyWith(showSideBar: !showSideBar, manuallyToggled: true);
              },
            ),
          ),
        );
      },
    );
  }
}
