part of '../home_view.dart';

class _HomeAppBarNickname extends StatefulWidget {
  const _HomeAppBarNickname({
    required this.nickname,
  });

  final String? nickname;

  @override
  State<_HomeAppBarNickname> createState() => _HomeAppBarNicknameState();
}

class _HomeAppBarNicknameState extends State<_HomeAppBarNickname> with SingleTickerProviderStateMixin {
  late final AnimationController animationController;

  bool visible = false;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      value: 0.0,
      duration: Durations.long1,
    );
  }

  @override
  void didUpdateWidget(covariant _HomeAppBarNickname oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.nickname != widget.nickname) {
      checkName();
    }
  }

  void checkName() async {
    setState(() => visible = true);

    await animationController.animateTo(1);
    await Future.delayed(const Duration(seconds: 1));
    await animationController.animateTo(0);

    if (mounted) setState(() => visible = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          tr("page.home.app_bar.hello_nickname", namedArgs: {
            "NICKNAME": widget.nickname ?? "",
          }),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextTheme.of(context).titleLarge?.copyWith(color: ColorScheme.of(context).primary),
        ),
        if (visible)
          Positioned.fill(
            child: FadeTransition(
              opacity: animationController,
              child: Container(
                alignment: Alignment.centerRight,
                transform: Matrix4.identity()
                  ..scale(5.0)
                  ..translate(-24.0, 0.0),
                transformAlignment: Alignment.center,
                child: const SpDotLottieBuilder(
                  asset: 'assets/lotties/sparkle.lottie',
                ),
              ),
            ),
          )
      ],
    );
  }
}
