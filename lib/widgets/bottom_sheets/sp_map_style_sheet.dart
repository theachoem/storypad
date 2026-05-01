import 'package:flutter/material.dart';
import 'package:storypad/views/map/local_widgets/maps/map_types.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';

class SpMapStyleSheet extends BaseBottomSheet {
  const SpMapStyleSheet({
    required this.mapStyle,
    required this.onChanged,
  });

  final SpMapStyle mapStyle;
  final void Function(SpMapStyle mapStyle) onChanged;

  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return SpSingleStateWidget.listen(
      initialValue: mapStyle,
      builder: (context, selectedMapStyle, notifier) {
        return SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...SpMapStyle.values.map((style) {
                return ListTile(
                  title: Text(style.label),
                  trailing: Visibility(
                    visible: style == selectedMapStyle,
                    child: SpFadeIn.fromBottom(
                      child: Icon(
                        SpIcons.checkCircle,
                        color: ColorScheme.of(context).primary,
                      ),
                    ),
                  ),
                  onTap: () {
                    notifier.value = style;
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
