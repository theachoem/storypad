import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/views/community/community_view.dart';

class CommunityTile extends StatelessWidget {
  const CommunityTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.forum_outlined),
      title: RichText(
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyLarge,
          text: "${tr("page.community.title")} ",
          children: [
            WidgetSpan(
              child: Material(
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
              ),
            )
          ],
        ),
      ),
      onTap: () async {
        CommunityRoute().push(context);
      },
    );
  }
}
