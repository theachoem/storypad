import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/rich_editor/embeds/sp_audio_embed.dart';
import 'package:storypad/widgets/rich_editor/embeds/sp_date_embed.dart';
import 'package:storypad/widgets/rich_editor/embeds/sp_media_embed.dart';
import 'package:storypad_editor/storypad_editor.dart';

class SpEmbeds {
  SpEmbeds._();

  /// Every embed a story can hold, for the editor and for headless conversion alike.
  static const all = <StoryEmbed>[SpMediaEmbed(), SpAudioEmbed(), SpDateEmbed()];

  /// Reads and writes story pages as Markdown (how they're stored and edited), and converts pages stored as Quill
  /// before Markdown, with [all].
  static final codec = StoryCodec(embeds: all);

  /// Content no embed understood (e.g. from a newer app version), kept as-is and shown as "Unknown".
  static Widget buildUnknown(BuildContext context, StoryEmbedContext<UnknownEmbedValue> embed) {
    return Text(tr("general.unknown"));
  }
}
