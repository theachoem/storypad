import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/services/assets/video_compression_progress.dart';
import 'package:storypad/core/services/logger/app_logger.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';

import 'video_compression_view_model.dart';

part 'video_compression_content.dart';

/// Full-screen progress shown while picked videos are re-encoded.
///
/// Video compression targets 1080p, which takes real seconds on a long clip --
/// long enough that a bare spinner reads as a hang, and long enough that the
/// user deserves a way out.
///
/// Unlike every other [BaseRoute] in the app, this one is never navigated to by
/// the user: [run] owns its whole lifetime. That's why it overrides
/// [buildRoute] and is pushed by hand rather than through [BaseRoute.push] --
/// see the notes on each below before reaching for the inherited helpers.
class VideoCompressionRoute extends BaseRoute {
  const VideoCompressionRoute({
    required this.progress,
  });

  /// Created by [run] *before* the route, because the pick loop writes to it
  /// too -- it belongs to the compression pipeline, not to this screen.
  final VideoCompressionProgress progress;

  /// How long [run] waits before putting the screen up. Most picks are skipped
  /// by `VideoCompressionService`'s within-target pre-check and come back in
  /// milliseconds -- showing a full screen for those would be a flash of chrome
  /// for nothing.
  static const Duration _gracePeriod = Duration(milliseconds: 400);

  /// Runs [task] behind this screen and takes the screen down again exactly
  /// once, whatever [task] does. Nothing is shown at all if [task] settles
  /// within [_gracePeriod].
  ///
  /// The route is pushed and removed **by reference**, never popped, and
  /// deliberately not through [BaseRoute.push]: `push` returns the page's
  /// result rather than the route, and popping removes whatever happens to be
  /// on top. That's how a stale callback can take the app's real route with it
  /// and leave a black screen -- and this route sits on the root navigator,
  /// whose whole stack is the single `RootView` route, so there is nothing to
  /// spare there. Going direct also skips `push`'s `logViewRoute`, which is
  /// right: a progress cover is not a screen the user visited.
  ///
  /// Never throws: a failed re-encode has to degrade into "keep what the user
  /// picked", so [task] failing returns `null` and the caller falls back.
  static Future<T?> run<T>(
    BuildContext context, {
    required int totalVideos,
    required Future<T> Function(VideoCompressionProgress progress) task,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final progress = VideoCompressionProgress(total: totalVideos);
    final pageRoute = VideoCompressionRoute(progress: progress).buildRoute<void>(context);

    T? value;
    Object? error;
    StackTrace? stackTrace;
    bool settled = false;

    // Swallowing the outcome here rather than letting it propagate keeps the
    // grace-period race below from ever leaving an unhandled async error.
    final work = () async {
      try {
        value = await task(progress);
      } catch (e, s) {
        error = e;
        stackTrace = s;
      } finally {
        settled = true;
      }
    }();

    // A cancellable timer rather than a bare `Future.delayed`, so a task that
    // wins the race doesn't leave a timer ticking behind it.
    final grace = Completer<void>();
    final graceTimer = Timer(_gracePeriod, () {
      if (!grace.isCompleted) grace.complete();
    });

    await Future.any([work, grace.future]);
    graceTimer.cancel();

    if (!settled) {
      navigator.push(pageRoute);
      await work;
      if (pageRoute.isActive) navigator.removeRoute(pageRoute);
    }

    progress.dispose();

    if (error != null) {
      AppLogger.error('VideoCompressionRoute#run error: $error', stackTrace: stackTrace);
      return null;
    }

    return value;
  }

  /// Always the same non-dismissible fade, never the inherited
  /// `CupertinoSheetRoute`/`MaterialPageRoute` pair. Video picking is usually
  /// launched from a sheet, and the Cupertino branch would hand the user a
  /// swipe-to-dismiss gesture on a screen whose route [run] alone may remove.
  @override
  PageRoute<T> buildRoute<T>(BuildContext context) {
    return PageRouteBuilder<T>(
      barrierDismissible: false,
      transitionDuration: Durations.short4,
      reverseTransitionDuration: Durations.short4,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      pageBuilder: (context, animation, secondaryAnimation) => buildPage(context),
    );
  }

  @override
  Widget buildPage(BuildContext context) => VideoCompressionView(params: this);
}

class VideoCompressionView extends StatelessWidget {
  const VideoCompressionView({
    super.key,
    required this.params,
  });

  final VideoCompressionRoute params;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VideoCompressionViewModel>(
      create: (context) => VideoCompressionViewModel(params: params),
      builder: (context, child) => _VideoCompressionContent(Provider.of(context)),
    );
  }
}
