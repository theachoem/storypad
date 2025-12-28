import 'dart:async';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/providers/app_lock_provider.dart';
import 'package:storypad/widgets/sp_icons.dart';

class SpAppLockWrapper extends StatelessWidget {
  const SpAppLockWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  static final GlobalKey<_LockedBarrierState> _globalKey = GlobalKey<_LockedBarrierState>();

  static bool authenticated(BuildContext context) =>
      context.read<AppLockProvider>().hasAppLock ? _globalKey.currentState?.authenticated == true : true;

  static Future<T> disableAppLockIfHas<T>(
    BuildContext context, {
    required FutureOr<T> Function() callback,
  }) async {
    if (_globalKey.currentState == null) return callback();
    return _globalKey.currentState!.disableAppLockIfHas(context, callback: callback);
  }

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
              child: _LockedBarrier(key: _globalKey),
            ),
          ],
        );
      },
    );
  }
}

class _LockedBarrier extends StatefulWidget {
  const _LockedBarrier({
    super.key,
  });

  @override
  State<_LockedBarrier> createState() => _LockedBarrierState();
}

class _LockedBarrierState extends State<_LockedBarrier> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController animationController;

  bool authenticated = false;
  bool barrierShown = true;
  bool listenToLifeCycle = true;

  Timer? _reEnableLifeCycleTimer;

  Future<T> disableAppLockIfHas<T>(
    BuildContext context, {
    required FutureOr<T> Function() callback,
  }) async {
    _reEnableLifeCycleTimer?.cancel();
    listenToLifeCycle = false;

    // Re-enable life cycle listening after some time to avoid app lock being disabled forever
    // if the callback forgets to re-enable it.
    _reEnableLifeCycleTimer = Timer(const Duration(minutes: 3), () {
      listenToLifeCycle = true;
    });

    final result = await callback();

    _reEnableLifeCycleTimer?.cancel();
    _reEnableLifeCycleTimer = null;
    listenToLifeCycle = true;

    return result;
  }

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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        if (listenToLifeCycle) {
          authenticated = false;
          showBarrierIfNot();
        }
        break;
      case AppLifecycleState.resumed:
        // There are cases when the user has already canceled authentication, but the app resumes and may call authenticate() again.
        // This check ensures we only re-authenticate when this route is not the current one, avoiding potential authentication loops.
        if (listenToLifeCycle && ModalRoute.of(context) != null && ModalRoute.of(context)?.isCurrent == false) {
          authenticate();
        }
        break;
    }
  }

  Future<void> showBarrierIfNot() async {
    if (animationController.value != 1) animationController.animateTo(1);
    if (!barrierShown) setState(() => barrierShown = true);
  }

  Future<void> authenticate() async {
    await Future.microtask(() {});

    if (authenticated) return;
    showBarrierIfNot();

    final context = this.context;
    if (!context.mounted) return;

    if (ModalRoute.of(context)?.isCurrent == true) {
      authenticated = await context.read<AppLockProvider>().authenticateIfHas(
        context: context,
        debugSource: '$runtimeType#authenticate',
      );
      if (authenticated) {
        await animationController.reverse(from: 1.0);
        setState(() => barrierShown = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (barrierShown) buildBlurFilter(),
        if (barrierShown) buildActionButtons(context),
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

  Widget buildActionButtons(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: MediaQuery.of(context).padding.bottom + 48,
      child: Center(
        child: FadeTransition(
          opacity: animationController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: kIsCupertino ? 8.0 : 4.0,
            children: [
              buildUnlockButtons(),
              if (context.read<AppLockProvider>().appLock.pin != null) buildForgotPinButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildForgotPinButton(BuildContext context) {
    if (kIsCupertino) {
      return CupertinoButton.tinted(
        sizeStyle: CupertinoButtonSize.medium,
        onPressed: () => context.read<AppLockProvider>().forgotPin(context),
        child: Text(tr('button.forgot_pin')),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: () => context.read<AppLockProvider>().forgotPin(context),
        label: Text(tr('button.forgot_pin')),
      );
    }
  }

  Widget buildUnlockButtons() {
    if (kIsCupertino) {
      return CupertinoButton.filled(
        sizeStyle: CupertinoButtonSize.medium,
        onPressed: () => authenticate(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8.0,
          children: [
            const Icon(SpIcons.lock),
            Text(tr('button.unlock')),
          ],
        ),
      );
    } else {
      return FilledButton.icon(
        icon: const Icon(SpIcons.lock),
        onPressed: () => authenticate(),
        label: Text(tr('button.unlock')),
      );
    }
  }
}
