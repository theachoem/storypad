import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:storypad/core/constants/app_constants.dart';
import 'package:storypad/views/paywall/paywall_view.dart';
import 'package:storypad/views/settings/local_widgets/font_weight_tile.dart';
import 'package:storypad/widgets/bottom_sheets/base_bottom_sheet.dart';
import 'package:storypad/widgets/sp_fade_in.dart';
import 'package:storypad/widgets/sp_icons.dart';
import 'package:storypad/widgets/sp_single_state_widget.dart';

class SpFontWeightSheet extends BaseBottomSheet {
  const SpFontWeightSheet({
    required this.fontWeight,
    required this.onChanged,
    this.showDefaultLabel = true,
    this.locked = false,
    this.defaultFontWeight = kDefaultFontWeight,
  });

  final FontWeight defaultFontWeight;
  final FontWeight fontWeight;
  final bool showDefaultLabel;
  final bool locked;
  final void Function(FontWeight fontWeight) onChanged;

  @override
  bool get fullScreen => false;

  @override
  Widget build(BuildContext context, double bottomPadding) {
    return SpSingleStateWidget.listen(
      initialValue: fontWeight,
      builder: (context, selectedFontWeight, notifier) {
        return SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...FontWeight.values.map((fontWeight) {
                String title = FontWeightTile.getFontWeightTitle(fontWeight);
                bool isDefault = defaultFontWeight == fontWeight;

                if (isDefault && showDefaultLabel) {
                  title += ' (${tr('general.default')})';
                }

                return ListTile(
                  title: Text(title),
                  trailing: !isDefault && locked
                      ? const Icon(SpIcons.lock)
                      : Visibility(
                          visible: fontWeight == selectedFontWeight,
                          child: SpFadeIn.fromBottom(
                            child: Icon(
                              SpIcons.checkCircle,
                              color: ColorScheme.of(context).primary,
                            ),
                          ),
                        ),
                  onTap: () {
                    if (!isDefault && locked) {
                      const PaywallRoute(initialFocus: .customizations).push(context);
                      return;
                    }

                    notifier.value = fontWeight;
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
