import 'package:flutter/cupertino.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'dart:io';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/core/extensions/color_scheme_extension.dart';
import 'package:storypad/core/objects/relax_sound_object.dart';
import 'package:storypad/core/services/url_opener_service.dart';
import 'package:storypad/providers/relax_sounds_provider.dart';
import 'package:storypad/widgets/sp_animated_icon.dart';
import 'package:storypad/widgets/sp_firestore_storage_downloader_builder.dart';
import 'package:storypad/widgets/sp_floating_relax_sound_tile.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_loop_animation_builder.dart';
import 'package:storypad/widgets/sp_tap_effect.dart';
import 'relax_sounds_view_model.dart';

part 'local_widgets/volume_slider.dart';
part 'local_widgets/sound_icon_card.dart';
part 'local_widgets/license_text.dart';

part 'relax_sounds_content.dart';

class RelaxSoundsRoute extends BaseRoute {
  const RelaxSoundsRoute();

  @override
  bool get fullscreenDialog => true;

  @override
  Widget buildPage(BuildContext context) => RelaxSoundsView(params: this);
}

class RelaxSoundsView extends StatelessWidget {
  const RelaxSoundsView({
    super.key,
    required this.params,
  });

  final RelaxSoundsRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<RelaxSoundsViewModel>(
      create: (context) => RelaxSoundsViewModel(params: params),
      builder: (context, viewModel, child) {
        return _RelaxSoundsContent(viewModel);
      },
    );
  }
}
