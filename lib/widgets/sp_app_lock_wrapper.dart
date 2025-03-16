import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/providers/app_lock_provider.dart';

class SpAppLockWrapper extends StatelessWidget {
  const SpAppLockWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppLockProvider>(
      child: child,
      builder: (context, provider, child) {
        return Stack(
          children: [
            child!,
            Visibility(
              visible: provider.hasAppLock,
              child: _LockedBarrier(),
            )
          ],
        );
      },
    );
  }
}

class _LockedBarrier extends StatefulWidget {
  const _LockedBarrier();

  @override
  State<_LockedBarrier> createState() => _LockedBarrierState();
}

class _LockedBarrierState extends State<_LockedBarrier> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController animationController;

  bool authenticated = false;
  bool showBarrier = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    animationController = AnimationController(
      vsync: this,
      value: 1.0,
      duration: Durations.long1,
    );

    authenticate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        authenticated = false;
        break;
      case AppLifecycleState.resumed:
        await authenticate();
        break;
    }
  }

  Future<void> authenticate() async {
    await Future.microtask(() {});

    if (authenticated) return;
    if (animationController.value != 1) animationController.animateTo(1);
    if (showBarrier != true) setState(() => showBarrier = true);

    final context = this.context;
    if (!context.mounted) return;

    if (ModalRoute.of(context)?.isCurrent == true) {
      authenticated = await context.read<AppLockProvider>().authenticateIfHas(context);
      if (authenticated) {
        await animationController.reverse(from: 1.0);
        setState(() => showBarrier = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (showBarrier) buildBlurFilter(),
        if (showBarrier) buildUnlockButton(context),
      ],
    );
  }

  Widget buildBlurFilter() {
    return Positioned.fill(
      child: FadeTransition(
        opacity: animationController,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: ColorScheme.of(context).surface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget buildUnlockButton(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: MediaQuery.of(context).padding.bottom + 48,
      child: Center(
        child: FadeTransition(
          opacity: animationController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 4.0,
            children: [
              FilledButton.icon(
                icon: Icon(Icons.lock_outline),
                onPressed: () => authenticate(),
                label: Text(tr('button.unlock')),
              ),
              if (context.read<AppLockProvider>().appLock.pin != null)
                OutlinedButton.icon(
                  onPressed: () => context.read<AppLockProvider>().forgotPin(context),
                  label: Text(tr('button.forgot_pin')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
