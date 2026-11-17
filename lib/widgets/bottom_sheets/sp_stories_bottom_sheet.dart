import 'package:flutter/material.dart';
import 'package:storypad/core/objects/search_filter_object.dart';
import 'package:storypad/core/objects/sp_latlng.dart';
import 'package:storypad/core/services/map/map_app_opener_service.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/story_list/sp_story_list.dart';

class SpStoriesBottomSheet extends BaseBottomSheet {
  const SpStoriesBottomSheet({
    required this.filter,
    required this.storyLocation,
  });

  final SearchFilterObject filter;
  final SpLatLng? storyLocation;

  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.5,
      child: Scaffold(
        floatingActionButton: storyLocation != null ? _MapAppOpenerButton(storyLocation: storyLocation!) : null,
        body: SpStoryList.withQuery(
          filter: filter,
          disableMultiEdit: true,
        ),
      ),
    );
  }
}

class _MapAppOpenerButton extends StatelessWidget {
  const _MapAppOpenerButton({
    required this.storyLocation,
  });

  final SpLatLng storyLocation;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(SpIcons.openInNew),
      onPressed: () => MapAppOpenerService.open(context, storyLocation),
    );
  }
}
