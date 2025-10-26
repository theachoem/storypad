import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:storypad/core/databases/models/story_preferences_db_model.dart';
import 'package:storypad/core/objects/gallery_template_object.dart';
import 'package:storypad/core/objects/story_page_object.dart';
import 'package:storypad/core/types/app_product.dart';
import 'package:storypad/core/types/page_layout_type.dart';
import 'package:storypad/providers/in_app_purchase_provider.dart';
import 'package:storypad/views/add_ons/add_ons_view.dart';
import 'package:storypad/views/stories/local_widgets/story_pages_builder.dart';
import 'package:storypad/views/templates/local_widgets/template_note.dart';
import 'package:storypad/widgets/base_view/view_model_provider.dart';
import 'package:flutter/material.dart';
import 'package:storypad/widgets/base_view/base_route.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_pop_up_menu_button.dart';

import 'show_template_gallery_view_model.dart';

part 'show_template_gallery_content.dart';

class ShowTemplateGalleryRoute extends BaseRoute {
  ShowTemplateGalleryRoute({
    required this.galleryTemplate,
  });

  final GalleryTemplateObject galleryTemplate;

  @override
  Map<String, String?>? get analyticsParameters {
    return {
      'templateId': galleryTemplate.id,
    };
  }

  @override
  bool get fullscreenDialog => true;

  @override
  Widget buildPage(BuildContext context) => ShowTemplateGalleryView(params: this);
}

class ShowTemplateGalleryView extends StatelessWidget {
  const ShowTemplateGalleryView({
    super.key,
    required this.params,
  });

  final ShowTemplateGalleryRoute params;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<ShowTemplateGalleryViewModel>(
      create: (context) => ShowTemplateGalleryViewModel(params: params),
      builder: (context, viewModel, child) {
        return _ShowTemplateGalleryContent(viewModel);
      },
    );
  }
}
