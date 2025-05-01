part of '../home_view.dart';

class _HomeAppBarNickname extends StatelessWidget {
  const _HomeAppBarNickname({
    required this.nickname,
  });

  final String? nickname;

  @override
  Widget build(BuildContext context) {
    return Text(
      tr("page.home.app_bar.hello_nickname", namedArgs: {
        "NICKNAME": nickname ?? "",
      }),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextTheme.of(context).titleLarge?.copyWith(color: ColorScheme.of(context).primary),
    );
  }
}
