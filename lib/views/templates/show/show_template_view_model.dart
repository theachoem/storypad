import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/types/path_type.dart';
import 'show_template_view.dart';

class ShowTemplateViewModel extends ChangeNotifier with DisposeAwareMixin {
  final ShowTemplateRoute params;

  ShowTemplateViewModel({
    required this.params,
  });

  late SearchFilterObject filter = SearchFilterObject(
    years: {},
    types: {PathType.docs},
    tagId: null,
    assetId: null,
    templateId: params.template.id,
  );
}
