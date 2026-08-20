import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/services/assets/video_compression_progress.dart';

import 'video_compression_view.dart';

class VideoCompressionViewModel extends ChangeNotifier with DisposeAwareMixin {
  final VideoCompressionRoute params;

  VideoCompressionViewModel({required this.params}) {
    progress.addListener(notifyListeners);
  }

  /// Lives in `core/` and is shared with the pick loop, so this view model
  /// reads it rather than owning it -- and must not dispose it.
  VideoCompressionProgress get progress => params.progress;

  /// The encoder reports nothing until it actually starts, so the bar stays
  /// indeterminate rather than sitting at a dead 0%.
  bool get started => progress.fraction > 0;

  double get value => progress.overallFraction;

  bool get cancelled => progress.cancelled;

  void cancel() => progress.cancel();

  /// "Video 2 of 3" only earns its place in a batch; a single pick says the
  /// plain message instead.
  String get message {
    if (progress.total <= 1 || progress.current == 0) return tr('page.video_compression.message');

    return tr(
      'page.video_compression.progress_args',
      namedArgs: {'SP_CURRENT': '${progress.current}', 'SP_TOTAL': '${progress.total}'},
    );
  }

  String get statusLabel {
    if (!started) return tr('page.video_compression.please_wait');
    return '${(value * 100).round()}%';
  }

  @override
  void dispose() {
    progress.removeListener(notifyListeners);
    super.dispose();
  }
}
