import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';

class SpMultiEditBottomNavBar extends StatelessWidget {
  const SpMultiEditBottomNavBar({
    super.key,
    required this.editing,
    required this.onCancel,
    required this.buttons,
  });

  final bool editing;
  final List<Widget> buttons;
  final void Function() onCancel;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: editing,
      child: SpFadeIn.fromBottom(
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          padding: EdgeInsets.only(
            left: MediaQuery.of(context).padding.left,
            right: MediaQuery.of(context).padding.right,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(height: 1),
              Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ).add(EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom, left: 48.0)),
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(mainAxisAlignment: MainAxisAlignment.end, spacing: 8.0, children: buttons),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 48 / 2 + 8,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 8,
                    bottom: MediaQuery.of(context).padding.bottom,
                    child: Center(
                      child: IconButton.filledTonal(
                        tooltip: tr("button.cancel"),
                        icon: const Icon(SpIcons.clear),
                        onPressed: () => onCancel(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
