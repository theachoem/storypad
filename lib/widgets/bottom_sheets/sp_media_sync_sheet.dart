import 'package:flutter/material.dart';
import 'package:storypad/core/types/media_sync_option.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';

class SpMediaSyncSheet extends BaseBottomSheet {
  const SpMediaSyncSheet({
    required this.mediaSync,
    required this.onChanged,
  });

  final MediaSyncOption mediaSync;
  final void Function(MediaSyncOption mediaSync) onChanged;

  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return SpSingleStateWidget.listen(
      initialValue: mediaSync,
      builder: (context, selectedMediaSync, notifier) {
        return SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...MediaSyncOption.values.map((mediaSync) {
                return ListTile(
                  title: Text(mediaSync.labelWithDefault),
                  trailing: Visibility(
                    visible: mediaSync == selectedMediaSync,
                    child: SpFadeIn.fromBottom(
                      child: Icon(
                        SpIcons.checkCircle,
                        color: ColorScheme.of(context).primary,
                      ),
                    ),
                  ),
                  onTap: () {
                    notifier.value = mediaSync;
                    onChanged(notifier.value);
                  },
                );
              }),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }
}
