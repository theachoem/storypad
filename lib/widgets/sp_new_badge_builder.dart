import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/storages/new_badge_storage.dart';
import 'package:storypad/core/types/new_badge.dart';

class SpNewBadgeBuilder extends StatefulWidget {
  const SpNewBadgeBuilder({
    super.key,
    required this.badgeKey,
    required this.builder,
  });

  final String badgeKey;
  final Widget Function(BuildContext context, Widget? newBadge, void Function() hideBadge) builder;

  @override
  State<SpNewBadgeBuilder> createState() => _SpNewBadgeBuilderState();
}

class _SpNewBadgeBuilderState extends State<SpNewBadgeBuilder> {
  bool showNewBadge = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    await NewBadgeStorage().clicked(widget.badgeKey).then((clicked) {
      showNewBadge = !clicked;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, buildNewBadge(context), () async {
      await NewBadgeStorage().click(widget.badgeKey);
      await load();
    });
  }

  Widget? buildNewBadge(BuildContext context) {
    if (widget.badgeKey == NewBadge.none.name) return null;
    if (!showNewBadge) return null;

    return Material(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0),
        side: BorderSide(
          color: ColorScheme.of(context).bootstrap.info.color,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.textScalerOf(context).scale(6),
          vertical: MediaQuery.textScalerOf(context).scale(1),
        ),
        child: Text(
          tr('general.new'),
          style: TextTheme.of(context).labelMedium?.copyWith(color: ColorScheme.of(context).onSurface),
        ),
      ),
    );
  }
}
