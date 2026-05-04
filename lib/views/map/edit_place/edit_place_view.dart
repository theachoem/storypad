import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/databases/models/place_db_model.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_section_title.dart';

import 'edit_place_view_model.dart';

part 'edit_place_content.dart';

class EditPlaceRoute extends BaseRoute {
  const EditPlaceRoute({
    required this.place,
  });

  final PlaceDbModel place;

  @override
  Widget buildPage(BuildContext context) => EditPlaceView(params: this);
}

class EditPlaceView extends StatelessWidget {
  const EditPlaceView({
    super.key,
    required this.params,
  });

  final EditPlaceRoute params;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditPlaceViewModel>(
      create: (context) => EditPlaceViewModel(params: params),
      builder: (context, child) {
        return _EditPlaceContent(Provider.of(context));
      },
    );
  }
}
