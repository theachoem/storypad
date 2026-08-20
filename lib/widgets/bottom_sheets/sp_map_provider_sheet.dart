import 'package:flutter/material.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/maps/map_types.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';

class SpMapProviderSheet extends BaseBottomSheet {
  const SpMapProviderSheet({
    required this.mapRenderer,
    required this.onChanged,
  });

  final SpMapRenderer mapRenderer;
  final void Function(SpMapRenderer mapRenderer) onChanged;

  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return SpSingleStateWidget.listen(
      initialValue: mapRenderer,
      builder: (context, selectedMapRenderer, notifier) {
        return SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...SpMapRenderer.values.map((mapRenderer) {
                return ListTile(
                  title: Text(mapRenderer.label),
                  subtitle: Text(mapRenderer.description),
                  trailing: Visibility(
                    visible: mapRenderer == selectedMapRenderer,
                    child: SpFadeIn.fromBottom(
                      child: Icon(
                        SpIcons.checkCircle,
                        color: ColorScheme.of(context).primary,
                      ),
                    ),
                  ),
                  onTap: () {
                    notifier.value = mapRenderer;
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
