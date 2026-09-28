import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/rich_text/storypad_editor/embeds/audio_embed.dart';
import 'package:storypad/core/rich_text/storypad_editor/embeds/date_embed.dart';
import 'package:storypad/core/rich_text/storypad_editor/embeds/media_embed.dart';
import 'package:storypad_editor/storypad_editor.dart';

/// Every embed a story can hold, for the editor and for headless conversion alike.
const storyPadEmbeds = <StoryEmbed>[MediaEmbed(), AudioEmbed(), DateEmbed()];

/// Converts stories between Quill (how they're stored) and Markdown (how they're edited), with [storyPadEmbeds].
final storyPadCodec = StoryCodec(embeds: storyPadEmbeds);

/// Content no embed understood (e.g. from a newer app version), kept as-is and shown as "Unknown".
Widget buildStoryPadUnknownEmbed(BuildContext context, StoryEmbedContext<UnknownEmbedValue> embed) {
  return Text(tr("general.unknown"));
}
