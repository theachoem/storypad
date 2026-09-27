import 'package:storypad_editor/storypad_editor.dart';

import 'audio_embed.dart';
import 'date_embed.dart';
import 'media_embed.dart';

export 'audio_embed.dart';
export 'date_embed.dart';
export 'embed_attributes.dart';
export 'media_embed.dart';

/// Every embed the example app registers, as StoryPad's app would.
const demoEmbeds = <StoryEmbed>[MediaEmbed(), AudioEmbed(), DateEmbed()];
