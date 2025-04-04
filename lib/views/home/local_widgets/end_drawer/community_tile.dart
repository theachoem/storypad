part of 'home_end_drawer.dart';

class _CommunityTile extends StatelessWidget {
  const _CommunityTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(SpIcons.forum),
      title: RichText(
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyLarge,
          text: "${tr("page.community.title")} ",
          children: [
            // WidgetSpan(
            //   child: Material(
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(4.0),
            //       side: BorderSide(
            //         color: ColorScheme.of(context).bootstrap.info.color,
            //       ),
            //     ),
            //     child: Padding(
            //       padding: EdgeInsets.symmetric(
            //         horizontal: MediaQuery.textScalerOf(context).scale(6),
            //         vertical: MediaQuery.textScalerOf(context).scale(1),
            //       ),
            //       child: Text(
            //         tr('general.new'),
            //         style: TextTheme.of(context).labelMedium?.copyWith(color: ColorScheme.of(context).onSurface),
            //       ),
            //     ),
            //   ),
            // )
          ],
        ),
      ),
      onTap: () async {
        CommunityRoute().push(context);
      },
    );
  }
}
