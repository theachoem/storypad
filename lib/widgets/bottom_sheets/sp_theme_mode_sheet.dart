import 'package:flutter/material.dart';
import 'package:storypad/views/settings/local_widgets/theme_mode_tile.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';

class SpThemeModeSheet extends BaseBottomSheet {
  const SpThemeModeSheet({
    required this.themeMode,
    required this.onChanged,
  });

  final ThemeMode themeMode;
  final void Function(ThemeMode themeMode) onChanged;

  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return SpSingleStateWidget.listen(
      initialValue: themeMode,
      builder: (context, selectedThemeMode, notifier) {
        return SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...ThemeMode.values.map((themeMode) {
                return ListTile(
                  title: Text(ThemeModeTile.getLocalizedThemeMode(themeMode)),
                  trailing: Visibility(
                    visible: themeMode == selectedThemeMode,
                    child: SpFadeIn.fromBottom(
                      child: Icon(
                        SpIcons.checkCircle,
                        color: ColorScheme.of(context).primary,
                      ),
                    ),
                  ),
                  onTap: () {
                    notifier.value = themeMode;
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
