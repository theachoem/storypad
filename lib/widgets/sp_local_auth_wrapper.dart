import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/services/local_auth_service.dart';
import 'package:storypad/providers/local_auth_provider.dart';

class SpLocalAuthWrapper extends StatelessWidget {
  const SpLocalAuthWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  static bool authenticated(BuildContext context) {
    return context.findAncestorStateOfType<_LockedState>()?.authenticated == true;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalAuthProvider>(
      child: child,
      builder: (context, provider, child) {
        if (provider.shouldShowLock) return _Locked(child: child!);
        return child!;
      },
    );
  }
}

class _Locked extends StatefulWidget {
  const _Locked({
    required this.child,
  });

  final Widget child;

  @override
  State<_Locked> createState() => _LockedState();
}

class _LockedState extends State<_Locked> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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

  // when native sheet close, it also trigger [resumed] which lead to loop calling [authenticate]
  // this variable is to ensure that if closed, no need to recall [authenticate]
  bool authenticatedSheetClosed = true;

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
        authenticatedSheetClosed = false;
        break;
      case AppLifecycleState.resumed:
        if (authenticatedSheetClosed) return;
        if (authenticated) return;
        if (animationController.value != 1) animationController.animateTo(1);
        if (showBarrier != true) setState(() => showBarrier = true);

        await authenticate();
        authenticatedSheetClosed = true;

        break;
    }
  }

  Future<void> authenticate() async {
    try {
      authenticated = await LocalAuthService.instance.authenticate();
    } catch (e) {
      debugPrint("👤 Authenticate local auth failed: $e");
    }

    if (authenticated) {
      await animationController.reverse(from: 1.0);
      setState(() => showBarrier = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
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
            color: Colors.black.withValues(alpha: 0.2),
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
          child: FilledButton.icon(
            onPressed: () => authenticate(),
            label: const Text("Unlock"),
          ),
        ),
      ),
    );
  }
}
