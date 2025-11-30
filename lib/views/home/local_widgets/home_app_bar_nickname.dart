part of '../home_view.dart';

class _HomeAppBarNickname extends StatelessWidget {
  const _HomeAppBarNickname();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NicknameProvider>(context);

    return Text(
      tr(
        "page.home.app_bar.hello_nickname",
        namedArgs: {
          "NICKNAME": provider.nickname ?? "",
        },
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextTheme.of(context).titleLarge?.copyWith(color: ColorScheme.of(context).primary),
    );
  }
}
