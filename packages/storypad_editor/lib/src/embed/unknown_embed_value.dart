import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

part 'unknown_html_embed.dart';
part 'unknown_quill_embed.dart';

/// Content no registered embed understood, preserved losslessly so opening and saving a story never destroys it --
/// e.g. an embed added by a newer app version, or a malformed value an embed rejected.
@immutable
sealed class UnknownEmbedValue {
  const UnknownEmbedValue();
}
