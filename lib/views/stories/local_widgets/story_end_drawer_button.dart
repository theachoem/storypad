import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/sp_icons.dart';

class StoryEndDrawerButton extends StatelessWidget {
  const StoryEndDrawerButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: "page.tags.title",
      child: IconButton(
        color: Theme.of(context).appBarTheme.foregroundColor,
        tooltip: tr("page.tags.title"),
        icon: const Icon(SpIcons.tag),
        onPressed: () => Scaffold.of(context).openEndDrawer(),
      ),
    );
  }
}
