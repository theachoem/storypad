import 'package:flutter/material.dart';
import 'package:storypad/core/mixins/dispose_aware_mixin.dart';
import 'community_view.dart';

class CommunityViewModel extends ChangeNotifier with DisposeAwareMixin {
  final CommunityRoute params;

  CommunityViewModel({
    required this.params,
  });
}
