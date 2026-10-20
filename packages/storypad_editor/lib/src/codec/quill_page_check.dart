import '../quill/quill_import_loss.dart';
import 'story_codec.dart';

/// The result of [StoryCodec.checkQuillPage]: whether a Quill page converts to Markdown without losing anything.
final class QuillPageCheck {
  const QuillPageCheck({required this.losses, required this.titleRoundTrips, required this.bodyRoundTrips});

  /// Formatting the conversion drops (see [StoryCodec.quillImportLosses]).
  final List<QuillImportLoss> losses;

  /// Whether the Markdown's leading heading reads back as exactly the page's title. Always true without a title (a
  /// leading heading in the body then becomes the title, see [StoryCodec.checkQuillPage]).
  final bool titleRoundTrips;

  /// Whether the Markdown's body, written back as Quill, is equivalent to the original ops. `false` when the title
  /// didn't round-trip (the body can't be told apart then).
  final bool bodyRoundTrips;

  /// Whether the Markdown may replace the stored Quill: no losses, and both title and body round-trip.
  bool get isLossless => losses.isEmpty && titleRoundTrips && bodyRoundTrips;

  @override
  String toString() =>
      'QuillPageCheck(losses: ${losses.length}, titleRoundTrips: $titleRoundTrips, bodyRoundTrips: $bodyRoundTrips)';
}
