import 'package:storypad/core/databases/models/relex_sound_mix_model.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_text_inputs_page.dart';

class EditMixRoute extends BaseRoute {
  const EditMixRoute({
    required this.mix,
  });

  final RelaxSoundMixModel mix;

  @override
  Widget buildPage(BuildContext context) => EditMixView(params: this);
}

class EditMixView extends StatelessWidget {
  const EditMixView({
    super.key,
    required this.params,
  });

  final EditMixRoute params;

  @override
  Widget build(BuildContext context) {
    return SpTextInputsPage(
      appBar: AppBar(),
      fields: [
        SpTextInputField(
          initialText: params.mix.name,
          hintText: '...',
        ),
      ],
    );
  }
}
