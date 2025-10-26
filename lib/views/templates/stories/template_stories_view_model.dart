import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/types/path_type.dart';
import 'template_stories_view.dart';

class TemplateStoriesViewModel extends ChangeNotifier with DisposeAwareMixin {
  final TemplateStoriesRoute params;

  TemplateStoriesViewModel({
    required this.params,
  });

  late SearchFilterObject filter = SearchFilterObject(
    years: {},
    types: {PathType.docs},
    tagId: null,
    assetId: null,
    templateId: params.template?.id,
    galleryTemplateId: params.galleryTemplate?.id,
  );
}
