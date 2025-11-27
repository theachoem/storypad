part of '../home_view.dart';

class _HomeFloatingButtons extends StatefulWidget {
  const _HomeFloatingButtons({
    required this.viewModel,
  });

  final HomeViewModel viewModel;

  @override
  State<_HomeFloatingButtons> createState() => _HomeFloatingButtonsState();
}

class _HomeFloatingButtonsState extends State<_HomeFloatingButtons> with SingleTickerProviderStateMixin {
  late final AnimationController animationController = AnimationController(vsync: this, duration: Durations.medium2);
  late Animation<double> animation = animationController.drive(CurveTween(curve: Curves.ease));

  OverlayEntry? floating;

  Future<void> toggle(BuildContext context) async {
    if (!mounted) return;
    if (animationController.isAnimating) return;

    if (animationController.isCompleted) {
      await animationController.reverse();

      floating?.remove();
      floating = null;
    } else {
      floating = createFloating(context);
      Overlay.maybeOf(context)?.insert(floating!);
      await animationController.forward();
    }
  }

  OverlayEntry createFloating(BuildContext buttons) {
    return OverlayEntry(
      builder: (context) => buildExpandedScaffold(context),
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    if (animationController.isCompleted) floating?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.0).animate(animation),
      child: buildButton(context),
    );
  }

  Widget buildButton(BuildContext context) {
    if (MediaQuery.accessibleNavigationOf(context)) {
      return FloatingActionButton.extended(
        tooltip: tr("button.new_story"),
        onPressed: () => toggle(context),
        label: Text(tr("button.new_story")),
        icon: const Icon(SpIcons.newStory),
        shape: const StadiumBorder(),
      );
    } else {
      return FloatingActionButton(
        tooltip: tr("button.new_story"),
        onPressed: () => toggle(context),
        child: const Icon(SpIcons.newStory),
      );
    }
  }

  Widget buildExpandedScaffold(BuildContext context) {
    List<IconButton> buttons = [
      IconButton.filled(
        tooltip: tr("button.new_story"),
        visualDensity: const VisualDensity(horizontal: 2, vertical: 2),
        icon: const Icon(SpIcons.add),
        onPressed: () {
          toggle(context);
          widget.viewModel.goToNewPage(context);
        },
      ),
      if (kStoryPad)
        IconButton.outlined(
          tooltip: tr("button.take_photo"),
          visualDensity: const VisualDensity(horizontal: 1.5, vertical: 1.5),
          icon: const Icon(SpIcons.camera),
          color: Colors.white,
          onPressed: () {
            toggle(context);
            widget.viewModel.takePhoto(context);
          },
        ),
      if (kIAPEnabled)
        IconButton.outlined(
          tooltip: tr("add_ons.templates.title"),
          visualDensity: const VisualDensity(horizontal: 1, vertical: 1),
          icon: const Icon(SpIcons.lightBulb, color: Colors.yellow),
          color: Colors.white,
          onPressed: () {
            toggle(context);
            widget.viewModel.goToTemplatePage(context);
          },
        ),
    ];

    return GestureDetector(
      onTap: () => toggle(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withValues(alpha: lerpDouble(0.0, 0.75, animation.value)),
            );
          },
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16.0,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ...List.generate(buttons.length, (index) {
              final button = buttons[index];

              return FadeScaleTransition(
                animation: animation,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 8.0,
                  children: [
                    Text(button.tooltip!, style: TextTheme.of(context).labelLarge?.copyWith(color: Colors.white)),
                    Padding(
                      padding: button.visualDensity?.horizontal != null
                          ? EdgeInsets.only(right: button.visualDensity!.horizontal)
                          : EdgeInsets.zero,
                      child: button,
                    ),
                  ],
                ),
              );
            }),
            FadeScaleTransition(
              animation: animation,
              child: FloatingActionButton(
                tooltip: tr("button.cancel"),
                backgroundColor: Colors.grey.shade900,
                foregroundColor: Colors.white,
                child: SpFadeIn.bound(
                  duration: Durations.medium1,
                  child: const Icon(SpIcons.clear),
                ),
                onPressed: () => toggle(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
