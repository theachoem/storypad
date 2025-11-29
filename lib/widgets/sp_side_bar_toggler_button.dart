import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/views/root/root_view_model.dart';
import 'package:storypad/widgets/sp_icons.dart';

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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: context.read<RootViewModel>().sideBarInfoNotifier,
      builder: (context, sideBarInfo, child) {
        bool bigScreen = sideBarInfo?.bigScreen ?? false;
        bool showSideBar = sideBarInfo?.showSideBar ?? false;

        return Visibility(
          visible: bigScreen && (visibleOnSideBarShown ? showSideBar : !showSideBar),
          child: IconButton(
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
        );
      },
    );
  }
}
