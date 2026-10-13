import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/story_editor/embeds/audio_embed.dart';
import 'package:storypad/core/story_editor/embeds/date_embed.dart';
import 'package:storypad/core/story_editor/embeds/media_embed.dart';
import 'package:storypad_editor/storypad_editor.dart';

/// Every embed a story can hold, for the editor and for headless conversion alike.
const storyPadEmbeds = <StoryEmbed>[MediaEmbed(), AudioEmbed(), DateEmbed()];

/// Reads and writes story pages as Markdown (how they're stored and edited), and converts pages stored as Quill before
/// Markdown, with [storyPadEmbeds].
final storyPadCodec = StoryCodec(embeds: storyPadEmbeds);

/// Content no embed understood (e.g. from a newer app version), kept as-is and shown as "Unknown".
Widget buildStoryPadUnknownEmbed(BuildContext context, StoryEmbedContext<UnknownEmbedValue> embed) {
  return Text(tr("general.unknown"));
}
